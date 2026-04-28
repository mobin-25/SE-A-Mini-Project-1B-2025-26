# WildTrack (Supabase Backend)

This app was migrated from Firebase to Supabase for:
- Authentication (email + password)
- Postgres database (alerts table)
- Storage (alert image uploads)

## 1) Supabase Project Setup

1. Open your Supabase project dashboard.
2. Go to Authentication -> Providers.
3. Enable Email provider.
4. In Authentication -> URL Configuration, add your app redirect URL if needed.
5. Open Settings -> API and copy:
	 - Project URL
	 - anon public key

## 2) Create Database + Policies

1. Open SQL Editor in Supabase.
2. Run the SQL from supabase/schema.sql.
3. Confirm that:
	 - alerts table exists
	 - alert-images storage bucket exists
	 - RLS policies were created

## 3) Flutter Configuration

This project now reads Supabase credentials from dart-defines:
- SUPABASE_URL
- SUPABASE_ANON_KEY

Run the app with:

```bash
flutter pub get
flutter run --dart-define=SUPABASE_URL=YOUR_SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

> Make sure `SUPABASE_URL` is the project endpoint, not the dashboard URL. Example:
> `https://your-project.supabase.co`
> 
> Do not use a URL like `https://supabase.com/dashboard/project/<id>`.

## 4) Authentication Flow in App

1. Signup screen creates user with email/password.
2. If email confirmation is enabled, user verifies email first.
3. Login screen signs in with email/password.
4. AuthGate listens for auth state and opens Home page when signed in.
5. Logout calls Supabase signOut.

## 5) Alerts Flow

1. User enters message and optionally picks an image.
2. Image uploads to storage bucket alert-images under alerts/<user_id>/.
3. App inserts alert row into alerts table.
4. Home stream listens to realtime updates and renders recent alerts.

## 6) Troubleshooting

- If startup throws missing key/url:
	- Ensure both dart-defines are passed.
- If insert fails with RLS error:
	- Confirm you ran supabase/schema.sql successfully.
- If image upload fails:
	- Verify storage bucket alert-images exists.
	- Verify storage policies exist and user is authenticated.
