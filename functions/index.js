/**
 * DCN Admin — signup application + approval Cloud Functions.
 *
 * The password an applicant chooses at signup goes STRAIGHT into Firebase Auth
 * (via these functions over HTTPS) and is never stored in Firestore. The auth
 * account is created disabled and only enabled on approval, when the member ID
 * is minted and the login projection is written.
 *
 * All privileged writes happen here with the Admin SDK (bypassing security
 * rules), so the client-facing rules can stay locked down.
 */
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { defineSecret } = require("firebase-functions/params");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();
const auth = admin.auth();
const FieldValue = admin.firestore.FieldValue;

const TERMII_API_KEY = defineSecret("TERMII_API_KEY");
// Termii sender ID — must be registered/approved on your Termii account.
const SENDER_ID = "DCN";

setGlobalOptions({ region: "europe-west1" });

// ── Helpers ───────────────────────────────────────────────────
function normalizePhone(raw) {
  let p = (raw || "").replace(/[^0-9]/g, "");
  if (p.startsWith("0")) p = "234" + p.slice(1);
  return p;
}

async function sendSms(to, message, apiKey) {
  const phone = normalizePhone(to);
  if (!phone || !apiKey) {
    console.warn("Termii SMS skipped:", { hasPhone: !!phone, hasKey: !!apiKey });
    return { ok: false, skipped: true };
  }
  try {
    // Channel: `generic` is the only route configured on this Termii
    // workspace. To reliably reach Nigerian numbers with Do-Not-Disturb on
    // (the default), the `dnd` route must be enabled by Termii support — then
    // switch this to "dnd".
    const res = await fetch("https://api.ng.termii.com/api/sms/send", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        to: phone,
        from: SENDER_ID,
        sms: message,
        type: "plain",
        channel: "generic",
        api_key: apiKey,
      }),
    });
    const body = await res.json().catch(() => ({}));
    // Log the outcome (never the key) so delivery is debuggable in Cloud Logging.
    console.log("Termii SMS response", {
      to: phone,
      http: res.status,
      message_id: body.message_id,
      balance: body.balance,
      message: body.message || body.msg || body.error,
    });
    return { ok: res.ok, body };
  } catch (e) {
    console.error("Termii SMS failed:", e && e.message);
    return { ok: false, error: e && e.message };
  }
}

function fullName(app) {
  return `${app.first_name || ""} ${app.last_name || ""}`.trim();
}

// ── submitApplication (public) ────────────────────────────────
// Called by the (unauthenticated) applicant. Validates the invite code,
// creates a disabled auth account with their password, and files the
// application. The role comes from the invite code, not the applicant.
exports.submitApplication = onCall(async (req) => {
  const d = req.data || {};
  const email = String(d.email || "").trim().toLowerCase();
  const password = String(d.password || "");
  const inviteCode = String(d.invite_code || "").trim();
  const deptCode = String(d.department || "").toUpperCase();

  if (!email || !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) {
    throw new HttpsError("invalid-argument", "A valid email is required.");
  }
  if (password.length < 8) {
    throw new HttpsError("invalid-argument", "Password must be at least 8 characters.");
  }
  if (!inviteCode) {
    throw new HttpsError("failed-precondition", "An invite code is required.");
  }

  // Look up the invite code (by doc id, else by `code` field).
  let codeData = null;
  const byId = await db.collection("invite_codes").doc(inviteCode).get();
  if (byId.exists) {
    codeData = byId.data();
  } else {
    const q = await db.collection("invite_codes").where("code", "==", inviteCode).limit(1).get();
    if (!q.empty) codeData = q.docs[0].data();
  }
  if (!codeData) throw new HttpsError("failed-precondition", "Invalid invite code.");
  if (codeData.active === false) throw new HttpsError("failed-precondition", "This invite code has been revoked.");
  if (typeof codeData.max_uses === "number" && (codeData.uses || 0) >= codeData.max_uses) {
    throw new HttpsError("failed-precondition", "This invite code has reached its usage limit.");
  }
  const codeDept = String(codeData.department_code || "").toUpperCase();
  if (codeDept && deptCode && codeDept !== deptCode) {
    throw new HttpsError("failed-precondition", "This invite code is for a different department.");
  }
  const role = String(codeData.role || "WORKER").toUpperCase();

  // Create the disabled auth account holding their chosen password.
  let uid;
  try {
    const user = await auth.createUser({
      email,
      password,
      displayName: `${d.first_name || ""} ${d.last_name || ""}`.trim() || undefined,
      disabled: true,
    });
    uid = user.uid;
  } catch (e) {
    if (e.code === "auth/email-already-exists") {
      throw new HttpsError("already-exists", "An account with this email already exists.");
    }
    console.error("createUser failed:", e && e.message);
    throw new HttpsError("internal", "Could not create the account. Try again.");
  }

  // Store the application (everything except the password).
  const { password: _pw, confirm_password: _cp, ...rest } = d;
  const appRef = db.collection("applications").doc();
  await appRef.set({
    ...rest,
    uid,
    email,
    role,
    department: deptCode,
    status: "PENDING",
    applied_label: "Just now",
    created_at: FieldValue.serverTimestamp(),
  });

  return { ok: true, application_id: appRef.id };
});

// ── checkApplicationStatus (public) ───────────────────────────
// Lets the pending screen reveal the minted member ID once approved.
exports.checkApplicationStatus = onCall(async (req) => {
  const appId = String((req.data || {}).application_id || "");
  if (!appId) throw new HttpsError("invalid-argument", "Missing application id.");
  const snap = await db.collection("applications").doc(appId).get();
  if (!snap.exists) throw new HttpsError("not-found", "Application not found.");
  const a = snap.data();
  return {
    status: a.status || "PENDING",
    member_id: a.member_id || null,
    reason: a.reject_reason || null,
    department_name: a.department_name || null,
  };
});

// ── decideApplication (HOD / Pastor) ──────────────────────────
exports.decideApplication = onCall({ secrets: [TERMII_API_KEY] }, async (req) => {
  if (!req.auth) throw new HttpsError("unauthenticated", "Sign in required.");
  const token = req.auth.token || {};
  const callerRole = String(token.role || "").toUpperCase();
  const callerDept = String(token.dept || "").toUpperCase();
  const isPastor = callerRole === "PASTOR" || callerRole === "SUPER_ADMIN";

  const data = req.data || {};
  const appId = String(data.application_id || "");
  const approve = data.approve === true;
  const reason = String(data.reason || "").trim();
  if (!appId) throw new HttpsError("invalid-argument", "Missing application id.");

  const appRef = db.collection("applications").doc(appId);
  const appSnap = await appRef.get();
  if (!appSnap.exists) throw new HttpsError("not-found", "Application not found.");
  const app = appSnap.data();
  if (app.status !== "PENDING") throw new HttpsError("failed-precondition", "This application has already been decided.");

  const appDept = String(app.department || "").toUpperCase();
  const isDeptLead = (callerRole === "HOD" || callerRole === "SUBHOD") && callerDept === appDept;
  if (!isPastor && !isDeptLead) {
    throw new HttpsError("permission-denied", "You are not authorized to decide this application.");
  }

  // ── Reject ──
  if (!approve) {
    await appRef.update({ status: "REJECTED", reject_reason: reason || null, decided_at: FieldValue.serverTimestamp() });
    try { await auth.deleteUser(app.uid); } catch (e) { /* account may already be gone */ }
    await sendSms(
      app.phone_number,
      `Hi ${app.first_name || "there"}, your DCN application was not approved${reason ? `: ${reason}` : "."} Please contact your HOD.`,
      TERMII_API_KEY.value(),
    );
    return { ok: true, status: "REJECTED" };
  }

  // ── Approve: mint member ID atomically ──
  const memberId = await db.runTransaction(async (tx) => {
    const counterRef = db.collection("counters").doc("member_id");
    const cs = await tx.get(counterRef);
    const cur = (cs.exists && typeof cs.data().next === "number") ? cs.data().next : 6;
    const next = cur + 1;
    tx.set(counterRef, { next }, { merge: true });
    return `DCN-${String(next).padStart(5, "0")}`;
  });

  // Consume one invite-code use.
  if (app.invite_code) {
    const byId = db.collection("invite_codes").doc(app.invite_code);
    const exists = (await byId.get()).exists;
    if (exists) {
      await byId.set({ uses: FieldValue.increment(1) }, { merge: true });
    } else {
      const q = await db.collection("invite_codes").where("code", "==", app.invite_code).limit(1).get();
      if (!q.empty) await q.docs[0].ref.set({ uses: FieldValue.increment(1) }, { merge: true });
    }
  }

  // Enable the account + set department-scoped claims.
  await auth.updateUser(app.uid, { disabled: false });
  await auth.setCustomUserClaims(app.uid, { role: app.role, dept: appDept || null });

  const name = fullName(app);
  // Full private user record.
  await db.collection("users").doc(app.uid).set({
    uid: app.uid,
    member_id: memberId,
    email: app.email,
    role: app.role,
    status: "APPROVED",
    department_id: appDept ? appDept.toLowerCase() : null,
    department_code: appDept || null,
    department_name: app.department_name || null,
    sub_unit_name: app.sub_unit_name || app.sub_unit || null,
    person: { first_name: app.first_name || "", last_name: app.last_name || "", photo_url: null },
    phone: app.phone_number || null,
    search_name: name.toLowerCase(),
    week_reports: { bible: false, prayer: false },
    created_at: FieldValue.serverTimestamp(),
  }, { merge: true });

  // Public login projection (member ID -> email).
  await db.collection("member_login").doc(memberId).set({ email: app.email, uid: app.uid });

  // Public approved-worker projection.
  await db.collection("worker_directory").doc(app.uid).set({
    name,
    search_name: name.toLowerCase(),
    department_name: app.department_name || null,
    sub_unit_name: app.sub_unit_name || app.sub_unit || null,
    role: app.role,
    photo_url: null,
    status: "APPROVED",
  });

  await appRef.update({ status: "APPROVED", member_id: memberId, decided_at: FieldValue.serverTimestamp() });

  await sendSms(
    app.phone_number,
    `Welcome to DCN, ${app.first_name || "there"}! Approved. Member ID: ${memberId}. Sign in on the DCN Admin app with this ID and your password.`,
    TERMII_API_KEY.value(),
  );

  return { ok: true, status: "APPROVED", member_id: memberId };
});

// ── onMessageCreated → push notification ──────────────────────
// When a chat message lands, push it to every other participant's devices.
exports.onMessageCreated = onDocumentCreated(
  "conversations/{convId}/messages/{msgId}",
  async (event) => {
    const msg = event.data && event.data.data();
    if (!msg) return;
    const convId = event.params.convId;

    const convSnap = await db.collection("conversations").doc(convId).get();
    if (!convSnap.exists) return;
    const conv = convSnap.data();

    const participants = conv.participant_uids || [];
    const recipients = participants.filter((uid) => uid !== msg.sender_uid);
    if (recipients.length === 0) return;

    // Title: group name, else the sender's name. Body: text or a photo marker.
    const isGroup = conv.type === "group";
    const title = isGroup
      ? (conv.title || "New message")
      : (msg.sender_name || "New message");
    const body = msg.text && msg.text.length > 0
      ? (isGroup ? `${msg.sender_name}: ${msg.text}` : msg.text)
      : "📷 Photo";

    // Gather every recipient's FCM tokens.
    const tokenDocs = [];
    for (const uid of recipients) {
      const toks = await db.collection("users").doc(uid).collection("fcm_tokens").get();
      toks.forEach((t) => tokenDocs.push({ uid, token: t.id }));
    }
    if (tokenDocs.length === 0) return;

    const message = {
      notification: { title, body },
      data: {
        type: "chat",
        conversation_id: convId,
        title: isGroup ? (conv.title || "") : (msg.sender_name || ""),
      },
      android: { priority: "high" },
      apns: { payload: { aps: { sound: "default" } } },
    };

    const resp = await admin.messaging().sendEachForMulticast({
      tokens: tokenDocs.map((t) => t.token),
      ...message,
    });

    // Prune tokens the FCM service reports as invalid.
    const deletions = [];
    resp.responses.forEach((r, i) => {
      if (!r.success) {
        const code = r.error && r.error.code;
        if (
          code === "messaging/registration-token-not-registered" ||
          code === "messaging/invalid-registration-token"
        ) {
          const { uid, token } = tokenDocs[i];
          deletions.push(
            db.collection("users").doc(uid).collection("fcm_tokens").doc(token).delete().catch(() => {}),
          );
        }
      }
    });
    await Promise.all(deletions);
    console.log("chat push", { convId, recipients: recipients.length, sent: resp.successCount, failed: resp.failureCount });
  },
);
