# pc_app

Flutter client for managing esports centers, bookings, owner onboarding, and
admin workflows on top of Firebase.

## Backend shape

The app now uses Firebase Authentication + Cloud Firestore + Cloud Storage for
the main business flows:

- `centers`: center metadata and image references
- `bookings`: customer bookings, cancel/check-in state, no-show state
- `center_blocked_seats`: owner-managed blocked seats per center
- `user_roles`: customer / owner_pending / owner / admin role records
- `owner_applications`: owner request form submissions
- `user_directory`: lightweight email directory for admin user listings
- `avatars/*` and `centers/*`: image uploads in Firebase Storage

Local `SharedPreferences` is still used as a cache/fallback layer, but Firebase
is the shared source for backend data.

## Admin bootstrap

The current hardcoded admin email is:

- `batsaikhanbatmunkh88@gmail.com`

If you want another admin account, update the allowlist in both:

- `lib/data/role_store.dart`
- `firestore.rules`

## Deploy rules

This repo already points Firebase CLI at:

- `firestore.rules`
- `storage.rules`

Deploy both after backend changes:

```bash
firebase deploy --only firestore:rules,storage
```

## Notes

- Customer bookings and seat-block changes now sync across devices through
  Firestore snapshots.
- Owner approval and role changes are reflected through Firestore-backed role
  data instead of device-local storage only.
- If Firebase initialization fails, the app still falls back safely instead of
  crashing on profile startup.
