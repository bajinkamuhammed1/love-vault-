import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const url = String.fromEnvironment('SUPABASE_URL');
  const publishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  if (url.isEmpty || publishableKey.isEmpty) {
    throw StateError(
      'Missing SUPABASE_URL or SUPABASE_PUBLISHABLE_KEY. '
      'Pass them with --dart-define.',
    );
  }

  await Supabase.initialize(url: url, publishableKey: publishableKey);

  if (Supabase.instance.client.auth.currentSession == null) {
    await Supabase.instance.client.auth.signInAnonymously();
  }

  runApp(const LoveVaultApp());
}
