# Love Vault

Love Vault is a private, text-first Flutter app designed around a two-person room.

## V1
- Home
- Play
- Ask Me
- Surprise
- Memories
- Profile and Settings
- Supabase anonymous authentication
- Private room membership protected by Row Level Security
- No photo or file uploads

## Run

Use the project's public Supabase URL and publishable key:

```bash
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=YOUR_URL \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

Never put a Supabase secret/service-role key in this app.

## Backend

The connected Supabase project contains the V1 schema, RLS policies, starter categories/questions, and secure create/join room RPCs.

Anonymous sign-in must be enabled in Supabase Auth before the app can create its first anonymous session.
