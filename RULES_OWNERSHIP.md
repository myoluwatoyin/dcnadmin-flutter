# Security rules are owned by the DCN Sermons repo

The Firebase project `dcnchurchadmin` is shared with the DCN Sermons app
(`~/development/dcn-sermons`). Since 2026-09-25 the **merged** Firestore, Storage
and Realtime Database rules and the Firestore indexes are deployed only from
`dcn-sermons/infra/`. This repo's `firestore.rules`, `storage.rules` and
`firestore.indexes.json` are kept as the reference copy of the workers block
(`dcn-sermons/infra/rules-tests/check-workers-sync.sh` checks they still match).

- Do NOT run `firebase deploy --only firestore` / `storage` from this repo; the
  targets were removed from `firebase.json` so it cannot happen by accident.
- To change a workers rule: edit it here, then copy the block into
  `dcn-sermons/infra/firestore.rules` (between the BEGIN/END markers), run the
  rules tests there, and deploy from there.
- `firebase deploy --only functions` from this repo is still fine (codebase `default`).
