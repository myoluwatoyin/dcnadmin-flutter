# DCN Admin Mobile App Product Brief

This Flutter app is a fresh mobile-only rebuild of the DCN Church Admin system. The previous project had a web admin app and a React Native mobile prototype; use them only as behavior/design references. The new app should be built cleanly in Flutter.

## Project Status

- Local repo: `/Users/mac/development/dcnadmin-flutter`
- GitHub repo: `https://github.com/myoluwatoyin/dcnadmin-flutter`
- Flutter project name: `dcnadmin`
- Firebase project ID: `dcnchurchadmin`
- Firebase CLI account currently connected: `ictsolutionsomega@gmail.com`
- Android application ID: `com.dcnchurchadmin.dcnadmin`
- iOS bundle ID: `com.dcnchurchadmin.dcnadmin`
- Supported platforms for now: Android and iOS only

Firebase has already been configured through FlutterFire:

- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `firebase.json`
- `.firebaserc`

Installed Firebase packages:

- `firebase_core`
- `firebase_auth`
- `cloud_firestore`
- `firebase_storage`
- `firebase_messaging`

## App Purpose

DCN Admin is a church operations app for:

- Worker, HOD/Sub-HOD, Follow-up worker, Follow-up HOD, Pastor, and admin-facing workflows.
- Member onboarding and approval.
- Department and sub-unit management.
- Tasks, meetings, attendance, reports, scorecards, follow-up, notifications, schedules, SMS, accountability, and worker health.

The first priority is a real, production-ready mobile auth and onboarding foundation. Do not build from demo-only screens.

## Visual Assets

Use the provided DCN assets from:

- `assets/branding/dcn-logo.png`
- `assets/branding/dcn-icon.png`
- `assets/branding/dcn-icon-square.png`
- `assets/branding/dcn-hero.png`

These assets were copied from the old mobile project. They are registered in `pubspec.yaml` under:

```yaml
assets:
  - assets/branding/
```

Use the logo on splash/auth screens where appropriate. Keep the final UI aligned with the design preference the user sends, but preserve the behavioral requirements below even if the design mockup uses placeholder/demo interactions.

## Backend Rule

Firebase is the major backend for this rebuild. Build real data access layers for Firebase instead of relying on hardcoded prototype arrays.

Do not use demo data in signup or login flows. In particular:

- Do not prefill login with demo member IDs or passwords.
- Do not implement preview-login role switches.
- Do not show "Preview suspended account" controls.
- Do not hardcode ministry departments/sub-units in the signup flow if backend data exists.
- Do not hardcode "worker that invited you" data. Search/fetch real approved workers.
- Do not validate invite codes locally. Validate against the backend.

Recommended architecture:

- `services/` or `data/` layer for Firebase Auth, Firestore, Storage, and Messaging.
- Repository abstractions for auth, signup, departments, invite codes, workers, user session, and role dashboards.
- UI screens should call repositories/providers, not Firebase SDK calls directly throughout widgets.

If a temporary legacy API bridge is needed while Firebase collections/functions are being finalized, isolate it behind repositories and keep the UI unchanged. Do not mix demo data into production flows.

## Auth Overview

The old production behavior used member-ID login, not email login. Preserve that product behavior unless the user explicitly approves a change.

### Splash

Splash/auth landing should show DCN branding and two actions:

- Sign in
- Create new account

The old copy was:

- Title: `DCN Church Admin`
- Body: `Church operations, follow-up, reporting, meetings, tasks, and team health.`

Use the user's design preference for visual treatment, but keep the two clear auth actions.

### Sign In

Fields:

- `member_id`
- `password`

Behavior:

- Member ID is required.
- Password is required.
- Submit against the real backend.
- Store the returned auth/session credentials securely.
- Fetch/refresh the real user session after login.
- Route by returned role/persona:
  - `PASTOR` or `SUPER_ADMIN` -> pastor/admin mobile area.
  - `HOD` with Follow-Up department -> follow-up HOD area.
  - `HOD` or `SUBHOD` -> HOD area.
  - `WORKER` in Follow-Up department -> follow-up worker area.
  - Other `WORKER` -> worker area.
- If status is not approved, the backend should reject login or the app should block access and show the correct state.
- Suspended users should be sent to an account suspended screen, not allowed into dashboards.

Do not include a role selector on real login. The previous mobile prototype had Worker/HOD/Pastor segmented controls only for preview/demo auth. Production login should infer the user's role from the backend response.

Do not include biometric auth as a fake login action. Only add biometric unlock later if it unlocks a previously authenticated secure local session.

Expected login response shape from the old backend for reference:

```json
{
  "success": true,
  "token": "...",
  "refreshToken": "...",
  "user": {
    "id": "...",
    "member_id": "...",
    "role": "WORKER",
    "status": "APPROVED",
    "department_id": "...",
    "department_name": "Drama",
    "department_code": "DRAMA",
    "sub_unit_id": "...",
    "sub_unit_name": "...",
    "persona": "worker",
    "person": {
      "first_name": "...",
      "last_name": "...",
      "photo_url": "..."
    }
  }
}
```

For the Firebase rebuild, model equivalent fields in Firebase Auth custom claims and/or Firestore user documents.

## Signup Overview

Signup is a six-step application flow. It creates a pending account/application and does not automatically sign the user in.

Steps:

1. Identity
2. Student
3. Church
4. Ministry
5. Responsibilities
6. Security

After successful submission:

- Clear the local draft.
- Show an approval-pending screen.
- Explain that the application is awaiting HOD/Pastor review.
- Show submitted timestamp, selected department, and available approver names when returned by the backend.
- Provide a route back to sign in.

Old pending-state copy:

- Title: `You're on the list!`
- Body: `Your application is with your HOD. We'll text you the moment you're approved.`
- Timeline item: `Application submitted`
- Timeline item: `Awaiting HOD review`

## Signup Fields

Use these exact payload names so backend mapping stays consistent.

### Step 1: Identity

Fields:

- `photo`
- `first_name`
- `last_name`
- `other_names`
- `gender`
- `date_of_birth`
- `phone_number`
- `email`
- `whatsapp_same_as_phone`
- `whatsapp_number`

Validation:

- `first_name` required.
- `last_name` required.
- `gender` required.
- `date_of_birth` required.
- `phone_number` required.
- `email` required and must be a valid email.
- If `whatsapp_same_as_phone` is false, `whatsapp_number` is required.
- If `whatsapp_same_as_phone` is true, submit `whatsapp_number` as `phone_number`.

Gender options:

- `Male`
- `Female`

Photo:

- Let the user select/capture a profile photo.
- Upload via Firebase Storage or submit as part of the backend signup flow.
- Store resulting URL/public metadata on the user/person record.

### Step 2: Student

Fields:

- `is_student`
- `institution`
- `other_institution`
- `faculty`
- `course`
- `level`
- `matric_number`
- `hostel`
- `room_number`
- `occupation`
- `workplace`
- `work_address`
- `home_address`
- `city`
- `state`
- `country`

Validation:

- `is_student` required.

If `is_student` is `yes`:

- `institution` required.
- If institution is `Other`, `other_institution` required and should be submitted as the institution name.
- `faculty` required.
- `course` required.
- `level` required.
- `hostel` required.
- If hostel is selected, `room_number` required.
- `matric_number` optional.

If `is_student` is `no`:

- `occupation` required.
- `workplace` required.
- `work_address` required.
- `home_address` required.
- `city` required.
- `state` required.
- `country` required.

Known UI option sets from the previous product:

- Institutions: `University of Ibadan`, `Other`
- Levels: `100`, `200`, `300`, `400`, `500`, `Postgraduate`
- Faculties: `Agriculture & Forestry`, `Arts`, `Basic Medical Sciences`, `Clinical Sciences`, `Dentistry`, `Education`, `Law`, `Pharmacy`, `Public Health`, `Science`, `Social Sciences`, `Technology`, `Veterinary Medicine`
- Hostels: `Indy`, `Zik`, `Bello`, `Kuti`, `Mellanby`, `Tedder`, `Idia`, `Queens`, `Awo`, `St Anne's`, `ITH`, `CMF`, `AOO`, `Immanuel College Hostel`, `Talent`, `CBN`, `Water Brooks`

These school option lists can be local constants initially unless the Firebase backend has an admin-managed source for them.

### Step 3: Church

Fields:

- `attendance_duration`
- `is_church_member`
- `attends_believers_equip`
- `invited_by_text`
- `invited_by_worker_id`
- `invited_by_worker_name`

Validation:

- `attendance_duration` required.
- `is_church_member` required.
- `attends_believers_equip` required.
- `invited_by_text` required.
- `invited_by_worker_id` optional, but if the user selects a worker it must be a real approved worker from backend search.

Options:

- Attendance duration: `First time`, `Less than 3 months`, `3-6 months`, `6 months - 1 year`, `More than 1 year`
- Church member: `Yes`, `No`, `First Timer`
- Believers Equip attendance: `Yes regularly`, `Sometimes`, `No`

Backend data requirement:

- The "Worker that invited you" search must call the backend as the user types.
- Search should start after at least 2 characters and debounce around 300ms.
- Store both selected worker ID and selected display name.

### Step 4: Ministry

Fields:

- `department`
- `sub_unit`

Validation:

- `department` required.
- `sub_unit` optional unless the backend marks a department as requiring it.

Important backend requirement:

- Fetch departments and sub-units from the backend.
- Do not hardcode the prototype department/sub-unit arrays for the production signup flow.
- Department values submitted to the backend should use the backend's stable code/name convention. The old backend accepted department codes such as `WORSHIP`, `MEDIA`, `USHERING`, `DRAMA`, `TECHNICAL`, `FOLLOWUP`.
- Sub-unit values submitted should match backend names or IDs consistently. Prefer IDs internally and map to names/codes only at the repository boundary if the backend requires names.

Old endpoint shape for reference:

```json
[
  {
    "id": "...",
    "name": "Media",
    "code": "MEDIA",
    "sub_units": [
      { "id": "...", "name": "Photography and Videography" }
    ]
  }
]
```

### Step 5: Responsibilities

Fields:

- `serving_another_church`
- `other_church_name`
- `other_church_role`
- `additional_responsibilities`
- `emergency_contact_name`
- `emergency_contact_phone`
- `guardian_name`
- `guardian_phone`

Validation:

- `serving_another_church` required.
- If `serving_another_church` is `yes`, `other_church_name` and `other_church_role` are required.
- `emergency_contact_name` required.
- `emergency_contact_phone` required.
- If `is_student` is `yes`, `guardian_name` and `guardian_phone` are required.
- `additional_responsibilities` optional.

When submitting, convert `serving_another_church` to a boolean-compatible value if the backend expects that.

### Step 6: Security

Fields:

- `role`
- `invite_code`
- `password`
- `confirm_password`
- `agreement`

Role options:

- `PASTOR`
- `HOD`
- `SUBHOD`
- `WORKER`

Validation:

- `role` required.
- If `role` is not `PASTOR`, `invite_code` required.
- `password` required.
- Password must be at least 8 characters.
- Password must contain at least 1 number.
- Password must contain at least 1 special character.
- `confirm_password` must match `password`.
- `agreement` required.

Agreement text:

`I confirm that the information provided is correct and I am willing to serve faithfully in DCN.`

Invite-code behavior:

- Validate invite code against the backend before final signup.
- For non-pastor roles, validate the code with the selected department.
- If the backend says invalid, expired, max uses reached, or department mismatch, show a clear inline error and do not submit.
- Pastor signup skips invite-code validation, but still creates a pending account/application unless backend policy changes.

## Signup Submission Payload

Submit the same fields listed above. The old backend used multipart form submission so it could include `photo`; the Firebase rebuild may use a two-step flow:

1. Upload profile photo to Firebase Storage, if provided.
2. Submit the application document/user profile to Firestore or a Cloud Function.

The stored application should include enough data for approvers to review and approve/reject the user, assign member ID, department, sub-unit, and role.

For compatibility with the old backend shape, preserve these normalized values:

- `is_student`: boolean or `yes`/`no`, but be consistent at repository boundary.
- `serving_another_church`: boolean or `yes`/`no`, but be consistent at repository boundary.
- `department`: stable department code or ID.
- `sub_unit`: stable sub-unit ID or name.
- `role`: uppercase enum.
- `status`: initially `PENDING`.

## Approval Behavior

Signup creates a pending user/application:

- New signups are not approved immediately.
- Approved users receive/are assigned a `member_id`.
- Only approved users can sign in.
- HODs should see pending signups for their department.
- Pastors/admins should see global pending signups.

Approval notifications should be generated through the backend. In the old system, signup notified HODs, pastors, and super admins.

## Session and Routing

After login/session restore, route based on `persona` if available. Derive if needed:

- `SUPER_ADMIN` or `PASTOR` -> `pastor`
- `HOD` + department code `FOLLOWUP` -> `followup_hod`
- `HOD` or `SUBHOD` -> `hod`
- department code `FOLLOWUP` -> `followup_worker`
- otherwise -> `worker`

Initial route targets can be:

- `worker` -> worker home
- `hod` -> HOD home
- `followup_worker` -> follow-up worker home
- `followup_hod` -> follow-up HOD home
- `pastor` -> pastor home/admin area

## Existing Backend Endpoints For Reference

The old Fastify backend exposed these real endpoints. The Firebase rebuild should implement equivalent Firebase/Cloud Function/Firestore behavior, or temporarily call these behind repositories if the old API remains available.

Public:

- `POST /auth/signup`
- `POST /auth/login`
- `POST /auth/admin/login`
- `GET /workers/search?q=...`
- `GET /departments`
- `GET /invite-codes/validate?code=...&department=...`

Authenticated mobile:

- `GET /mobile/session`
- `GET /mobile/worker/home`
- `GET /mobile/hod/home`
- `GET /mobile/followup-hod/home`
- `GET /mobile/followup-worker/home`
- `GET /mobile/pastor/home`
- `GET /mobile/people`
- `GET /mobile/people/:id`
- `GET /mobile/notifications`
- `GET /mobile/activity`
- `GET /mobile/calendar`
- `GET /mobile/settings`

## Prototype Code References

Use these old files only for understanding behavior. Do not copy React Native code into Flutter.

- Old mobile splash: `/Users/mac/development/dcn-church-admin/apps/mobile/app/(auth)/splash.tsx`
- Old mobile login prototype: `/Users/mac/development/dcn-church-admin/apps/mobile/app/(auth)/login.tsx`
- Old mobile signup prototype: `/Users/mac/development/dcn-church-admin/apps/mobile/app/(auth)/signup.tsx`
- Production web login behavior: `/Users/mac/development/dcn-church-admin/apps/web/src/pages/LoginPage.tsx`
- Production web signup behavior: `/Users/mac/development/dcn-church-admin/apps/web/src/pages/signup/SignupPage.tsx`
- Signup step fields: `/Users/mac/development/dcn-church-admin/apps/web/src/pages/signup/`
- Old backend auth service: `/Users/mac/development/dcn-church-admin/apps/api/src/services/auth.service.ts`
- Old backend mobile routes: `/Users/mac/development/dcn-church-admin/apps/api/src/routes/mobile.ts`

## Design Preference Notes

The user will provide design preference output separately. Follow that visual direction, with these deliberate product differences:

- Login should not be demo-oriented.
- Login should not ask the user to choose Worker/HOD/Pastor. The backend determines role/persona.
- Login should not contain preview/demo account buttons.
- Signup should not use dummy departments, sub-units, invite codes, or worker search lists.
- Signup should use real backend data and show loading/error/empty states for each backend fetch.
- Signup should collect the full six-step form above, not a shortened mockup form.
- Signup success should show pending approval, not navigate directly into the app.

## Implementation Quality Expectations

- Keep Flutter code organized by feature: `auth`, `signup`, `home`, `shared`, `services`, `repositories`, `models`.
- Use typed models for users, departments, sub-units, invite validation, signup drafts, and auth session.
- Keep validation centralized enough that fields and submit behavior stay consistent.
- Persist signup drafts locally, excluding passwords and large file objects.
- Use secure storage for tokens/session secrets if using custom tokens or API tokens.
- Show user-friendly backend errors inline.
- Add tests for validation and route/persona derivation.
- Run `flutter analyze`, `flutter test`, and `flutter build apk --debug` before handing back.
