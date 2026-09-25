/**
 * DCN Admin — Firestore + Auth seeder.
 *
 * Populates the real backend with the reference data the app needs to work
 * end-to-end during development:
 *   - departments (+ sub-units)      — Ministry step
 *   - invite_codes                   — Security step validation
 *   - test users (Auth + users doc)  — login + persona routing
 *   - member_login / worker_directory — public projections for pre-auth reads
 *
 * Auth is via Application Default Credentials (the gcloud/Firebase CLI login),
 * so no service-account key file is required. Idempotent: re-running updates
 * in place using deterministic ids.
 *
 * Usage:  PROJECT_ID=dcnchurchadmin npm run seed
 */
const admin = require("firebase-admin");

const PROJECT_ID = process.env.PROJECT_ID || "dcnchurchadmin";
// Shared password for all seeded test accounts (meets the app's policy).
const TEST_PASSWORD = process.env.SEED_PASSWORD || "Test123!";

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  projectId: PROJECT_ID,
});

const db = admin.firestore();
const auth = admin.auth();

// ── Reference data ────────────────────────────────────────────
const DEPARTMENTS = [
  {
    code: "WORSHIP",
    name: "Worship",
    requires_sub_unit: false,
    sub_units: ["Choir", "Instrumentalists", "Sound"],
  },
  {
    code: "MEDIA",
    name: "Media",
    requires_sub_unit: false,
    sub_units: ["Photography and Videography", "Graphics", "Livestream"],
  },
  {
    code: "USHERING",
    name: "Ushering",
    requires_sub_unit: false,
    sub_units: ["Protocol", "Sanitation"],
  },
  {
    code: "DRAMA",
    name: "Drama",
    requires_sub_unit: false,
    sub_units: ["Actors", "Script", "Stage"],
  },
  {
    code: "TECHNICAL",
    name: "Technical",
    requires_sub_unit: false,
    sub_units: ["Lighting", "Power", "Setup"],
  },
  {
    code: "FOLLOWUP",
    name: "Follow-Up",
    requires_sub_unit: false,
    sub_units: ["Calls", "Visitation"],
  },
];

// department_code -> [invite codes]
const INVITE_CODES = [
  { code: "DRAMA-9F2K-44XQ", department_code: "DRAMA", max_uses: 50 },
  { code: "WORSHIP-7A1B-22MN", department_code: "WORSHIP", max_uses: 50 },
  { code: "MEDIA-3C5D-88PL", department_code: "MEDIA", max_uses: 50 },
  { code: "USHERING-6E4F-19KJ", department_code: "USHERING", max_uses: 50 },
  { code: "TECHNICAL-8G2H-77RT", department_code: "TECHNICAL", max_uses: 50 },
  { code: "FOLLOWUP-1J9K-05ZP", department_code: "FOLLOWUP", max_uses: 50 },
];

// Test accounts spanning every persona + a suspended case.
const USERS = [
  {
    member_id: "DCN-00001",
    email: "worker.drama@dcn.test",
    first_name: "Tobi",
    last_name: "Adeyemi",
    role: "WORKER",
    status: "APPROVED",
    department_code: "DRAMA",
    department_name: "Drama",
    sub_unit_name: "Actors",
    // Profile extras surfaced on the Worker profile screen.
    phone: "+2348100000421",
    access_key: "DRAMA-9F2K-44XQ",
    school: "University of Ibadan",
    level: "300",
    dob: "14 August",
    joined_label: "14 Aug 2024",
  },
  {
    member_id: "DCN-00002",
    email: "hod.drama@dcn.test",
    first_name: "Grace",
    last_name: "Williams",
    role: "HOD",
    status: "APPROVED",
    department_code: "DRAMA",
    department_name: "Drama",
  },
  {
    member_id: "DCN-00003",
    email: "worker.followup@dcn.test",
    first_name: "Emeka",
    last_name: "Okoro",
    role: "WORKER",
    status: "APPROVED",
    department_code: "FOLLOWUP",
    department_name: "Follow-Up",
    sub_unit_name: "Calls",
  },
  {
    member_id: "DCN-00004",
    email: "hod.followup@dcn.test",
    first_name: "Ada",
    last_name: "Nwosu",
    role: "HOD",
    status: "APPROVED",
    department_code: "FOLLOWUP",
    department_name: "Follow-Up",
  },
  {
    member_id: "DCN-00005",
    email: "pastor@dcn.test",
    first_name: "David",
    last_name: "Okafor",
    role: "PASTOR",
    status: "APPROVED",
    department_code: null,
    department_name: null,
  },
  {
    member_id: "DCN-00006",
    email: "suspended@dcn.test",
    first_name: "Ade",
    last_name: "Akin",
    role: "WORKER",
    status: "SUSPENDED",
    department_code: "MEDIA",
    department_name: "Media",
  },
];

// ── Helpers ───────────────────────────────────────────────────
async function ensureAuthUser(email, password, displayName) {
  try {
    const existing = await auth.getUserByEmail(email);
    await auth.updateUser(existing.uid, { password, displayName });
    return existing.uid;
  } catch (e) {
    if (e.code === "auth/user-not-found") {
      const created = await auth.createUser({ email, password, displayName });
      return created.uid;
    }
    throw e;
  }
}

async function seedDepartments() {
  const batch = db.batch();
  for (const d of DEPARTMENTS) {
    const ref = db.collection("departments").doc(d.code.toLowerCase());
    batch.set(ref, {
      name: d.name,
      code: d.code,
      requires_sub_unit: d.requires_sub_unit,
      sub_units: d.sub_units.map((name, i) => ({
        id: `${d.code.toLowerCase()}-${i + 1}`,
        name,
      })),
    });
  }
  await batch.commit();
  console.log(`✓ Seeded ${DEPARTMENTS.length} departments`);
}

async function seedInviteCodes() {
  const batch = db.batch();
  for (const c of INVITE_CODES) {
    const ref = db.collection("invite_codes").doc(c.code);
    batch.set(ref, {
      code: c.code,
      department_code: c.department_code,
      active: true,
      max_uses: c.max_uses,
      uses: 0,
    });
  }
  await batch.commit();
  console.log(`✓ Seeded ${INVITE_CODES.length} invite codes`);
}

async function seedUsers() {
  const uidByMemberId = {};
  for (const u of USERS) {
    const fullName = `${u.first_name} ${u.last_name}`.trim();
    const uid = await ensureAuthUser(u.email, TEST_PASSWORD, fullName);
    uidByMemberId[u.member_id] = uid;

    // Custom claims drive department-scoped security rules (HOD/Pastor access).
    await auth.setCustomUserClaims(uid, {
      role: u.role,
      dept: u.department_code || null,
    });

    // Full private user record (owner-readable only).
    await db.collection("users").doc(uid).set({
      uid,
      member_id: u.member_id,
      email: u.email,
      role: u.role,
      status: u.status,
      department_id: u.department_code ? u.department_code.toLowerCase() : null,
      department_code: u.department_code,
      department_name: u.department_name,
      sub_unit_name: u.sub_unit_name || null,
      person: {
        first_name: u.first_name,
        last_name: u.last_name,
        photo_url: null,
      },
      phone: u.phone || null,
      access_key: u.access_key || null,
      school: u.school || null,
      level: u.level || null,
      dob: u.dob || null,
      joined_label: u.joined_label || null,
      search_name: fullName.toLowerCase(),
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Public login projection: member ID -> email.
    await db.collection("member_login").doc(u.member_id).set({
      email: u.email,
      uid,
    });

    // Public approved-worker projection for inviter search.
    if (u.status === "APPROVED" && u.role !== "PASTOR") {
      await db.collection("worker_directory").doc(uid).set({
        name: fullName,
        search_name: fullName.toLowerCase(),
        department_name: u.department_name,
        sub_unit_name: u.sub_unit_name || null,
        role: u.role,
        photo_url: null,
        status: u.status,
      });
    } else {
      // Keep the projection clean if a user is no longer eligible.
      await db.collection("worker_directory").doc(uid).delete().catch(() => {});
    }

    console.log(`✓ User ${u.member_id} (${u.role}/${u.status}) <${u.email}>`);
  }
  return uidByMemberId;
}

// ── Member-ID counter ─────────────────────────────────────────
// The decideApplication Cloud Function mints IDs by incrementing this counter:
// the next approval becomes DCN-0000{next+1}. Seeded users occupy DCN-00001..
// DCN-00006, so start `next` at 6 (first minted ID = DCN-00007).
async function seedCounters() {
  // Never lower an already-advanced counter (re-seeding must not cause ID
  // collisions), so only initialize it when it's missing.
  const ref = db.collection("counters").doc("member_id");
  const snap = await ref.get();
  if (snap.exists && typeof snap.data().next === "number") {
    console.log(`• counters/member_id already at next: ${snap.data().next} — left unchanged`);
    return;
  }
  await ref.set({ next: 6 });
  console.log("✓ Seeded counters/member_id (next: 6 → first approval mints DCN-00007)");
}

// ── Worker dashboard data (scoped to DCN-00001) ───────────────
// Dates are generated relative to "now" so the schedule always looks live.
function dayAt(offsetDays, hour, minute = 0) {
  const d = new Date();
  d.setDate(d.getDate() + offsetDays);
  d.setHours(hour, minute, 0, 0);
  return d;
}
const WD = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
const MON = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
function fmtDay(d) {
  return `${WD[d.getDay()]}, ${d.getDate()} ${MON[d.getMonth()]}`;
}
function fmtTime(d) {
  let h = d.getHours();
  const m = d.getMinutes().toString().padStart(2, "0");
  const ap = h >= 12 ? "PM" : "AM";
  h = h % 12 || 12;
  return `${h}:${m} ${ap}`;
}
const ts = (d) => admin.firestore.Timestamp.fromDate(d);

async function seedWorkerData(uid) {
  if (!uid) return;

  // Tasks
  const tasks = [
    { id: "t01", title: "Review Sunday script (Act II)", status: "ASSIGNED", priority: "HIGH", due: dayAt(1, 17), assigned_by: "Grace Williams (HOD)", description: "Read through Act II before Thursday rehearsal. Mark any unclear lines." },
    { id: "t02", title: "Memorise opening monologue", status: "IN_PROGRESS", priority: "HIGH", due: dayAt(3, 9), assigned_by: "Grace Williams (HOD)", description: "Full memorisation of the opening monologue (pp. 1–3)." },
    { id: "t03", title: "Submit costume measurements", status: "SUBMITTED", priority: "MEDIUM", due: dayAt(0, 18), assigned_by: "Sub-HOD — Costume", description: "Send all measurements via the form." },
    { id: "t04", title: "Prayer slot — Friday 6–7am", status: "ASSIGNED", priority: "MEDIUM", due: dayAt(2, 6), assigned_by: "Prayer Coordinator", description: "1-hour prayer slot. Log a brief note after." },
    { id: "t05", title: "Help with stage build on Saturday", status: "ASSIGNED", priority: "LOW", due: dayAt(3, 10), assigned_by: "Stage Manager", description: "Arrive by 10am to help with stage construction." },
    { id: "t06", title: "Bring props from store", status: "OVERDUE", priority: "HIGH", due: dayAt(-2, 12), assigned_by: "Stage Manager", description: "Pick up the wooden chairs and lamp. Overdue." },
    { id: "t07", title: "Last week's rehearsal write-up", status: "APPROVED", priority: "LOW", due: dayAt(-6, 12), assigned_by: "Grace Williams (HOD)", description: "Approved by HOD." },
  ];
  let batch = db.batch();
  for (const t of tasks) {
    batch.set(db.collection("tasks").doc(`${uid}_${t.id}`), {
      title: t.title, status: t.status, priority: t.priority,
      due_date: fmtDay(t.due), due_at: ts(t.due),
      assigned_by: t.assigned_by, description: t.description,
      assignee_uid: uid, department_code: "DRAMA",
    });
  }
  await batch.commit();

  // Meetings (audience includes this worker)
  const meetings = [
    { id: "m01", title: "Drama Department Town Hall", type: "EMERGENCY", status: "SCHEDULED", start: dayAt(0, 19), end: dayAt(0, 20), location: "Main Hall", agenda: "Urgent alignment ahead of Sunday performance" },
    { id: "m02", title: "Drama Rehearsal — Script Reading", type: "REGULAR", status: "SCHEDULED", start: dayAt(1, 17), end: dayAt(1, 20), location: "Hall B", agenda: "Week 4 — Script discussion + role delegation" },
    { id: "m03", title: "Drama Prayer Meeting", type: "REGULAR", status: "SCHEDULED", start: dayAt(2, 6), end: dayAt(2, 7), location: "Prayer Room" },
    { id: "m04", title: "Sub-unit Debrief — Actors", type: "AD_HOC", status: "RESCHEDULED", start: dayAt(3, 9), end: dayAt(3, 10), location: "Hall B (back room)", reason: "Hall B booked by Worship rehearsal." },
    { id: "m05", title: "The Experience", type: "SERVICE", status: "SCHEDULED", start: dayAt(4, 10), end: dayAt(4, 12, 30), location: "Main Auditorium" },
  ];
  batch = db.batch();
  for (const m of meetings) {
    batch.set(db.collection("meetings").doc(`drama_${m.id}`), {
      title: m.title, type: m.type, status: m.status,
      date: fmtDay(m.start), start: fmtTime(m.start), end: fmtTime(m.end),
      start_at: ts(m.start), location: m.location,
      agenda: m.agenda || null, reason: m.reason || null,
      department_code: "DRAMA", audience_uids: [uid],
    });
  }
  await batch.commit();

  // Weekly Bible/prayer reports — current week open, 6-week submitted streak.
  const reports = [
    { wk: 33, label: "W33 · This week", submitted: false, bible: "", prayer: "" },
    { wk: 32, label: "W32 · last week", submitted: true, bible: "John 14 – 16 (Jesus' farewell discourse).", prayer: "Prayed for my course mates and clarity on plans." },
    { wk: 31, label: "W31", submitted: true, bible: "Acts 1 – 4 — the early church.", prayer: "Prayed daily for the Drama team." },
    { wk: 30, label: "W30", submitted: true, bible: "Romans 8 (Spirit-led life).", prayer: "Prayer slot Friday 6–7am." },
    { wk: 29, label: "W29", submitted: true, bible: "Psalms 22 – 24.", prayer: "Personal — gratitude and surrender." },
    { wk: 28, label: "W28", submitted: true, bible: "1 Peter — all 5 chapters.", prayer: "Prayed for my parents." },
    { wk: 27, label: "W27", submitted: true, bible: "John 1 – 3.", prayer: "Prayer walk after rehearsal." },
    { wk: 26, label: "W26", submitted: false, bible: "—", prayer: "—" },
  ];
  batch = db.batch();
  for (const r of reports) {
    batch.set(db.collection("reports").doc(`${uid}_w${r.wk}`), {
      uid, week_number: r.wk, week_label: r.label,
      submitted: r.submitted, bible: r.bible, prayer: r.prayer,
      created_at: ts(dayAt(-(33 - r.wk) * 7, 8)),
    });
  }
  await batch.commit();

  // Members referenced by the follow-up assignments.
  const members = [
    { id: "m_chinwe", name: "Chinwe Okeke", phone: "+2348051234003", dob: "May 21", status: "Active", weeks_absent: 0, school: "University of Ibadan", level: "100" },
    { id: "m_samuel", name: "Samuel Adesina", phone: "+2348051234004", dob: "Aug 11", status: "At Risk", weeks_absent: 3, school: "University of Ibadan", level: "400" },
  ];
  batch = db.batch();
  for (const m of members) {
    batch.set(db.collection("members").doc(m.id), {
      name: m.name, phone: m.phone, dob: m.dob, status: m.status,
      weeks_absent: m.weeks_absent, school: m.school, level: m.level,
    });
  }
  await batch.commit();

  // Cross-dept follow-up assignments given to this worker.
  const followups = [
    { id: "f01", member_id: "m_chinwe", member_name: "Chinwe Okeke", priority: "med", status: "PENDING", reason: "Shared course — friendly check-in", assigned_by: "Ada Nwosu (FU HOD)" },
    { id: "f02", member_id: "m_samuel", member_name: "Samuel Adesina", priority: "high", status: "PENDING", reason: "Missed 3 weeks — same hostel as you", assigned_by: "Ada Nwosu (FU HOD)" },
  ];
  batch = db.batch();
  for (const f of followups) {
    batch.set(db.collection("followup_assignments").doc(`${uid}_${f.id}`), {
      worker_uid: uid, member_id: f.member_id, member_name: f.member_name,
      priority: f.priority, status: f.status, reason: f.reason,
      assigned_by: f.assigned_by, assigned_at_label: "Yesterday",
      created_at: ts(dayAt(-1, 9)),
    });
  }
  await batch.commit();

  // Quarterly scorecards (current with detail + history).
  const cats = (t, e, i, x, a) => [
    { label: "Teachability", score: t, max: 40, critical: true },
    { label: "Enthusiasm", score: e, max: 15, critical: true },
    { label: "Interest", score: i, max: 20, critical: false },
    { label: "Exam / Test", score: x, max: 15, critical: false },
    { label: "Attendance", score: a, max: 10, critical: true },
  ];
  const scorecards = [
    { id: "q2_2026", quarter: "Q2", year: 2026, categories: cats(34, 13, 16, 13, 9), total: 85, pass: true, hod_name: "Grace Williams", hod_note: "Strong growth this quarter. Your teachability is consistently top-tier — keep showing up early to rehearsals. Work on memorising lines faster." },
    { id: "q1_2026", quarter: "Q1", year: 2026, categories: cats(32, 12, 17, 11, 8), total: 80, pass: true, hod_name: "Grace Williams", hod_note: "Solid start to the year. Keep it up." },
    { id: "q4_2025", quarter: "Q4", year: 2025, categories: [], total: 72, pass: true, hod_name: "Grace Williams", hod_note: "" },
    { id: "q3_2025", quarter: "Q3", year: 2025, categories: [], total: 58, pass: true, hod_name: "Grace Williams", hod_note: "" },
    { id: "q2_2025", quarter: "Q2", year: 2025, categories: [], total: 44, pass: false, hod_name: "Grace Williams", hod_note: "" },
  ];
  batch = db.batch();
  for (const s of scorecards) {
    batch.set(db.collection("scorecards").doc(`${uid}_${s.id}`), {
      uid, quarter: s.quarter, year: s.year, categories: s.categories,
      total: s.total, pass: s.pass, hod_name: s.hod_name, hod_note: s.hod_note,
      ack_status: null, department_code: "DRAMA", status: "DONE",
      worker_name: "Tobi Adeyemi", assessed_at: ts(dayAt(-30, 10)),
    });
  }
  await batch.commit();

  // Life updates (one responded, one seen).
  const life = [
    { id: "lu01", type: "Testimony", body: "God provided my full tuition through an unexpected bursary this week. Still in awe.", shared_with: "My HOD + Pastor", status: "RESPONDED", response: { by: "Grace Williams", at: "2 days ago", body: "Praise God, Tobi! So happy for you — let's share this at the next dept meeting." }, mins: 4320 },
    { id: "lu02", type: "Prayer need", body: "Please pray for my dad's health — he has a check-up next week.", shared_with: "My HOD", status: "SEEN", response: null, mins: 1440 },
  ];
  batch = db.batch();
  for (const l of life) {
    const d = new Date(); d.setMinutes(d.getMinutes() - l.mins);
    batch.set(db.collection("life_updates").doc(`${uid}_${l.id}`), {
      uid, type: l.type, body: l.body, shared_with: l.shared_with,
      status: l.status, response: l.response, department_code: "DRAMA",
      worker_name: "Tobi Adeyemi",
      at: l.mins >= 1440 ? `${Math.round(l.mins/1440)} days ago` : "today",
      created_at: ts(d),
    });
  }
  await batch.commit();

  // Accountability partner + weekly check-ins.
  await db.collection("accountability").doc(uid).set({
    uid,
    partner_name: "Tunde Bakare",
    partner_dept: "Drama · Stage Crew",
    you_submitted: true,
    you_submitted_label: "Submitted Mon",
    partner_submitted: false,
    partner_submitted_label: "Not yet",
    history: [
      { week: "W32 · last week", both: true },
      { week: "W31", both: true },
      { week: "W30", both: false },
      { week: "W29", both: true },
    ],
  });

  // In-app notifications (some deep-link into detail screens).
  const notifs = [
    { id: "n01", type: "MEETING_RESCHEDULED", title: "Sub-unit Debrief rescheduled", body: "Moved to Saturday 9:00 AM. Reason: Hall B booked.", read: false, urgent: false, at: "5 min ago", mins: 5, route: "/meeting/drama_m04" },
    { id: "n02", type: "TASK_OVERDUE", title: "Task overdue: Bring props from store", body: "Please update the status.", read: false, urgent: true, at: "1 hour ago", mins: 60, route: `/task/${uid}_t06` },
    { id: "n03", type: "MEETING_EMERGENCY", title: "URGENT — Drama Town Hall called", body: "Tonight 7:00 PM, Main Hall.", read: false, urgent: true, at: "3 hours ago", mins: 180, route: "/meeting/drama_m01" },
    { id: "n04", type: "PARTNER_REQUEST", title: "Accountability partner request", body: "Tunde Bakare wants to be your accountability partner.", read: false, urgent: false, at: "6 hours ago", mins: 360, partner_name: "Tunde Bakare", partner_sub: "Drama · Stage Crew", partner_note: "Hey! Let's keep each other consistent on Bible reading and prayer this quarter." },
    { id: "n05", type: "REPORT_REMINDER", title: "Bible/Prayer report due", body: "Submit your report before Thursday.", read: true, urgent: false, at: "Yesterday", mins: 1440 },
    { id: "n06", type: "TASK_ASSIGNED", title: "New task: Memorise opening monologue", body: "Due Saturday — high priority.", read: true, urgent: false, at: "2 days ago", mins: 2880, route: `/task/${uid}_t02` },
  ];
  batch = db.batch();
  for (const n of notifs) {
    const d = new Date();
    d.setMinutes(d.getMinutes() - n.mins);
    batch.set(db.collection("notifications").doc(`${uid}_${n.id}`), {
      uid, type: n.type, title: n.title, body: n.body,
      read: n.read, urgent: n.urgent, at: n.at, created_at: ts(d),
      route: n.route || null,
      partner_name: n.partner_name || null,
      partner_sub: n.partner_sub || null,
      partner_note: n.partner_note || null,
    });
  }
  await batch.commit();

  console.log(`✓ Seeded worker dashboard data for DCN-00001 (${tasks.length} tasks, ${meetings.length} meetings, ${reports.length} reports, ${followups.length} follow-ups, ${notifs.length} notifications)`);
}

// ── HOD department dataset (Drama; HOD = DCN-00002) ───────────
// Team workers are Firestore-only user docs (no auth login needed) so the HOD
// screens have a realistic roster to manage. Summary fields are denormalized
// onto each user doc for the team + accountability views.
async function seedDeptData(uidByMemberId) {
  const workerUid = uidByMemberId["DCN-00001"];
  const hodUid = uidByMemberId["DCN-00002"];
  if (!workerUid || !hodUid) return;

  // Denormalize team-summary fields onto the real worker (DCN-00001).
  await db.collection("users").doc(workerUid).set({
    week_reports: { bible: true, prayer: true },
    tasks_open: 5, tasks_overdue: 1, attendance_rate: 92,
    scorecard_last: 80, weeks_with_us: 84, at_risk: false,
  }, { merge: true });

  // Additional Drama workers (login-less roster).
  const team = [
    { id: "seed_w02", first: "Tunde", last: "Bakare", sub: "Stage Crew", role: "WORKER", phone: "+2348100000422", bible: false, prayer: false, open: 3, overdue: 0, att: 78, last: 62, weeks: 41, at_risk: false },
    { id: "seed_w03", first: "Adaeze", last: "Nwosu", sub: "Actors", role: "WORKER", phone: "+2348100000423", bible: true, prayer: false, open: 2, overdue: 0, att: 96, last: 88, weeks: 110, at_risk: false },
    { id: "seed_w04", first: "Joy", last: "Adebayo", sub: "Prayer Unit", role: "SUBHOD", phone: "+2348100000424", bible: true, prayer: true, open: 4, overdue: 0, att: 98, last: 92, weeks: 156, at_risk: false },
    { id: "seed_w05", first: "Samuel", last: "Eze", sub: "Stage Crew", role: "SUBHOD", phone: "+2348100000425", bible: true, prayer: true, open: 6, overdue: 2, att: 88, last: 76, weeks: 72, at_risk: false },
    { id: "seed_w06", first: "Funke", last: "Adediran", sub: "Costume", role: "WORKER", phone: "+2348100000426", bible: false, prayer: true, open: 2, overdue: 0, att: 84, last: 71, weeks: 28, at_risk: false },
    { id: "seed_w07", first: "Mary", last: "Onyema", sub: "Actors", role: "WORKER", phone: "+2348100000427", bible: true, prayer: true, open: 1, overdue: 0, att: 90, last: 68, weeks: 19, at_risk: false },
    { id: "seed_w08", first: "Daniel", last: "Adekunle", sub: "Stage Crew", role: "WORKER", phone: "+2348100000428", bible: false, prayer: false, open: 3, overdue: 1, att: 64, last: 48, weeks: 14, at_risk: true },
    { id: "seed_w09", first: "Ifeanyi", last: "Madu", sub: "Costume", role: "SUBHOD", phone: "+2348100000430", bible: true, prayer: false, open: 5, overdue: 0, att: 86, last: 79, weeks: 92, at_risk: false },
    { id: "seed_w10", first: "Blessing", last: "Eze", sub: "Prayer Unit", role: "WORKER", phone: "+2348100000431", bible: true, prayer: true, open: 1, overdue: 0, att: 98, last: 87, weeks: 67, at_risk: false },
    { id: "seed_w11", first: "Yemi", last: "Adebowale", sub: "Stage Crew", role: "WORKER", phone: "+2348100000432", bible: false, prayer: false, open: 0, overdue: 0, att: 52, last: 38, weeks: 23, at_risk: true },
  ];
  let batch = db.batch();
  for (const w of team) {
    const name = `${w.first} ${w.last}`;
    batch.set(db.collection("users").doc(w.id), {
      uid: w.id, member_id: null, role: w.role, status: "APPROVED",
      department_id: "drama", department_code: "DRAMA", department_name: "Drama",
      sub_unit_name: w.sub, phone: w.phone,
      person: { first_name: w.first, last_name: w.last, photo_url: null },
      search_name: name.toLowerCase(),
      week_reports: { bible: w.bible, prayer: w.prayer },
      tasks_open: w.open, tasks_overdue: w.overdue, attendance_rate: w.att,
      scorecard_last: w.last, weeks_with_us: w.weeks, at_risk: w.at_risk,
    });
    batch.set(db.collection("worker_directory").doc(w.id), {
      name, search_name: name.toLowerCase(), department_name: "Drama",
      sub_unit_name: w.sub, role: w.role, photo_url: null, status: "APPROVED",
    });
  }
  await batch.commit();

  // Review queue — submitted tasks awaiting HOD review.
  const review = [
    { id: "drama_r01", title: "Submit costume measurements", worker: "seed_w03", worker_name: "Adaeze Nwosu", note: "All measurements taken. Sent the spreadsheet to Costume sub-HOD.", attachments: 1, priority: "MEDIUM", at: "Tue · 2:14 PM", mins: 200 },
    { id: "drama_r02", title: "Stage build — backdrop frame", worker: "seed_w05", worker_name: "Samuel Eze", note: "Frame complete, ready for paint Saturday morning.", attachments: 3, priority: "HIGH", at: "Tue · 11:02 AM", mins: 380 },
    { id: "drama_r03", title: "Script — Act III memorisation", worker: "seed_w07", worker_name: "Mary Onyema", note: "Done. Can recite without script. Practiced with Adaeze yesterday.", attachments: 0, priority: "HIGH", at: "Mon · 5:48 PM", mins: 1200 },
    { id: "drama_r04", title: "Costume — lead actress outfit", worker: "seed_w06", worker_name: "Funke Adediran", note: "Outfit altered, fitting tomorrow.", attachments: 2, priority: "MEDIUM", at: "Mon · 1:22 PM", mins: 1500 },
    { id: "drama_r05", title: "Prayer slot — Friday 6–7am", worker: "seed_w10", worker_name: "Blessing Eze", note: "Completed prayer slot. Interceded for the team and Sunday performance.", attachments: 0, priority: "LOW", at: "Sun · 8:30 AM", mins: 2600 },
  ];
  batch = db.batch();
  for (const r of review) {
    const d = new Date(); d.setMinutes(d.getMinutes() - r.mins);
    batch.set(db.collection("tasks").doc(r.id), {
      title: r.title, status: "SUBMITTED", priority: r.priority,
      department_code: "DRAMA", assignee_uid: r.worker, assignee_name: r.worker_name,
      submission_note: r.note, attachments: r.attachments,
      submitted_at_label: r.at, due_date: r.at, submitted_at: ts(d),
      assigned_by: "Grace Williams (HOD)",
    });
  }
  await batch.commit();

  // Pending sign-up applications under the Drama key.
  const apps = [
    { id: "app_dr01", name: "Chinwe Nwankwo", applied: "Today · 9:14 AM", school: "University of Ibadan", level: "200", sub_unit_pref: "Actors", responsibilities: ["Actor", "Prayer slot"], phone: "+2348071230001", mins: 120 },
    { id: "app_dr02", name: "Olu Owolabi", applied: "Yesterday", school: "University of Ibadan", level: "400", sub_unit_pref: "Stage Crew", responsibilities: ["Stage manager"], phone: "+2348071230002", mins: 1500 },
    { id: "app_dr03", name: "Bisi Adekoya", applied: "Yesterday", school: "University of Ibadan", level: "100", sub_unit_pref: "Costume", responsibilities: ["Actor"], phone: "+2348071230003", mins: 1600 },
  ];
  batch = db.batch();
  for (const a of apps) {
    const d = new Date(); d.setMinutes(d.getMinutes() - a.mins);
    batch.set(db.collection("applications").doc(a.id), {
      first_name: a.name.split(" ")[0], last_name: a.name.split(" ").slice(1).join(" "),
      department: "DRAMA", department_name: "Drama", status: "PENDING",
      applied_label: a.applied, school: a.school, level: a.level,
      sub_unit_pref: a.sub_unit_pref, responsibilities: a.responsibilities,
      phone_number: a.phone, created_at: ts(d),
    });
  }
  await batch.commit();

  // Done Q2 scorecards for a few team workers (so the HOD queue shows progress).
  const doneCards = [
    { worker: "seed_w03", name: "Adaeze Nwosu", sub: "Actors", total: 88 },
    { worker: "seed_w04", name: "Joy Adebayo", sub: "Prayer Unit", total: 92 },
    { worker: "seed_w10", name: "Blessing Eze", sub: "Prayer Unit", total: 87 },
  ];
  batch = db.batch();
  for (const s of doneCards) {
    batch.set(db.collection("scorecards").doc(`${s.worker}_q2_2026`), {
      uid: s.worker, worker_name: s.name, sub_unit_name: s.sub,
      quarter: "Q2", year: 2026, total: s.total, pass: s.total >= 50,
      department_code: "DRAMA", status: "DONE", hod_name: "Grace Williams",
      hod_note: "Assessed for Q2.", categories: [], ack_status: null,
      assessed_at: ts(dayAt(-3, 10)),
    });
  }
  await batch.commit();

  // HOD notifications (addressed to DCN-00002).
  const hodNotifs = [
    { id: "h01", type: "TASK_SUBMITTED", title: "5 tasks awaiting your review", body: "Adaeze, Samuel, Mary, Funke, Blessing have submitted work.", read: false, urgent: false, at: "10 min ago", mins: 10, route: null },
    { id: "h02", type: "WORKER_AT_RISK", title: "2 workers flagged at risk", body: "Daniel & Yemi have missed 3+ weeks of reports.", read: false, urgent: true, at: "1 hour ago", mins: 60 },
    { id: "h03", type: "SIGNUP_REQUEST", title: "3 new sign-ups under your key", body: "Approve or reject from the Approvals screen.", read: false, urgent: false, at: "2 hours ago", mins: 120, route: "/hod/approvals" },
    { id: "h04", type: "SCORECARD_DUE", title: "Q2 scorecards due in 14 days", body: "12 workers to assess. 4 done, rest to go.", read: true, urgent: false, at: "Yesterday", mins: 1440 },
    { id: "h05", type: "MEETING_RSVP", title: "Stage Build Day — 18 RSVPed yes", body: "Out of 22 dept members.", read: true, urgent: false, at: "Yesterday", mins: 1500 },
  ];
  batch = db.batch();
  for (const n of hodNotifs) {
    const d = new Date(); d.setMinutes(d.getMinutes() - n.mins);
    batch.set(db.collection("notifications").doc(`${hodUid}_${n.id}`), {
      uid: hodUid, type: n.type, title: n.title, body: n.body,
      read: n.read, urgent: n.urgent, at: n.at, route: n.route || null,
      created_at: ts(d),
    });
  }
  await batch.commit();

  console.log(`✓ Seeded HOD Drama dataset (${team.length} team workers, ${review.length} review tasks, ${apps.length} applications, ${doneCards.length} done scorecards, ${hodNotifs.length} HOD notifications)`);
}

// ── Follow-Up worker dataset (members; FU worker = DCN-00003) ──
function att(rate) {
  // 12-week present/absent pattern from a rate (0..100), newest last.
  const present = Math.round((rate / 100) * 12);
  return Array.from({ length: 12 }, (_, i) => i >= 12 - present);
}
async function seedFuData(uidByMemberId) {
  const fu = uidByMemberId["DCN-00003"];
  if (!fu) return;

  const members = [
    { id: "mem_01", name: "Adaeze Nwosu", phone: "+2348051234001", dob: "May 22", cat: "Member", status: "Active", absent: 0, last: "Sun, 17 May", school: "University of Ibadan", level: "200", first_seen: "Jan 2024", att: 92, bday: "In 2 days" },
    { id: "mem_02", name: "Tunde Bakare", phone: "+2348051234002", dob: "Jul 04", cat: "Member", status: "At Risk", absent: 2, last: "Sun, 03 May", school: "University of Ibadan", level: "300", first_seen: "Sep 2023", att: 70, queue: { p: "high", r: "Missed 2 Sundays in a row" }, notes: [{ from: "Emeka Okoro", at: "Last Sun · 3:14 PM", body: "Called twice — no answer. Will try again Monday." }] },
    { id: "mem_03", name: "Chinwe Okeke", phone: "+2348051234003", dob: "May 21", cat: "Member", status: "Active", absent: 0, last: "Sun, 17 May", school: "LASU", level: "100", first_seen: "Feb 2025", att: 96, bday: "Today" },
    { id: "mem_04", name: "Samuel Adesina", phone: "+2348051234004", dob: "Aug 11", cat: "Member", status: "Unreachable", absent: 4, last: "Sun, 19 Apr", school: "University of Ibadan", level: "400", first_seen: "Jun 2024", att: 55, unreachable: true, queue: { p: "urgent", r: "Unreachable — 4 weeks absent" } },
    { id: "mem_05", name: "Blessing Eze", phone: "+2348051234005", dob: "May 26", cat: "Member", status: "Active", absent: 0, last: "Sun, 17 May", school: "University of Ibadan", level: "200", first_seen: "Mar 2024", att: 98, bday: "In 6 days" },
    { id: "mem_06", name: "Ifeanyi Madu", phone: "+2348051234006", dob: "Oct 03", cat: "Member", status: "Active", absent: 1, last: "Sun, 10 May", school: "University of Ibadan", level: "500", first_seen: "Apr 2023", att: 88 },
    { id: "mem_07", name: "Olamide Bello", phone: "+2348051234007", dob: "Jun 14", cat: "Member", status: "At Risk", absent: 3, last: "Sun, 26 Apr", school: "LASU", level: "300", first_seen: "Nov 2024", att: 64, queue: { p: "high", r: "Missed 3 Sundays" } },
    { id: "mem_08", name: "Kemi Falade", phone: "+2348051234008", dob: "Nov 19", cat: "Member", status: "Active", absent: 0, last: "Sun, 17 May", school: "University of Ibadan", level: "200", first_seen: "Aug 2024", att: 94 },
    { id: "mem_09", name: "Emeka Obi", phone: "+2348051234009", dob: "Mar 02", cat: "First-Timer", status: "First-Timer", absent: 0, last: "Sun, 17 May", school: "University of Ibadan", level: "100", first_seen: "Sun, 17 May", att: 100, pipeline: "Contacted", week: 1, queue: { p: "med", r: "First-timer welcome call" } },
    { id: "mem_10", name: "Halima Saliu", phone: "+2348051234010", dob: "Jan 28", cat: "First-Timer", status: "First-Timer", absent: 0, last: "Sun, 10 May", school: "LASU", level: "200", first_seen: "Sun, 10 May", att: 100, pipeline: "Returning", week: 2, queue: { p: "med", r: "First-timer welcome call", done: true, outcome: "Called & Spoke" }, notes: [{ from: "Emeka Okoro", at: "Mon 9:14am", body: "Called & Spoke — excited to come back Sunday." }] },
    { id: "mem_11", name: "Daniel Adekunle", phone: "+2348051234011", dob: "Dec 12", cat: "First-Timer", status: "First-Timer", absent: 0, last: "Sun, 17 May", school: "University of Ibadan", level: "300", first_seen: "Sun, 17 May", att: 100, pipeline: "Attending", week: 1, queue: { p: "med", r: "First-timer welcome call" } },
    { id: "mem_12", name: "Funke Adediran", phone: "+2348051234012", dob: "May 24", cat: "Member", status: "Active", absent: 0, last: "Sun, 17 May", school: "University of Ibadan", level: "400", first_seen: "Jul 2023", att: 90, bday: "In 4 days" },
    { id: "mem_13", name: "Yemi Adebowale", phone: "+2348051234013", dob: "Sep 30", cat: "Member", status: "Unreachable", absent: 5, last: "Sun, 12 Apr", school: "LASU", level: "500", first_seen: "Feb 2023", att: 42, unreachable: true, queue: { p: "urgent", r: "Unreachable — 5 weeks absent" } },
  ];
  let batch = db.batch();
  for (const m of members) {
    batch.set(db.collection("members").doc(m.id), {
      name: m.name, phone: m.phone, dob: m.dob, category: m.cat, status: m.status,
      weeks_absent: m.absent, last_attended: m.last, school: m.school, level: m.level,
      first_seen: m.first_seen, assigned_worker_uid: fu, unreachable: m.unreachable || false,
      pipeline_status: m.pipeline || "", week_number: m.week || 0,
      next_birthday_label: m.bday || "",
      in_queue: !!m.queue, queue_priority: m.queue ? m.queue.p : "med",
      queue_reason: m.queue ? m.queue.r : "", queue_status: m.queue && m.queue.done ? "DONE" : "PENDING",
      last_outcome: m.queue && m.queue.outcome ? m.queue.outcome : "",
      attendance: att(m.att),
      follow_up_notes: m.notes || [],
    });
  }
  await batch.commit();

  // A couple weekly reports + a meeting for DCN-00003 so the reused
  // Report/Schedule tabs render real content.
  batch = db.batch();
  batch.set(db.collection("reports").doc(`${fu}_w33`), { uid: fu, week_number: 33, week_label: "W33 · This week", submitted: false, bible: "", prayer: "", created_at: ts(dayAt(0, 8)) });
  batch.set(db.collection("reports").doc(`${fu}_w32`), { uid: fu, week_number: 32, week_label: "W32 · last week", submitted: true, bible: "Luke 15 — the lost sheep & prodigal.", prayer: "Prayed for my follow-up members by name.", created_at: ts(dayAt(-7, 8)) });
  batch.set(db.collection("reports").doc(`${fu}_w31`), { uid: fu, week_number: 31, week_label: "W31", submitted: true, bible: "1 Thessalonians.", prayer: "Interceded for the at-risk members.", created_at: ts(dayAt(-14, 8)) });
  batch.set(db.collection("meetings").doc("fu_sync"), {
    title: "Follow-Up Team Sync", type: "REGULAR", status: "SCHEDULED",
    date: fmtDay(dayAt(1, 18, 30)), start: fmtTime(dayAt(1, 18, 30)), end: fmtTime(dayAt(1, 19, 30)),
    start_at: ts(dayAt(1, 18, 30)), location: "Conference Room",
    agenda: "Review this week's queue + first-timer assignments.",
    department_code: "FOLLOWUP", audience_uids: [fu],
  });
  await batch.commit();

  console.log(`✓ Seeded Follow-Up worker dataset for DCN-00003 (${members.length} members, 3 reports, 1 meeting)`);
}

// ── Follow-Up HOD dataset (FU HOD = DCN-00004) ────────────────
async function seedFuHodData(uidByMemberId) {
  const fu = uidByMemberId["DCN-00003"];
  const hod = uidByMemberId["DCN-00004"];
  if (!fu || !hod) return;

  // FU-performance fields on the real FU worker (DCN-00003).
  await db.collection("users").doc(fu).set({
    week_reports: { bible: true, prayer: true }, sub_unit_name: "Calls",
    fu_assigned: 8, fu_contacted: 5, fu_queue_done_pct: 63, fu_unreachable_handled: 2,
    attendance_rate: 90, scorecard_last: 74, weeks_with_us: 60, at_risk: false,
  }, { merge: true });

  // Additional FU team workers (login-less).
  const team = [
    { id: "fu_w2", first: "Daniel", last: "Ochonogor", sub: "Pastoral Care Unit A", role: "SUBHOD", bible: true, prayer: true, assigned: 12, contacted: 11, pct: 92, unreach: 3, att: 95, last: 88 },
    { id: "fu_w3", first: "Halima", last: "Saliu", sub: "First-Timer Welcome", role: "WORKER", bible: true, prayer: false, assigned: 7, contacted: 6, pct: 86, unreach: 0, att: 90, last: 76 },
    { id: "fu_w4", first: "Peter", last: "Obi", sub: "Pastoral Care Unit A", role: "WORKER", bible: false, prayer: false, assigned: 9, contacted: 3, pct: 33, unreach: 1, att: 62, last: 48, at_risk: true },
    { id: "fu_w5", first: "Mary", last: "Onyema", sub: "Pastoral Care Unit B", role: "WORKER", bible: true, prayer: true, assigned: 10, contacted: 8, pct: 80, unreach: 0, att: 92, last: 81 },
    { id: "fu_w6", first: "Joy", last: "Adebayo", sub: "First-Timer Welcome", role: "SUBHOD", bible: true, prayer: true, assigned: 6, contacted: 6, pct: 100, unreach: 1, att: 98, last: 92 },
    { id: "fu_w7", first: "Grace", last: "Ekong", sub: "Pastoral Care Unit B", role: "WORKER", bible: true, prayer: false, assigned: 8, contacted: 4, pct: 50, unreach: 0, att: 84, last: 66 },
  ];
  let batch = db.batch();
  for (const w of team) {
    const name = `${w.first} ${w.last}`;
    batch.set(db.collection("users").doc(w.id), {
      uid: w.id, member_id: null, role: w.role, status: "APPROVED",
      department_id: "followup", department_code: "FOLLOWUP", department_name: "Follow-Up",
      sub_unit_name: w.sub, person: { first_name: w.first, last_name: w.last, photo_url: null },
      search_name: name.toLowerCase(),
      week_reports: { bible: w.bible, prayer: w.prayer },
      attendance_rate: w.att, scorecard_last: w.last, weeks_with_us: 50, at_risk: w.at_risk || false,
      tasks_open: 0, tasks_overdue: 0,
      fu_assigned: w.assigned, fu_contacted: w.contacted, fu_queue_done_pct: w.pct, fu_unreachable_handled: w.unreach,
    });
    batch.set(db.collection("worker_directory").doc(w.id), {
      name, search_name: name.toLowerCase(), department_name: "Follow-Up",
      sub_unit_name: w.sub, role: w.role, photo_url: null, status: "APPROVED",
    });
  }
  await batch.commit();

  // Pending FOLLOWUP applications (for the reused approvals screen).
  batch = db.batch();
  const fapps = [
    { id: "app_fu01", first: "Ngozi", last: "Uche", school: "University of Ibadan", level: "200", sub: "Calls", resp: ["Follow-up calling"], phone: "+2348071240001" },
    { id: "app_fu02", first: "Tobi", last: "Ade", school: "LASU", level: "300", sub: "First-Timer Welcome", resp: ["First-timer welcome"], phone: "+2348071240002" },
  ];
  for (const a of fapps) {
    batch.set(db.collection("applications").doc(a.id), {
      first_name: a.first, last_name: a.last, department: "FOLLOWUP", department_name: "Follow-Up",
      status: "PENDING", applied_label: "Yesterday", school: a.school, level: a.level,
      sub_unit_pref: a.sub, responsibilities: a.resp, phone_number: a.phone, created_at: ts(dayAt(-1, 10)),
    });
  }
  await batch.commit();

  // SMS templates.
  const templates = [
    { id: "tpl_bday_member", name: "Birthday — Member", category: "AUTO", body: "Happy birthday, {first_name}! 🎂 The whole DCN family is celebrating you today. — Pastor Femi" },
    { id: "tpl_bday_worker", name: "Birthday — Worker", category: "AUTO", body: "Happy birthday {first_name}! Thank you for serving so faithfully. — Pastor Femi" },
    { id: "tpl_check", name: "Absence — gentle", category: "AUTO", body: "Hi {first_name}, missed seeing you at The Experience yesterday — hoping you're OK. — DCN" },
    { id: "tpl_strong", name: "Absence — pastoral", category: "AUTO", body: "Hi {first_name}, we've missed you the last few Sundays. Please reach out so we can pray with you. — Pastor Femi" },
    { id: "tpl_visit", name: "Absence — visit", category: "AUTO", body: "Hi {first_name}, can a follow-up worker visit this week? Reply YES or NO. — DCN" },
    { id: "tpl_welcome", name: "First-timer welcome", category: "AUTO", body: "Welcome to DCN, {first_name}! 🙌 A follow-up worker will reach out this week. — Pastor Femi" },
    { id: "tpl_be_check", name: "Believers Equip miss", category: "AUTO", body: "Hi {first_name}, we missed you at Believers Equip. The Tuesday teaching is gold. — DCN" },
    { id: "tpl_announce", name: "Custom announcement", category: "MANUAL", body: "" },
  ];
  batch = db.batch();
  for (const t of templates) batch.set(db.collection("sms_templates").doc(t.id), { name: t.name, category: t.category, body: t.body });
  await batch.commit();

  // Absence rules.
  const rules = [
    { id: "sun_2", service: "sunday", threshold: 2, template_name: "Absence — gentle", body: templates[2].body, active: true },
    { id: "sun_4", service: "sunday", threshold: 4, template_name: "Absence — pastoral", body: templates[3].body, active: true },
    { id: "sun_6", service: "sunday", threshold: 6, template_name: "Absence — visit", body: templates[4].body, active: true },
    { id: "tue_3", service: "tuesday", threshold: 3, template_name: "Believers Equip miss", body: templates[6].body, active: true },
  ];
  batch = db.batch();
  for (const r of rules) batch.set(db.collection("sms_rules").doc(r.id), r);
  await batch.commit();

  // SMS log.
  const log = [
    { id: "sms01", to: "Tunde Bakare", to_phone: "+234805 … 002", type: "ABSENCE", template: "Absence — gentle", status: "DELIVERED", sent_at: "Today · 7:00 AM", auto: true, sort_key: 100 },
    { id: "sms02", to: "Chinwe Okeke", to_phone: "+234805 … 003", type: "BIRTHDAY", template: "Birthday — Member", status: "DELIVERED", sent_at: "Today · 7:00 AM", auto: true, sort_key: 99 },
    { id: "sms03", to: "Samuel Adesina", to_phone: "+234805 … 004", type: "ABSENCE", template: "Absence — visit", status: "FAILED", sent_at: "Today · 7:00 AM", auto: true, error: "Phone switched off", sort_key: 98 },
    { id: "sms04", to: "All Follow-Up dept (7)", to_phone: "7 recipients", type: "MEETING", template: "Meeting reminder", status: "DELIVERED", sent_at: "Yesterday · 11:42 AM", auto: false, sort_key: 80 },
    { id: "sms05", to: "Olamide Bello", to_phone: "+234805 … 007", type: "ABSENCE", template: "Absence — pastoral", status: "DELIVERED", sent_at: "Yesterday · 7:00 AM", auto: true, sort_key: 79 },
    { id: "sms06", to: "All members (13)", to_phone: "13 recipients", type: "BLAST", template: "Custom announcement", status: "DELIVERED", sent_at: "Mon · 8:00 PM", auto: false, sort_key: 60 },
  ];
  batch = db.batch();
  for (const l of log) batch.set(db.collection("sms_log").doc(l.id), l);
  await batch.commit();

  // Done Q2 scorecards for two FU workers (reused scorecard queue shows progress).
  batch = db.batch();
  for (const s of [{ w: "fu_w2", name: "Daniel Ochonogor", sub: "Pastoral Care Unit A", total: 90 }, { w: "fu_w6", name: "Joy Adebayo", sub: "First-Timer Welcome", total: 94 }]) {
    batch.set(db.collection("scorecards").doc(`${s.w}_q2_2026`), {
      uid: s.w, worker_name: s.name, sub_unit_name: s.sub, quarter: "Q2", year: 2026,
      total: s.total, pass: true, department_code: "FOLLOWUP", status: "DONE",
      hod_name: "Ada Nwosu", hod_note: "Assessed for Q2.", categories: [], ack_status: null,
      assessed_at: ts(dayAt(-3, 10)),
    });
  }
  await batch.commit();

  // FU HOD notifications (to DCN-00004).
  const notifs = [
    { id: "fh01", type: "ABSENCE_ESCALATED", title: "Yemi Adebowale — 5 weeks unreachable", body: "Pastoral visit recommended.", read: false, urgent: true, at: "30 min ago", mins: 30 },
    { id: "fh02", type: "WORKER_PERFORMANCE", title: "Peter Obi behind on follow-ups", body: "Only 3 of 9 assigned members contacted.", read: false, urgent: false, at: "1 hour ago", mins: 60 },
    { id: "fh03", type: "SMS_FAILED", title: "1 absence SMS failed today", body: "Samuel Adesina — phone switched off.", read: false, urgent: false, at: "3 hours ago", mins: 180 },
    { id: "fh04", type: "SIGNUP_REQUEST", title: "2 new sign-ups under your key", body: "Approve or decline from Approvals.", read: true, urgent: false, at: "Yesterday", mins: 1440, route: "/hod/approvals" },
  ];
  batch = db.batch();
  for (const n of notifs) {
    const d = new Date(); d.setMinutes(d.getMinutes() - n.mins);
    batch.set(db.collection("notifications").doc(`${hod}_${n.id}`), {
      uid: hod, type: n.type, title: n.title, body: n.body, read: n.read, urgent: n.urgent,
      at: n.at, route: n.route || null, created_at: ts(d),
    });
  }
  await batch.commit();

  console.log(`✓ Seeded Follow-Up HOD dataset (${team.length} FU team, ${fapps.length} applications, ${templates.length} templates, ${rules.length} rules, ${log.length} SMS log, ${notifs.length} notifications)`);
}

// ── Pastor / Super-Admin dataset (Pastor = DCN-00005) ─────────
async function seedPastorData(uidByMemberId) {
  const pastor = uidByMemberId["DCN-00005"];
  if (!pastor) return;

  // Enrich the existing dept invite codes with role + expiry, and add a couple
  // with varied statuses so the Access Keys screen shows the full lifecycle.
  const enrich = [
    { code: "DRAMA-9F2K-44XQ", role: "WORKER", dept: "Drama", uses: 4, max: 50 },
    { code: "WORSHIP-7A1B-22MN", role: "WORKER", dept: "Worship", uses: 2, max: 50 },
    { code: "MEDIA-3C5D-88PL", role: "WORKER", dept: "Media", uses: 8, max: 50 },
    { code: "USHERING-6E4F-19KJ", role: "WORKER", dept: "Ushering", uses: 3, max: 50 },
    { code: "TECHNICAL-8G2H-77RT", role: "WORKER", dept: "Technical", uses: 1, max: 50 },
    { code: "FOLLOWUP-1J9K-05ZP", role: "WORKER", dept: "Follow-Up", uses: 6, max: 50 },
  ];
  let batch = db.batch();
  for (const c of enrich) {
    batch.set(db.collection("invite_codes").doc(c.code), {
      role: c.role, department_name: c.dept, expires: "30 Jun 2026", uses: c.uses,
    }, { merge: true });
  }
  // Extra codes: one exhausted, one revoked.
  batch.set(db.collection("invite_codes").doc("DCN-SUB-1K8P"), { code: "DCN-SUB-1K8P", role: "SUBHOD", department_name: "Worship", department_code: "WORSHIP", max_uses: 1, uses: 1, active: true, expires: "15 Jul 2026" });
  batch.set(db.collection("invite_codes").doc("DCN-HOD-5R7T"), { code: "DCN-HOD-5R7T", role: "HOD", department_name: "Technical", department_code: "TECHNICAL", max_uses: 1, uses: 0, active: false, expires: "01 Jun 2026" });
  await batch.commit();

  // Church-wide analytics doc.
  await db.collection("analytics").doc("church").set({
    attendance_monthly: [
      { month: "Jan", sunday: 69, tuesday: 51, present: 284 },
      { month: "Feb", sunday: 71, tuesday: 54, present: 293 },
      { month: "Mar", sunday: 74, tuesday: 58, present: 305 },
      { month: "Apr", sunday: 72, tuesday: 56, present: 297 },
      { month: "May", sunday: 76, tuesday: 60, present: 313 },
      { month: "Jun", sunday: 78, tuesday: 62, present: 321 },
    ],
    attendance_sunday_avg: 78, attendance_tuesday_avg: 62, attendance_trend: "+4%",
    services: [
      { name: "The Experience", date: "Sun, 7 Jun", type: "SUNDAY", present: 318, late: 24, absent: 70 },
      { name: "Believers Equip", date: "Tue, 9 Jun", type: "TUESDAY", present: 251, late: 12, absent: 149 },
      { name: "The Experience", date: "Sun, 31 May", type: "SUNDAY", present: 309, late: 31, absent: 72 },
    ],
    sms: { sent: 384, delivered: 362, failed: 9, pending: 13, rate: 94.3, cost_month: "₦4,820" },
    blasts: [
      { name: "Communion Sunday reminder", audience: "All members", count: 412, status: "SCHEDULED", at: "Sat · 6:00 PM", delivered: 0, failed: 0 },
      { name: "Town hall — Drama dept", audience: "Drama workers", count: 22, status: "SENT", at: "Yesterday · 3 PM", delivered: 21, failed: 1 },
      { name: "First-timer welcome batch", audience: "First-timers", count: 12, status: "SENT", at: "Mon · 9:00 AM", delivered: 12, failed: 0 },
    ],
    retention: { first_timers_90d: 27, returned: 14, retained_pct: 52, at_risk_total: 18, at_risk_recovered: 9, avg_contact_days: 1.8 },
  });

  // Pastor notifications.
  const notifs = [
    { id: "p01", type: "DEPT_WATCH", title: "Drama dept marked 'Watch'", body: "Reports completion dropped. HOD notified.", read: false, urgent: true, at: "1h ago", mins: 60, route: null },
    { id: "p02", type: "APPROVALS", title: "New sign-ups awaiting approval", body: "Across several departments.", read: false, urgent: false, at: "2h ago", mins: 120, route: "/p/approvals" },
    { id: "p03", type: "ATTENDANCE", title: "Sunday attendance trending up", body: "+4% this month.", read: false, urgent: false, at: "Yesterday", mins: 1440, route: "/p/attendance" },
    { id: "p04", type: "SCORECARDS", title: "Q2 scorecards · 30 days left", body: "Assessment window closing.", read: true, urgent: false, at: "Yesterday", mins: 1500, route: "/p/scorecards" },
    { id: "p05", type: "MEETING", title: "Drama Town Hall called", body: "Emergency meeting · 22 notified.", read: true, urgent: false, at: "3h ago", mins: 180, route: null },
  ];
  batch = db.batch();
  for (const n of notifs) {
    const d = new Date(); d.setMinutes(d.getMinutes() - n.mins);
    batch.set(db.collection("notifications").doc(`${pastor}_${n.id}`), {
      uid: pastor, type: n.type, title: n.title, body: n.body, read: n.read,
      urgent: n.urgent, at: n.at, route: n.route, created_at: ts(d),
    });
  }
  await batch.commit();

  // A Pastor member_id + profile bits so their profile screen reads well.
  await db.collection("users").doc(pastor).set({
    member_id: "DCN-00005", access_key: "PASTOR-MASTER-KEY", phone: "+2348100000001",
    joined_label: "12 Mar 2018",
  }, { merge: true });

  console.log(`✓ Seeded Pastor dataset (invite codes enriched, analytics doc, ${notifs.length} notifications)`);
}

(async () => {
  console.log(`Seeding project: ${PROJECT_ID}`);
  await seedDepartments();
  await seedInviteCodes();
  await seedCounters();
  const uidByMemberId = await seedUsers();
  await seedWorkerData(uidByMemberId["DCN-00001"]);
  await seedDeptData(uidByMemberId);
  await seedFuData(uidByMemberId);
  await seedFuHodData(uidByMemberId);
  await seedPastorData(uidByMemberId);
  console.log("\nAll done. Test accounts share the password:", TEST_PASSWORD);
  console.log("Sign in with a member ID, e.g. DCN-00001 (Worker) or DCN-00005 (Pastor).");
  process.exit(0);
})().catch((e) => {
  console.error("Seed failed:", e);
  process.exit(1);
});
