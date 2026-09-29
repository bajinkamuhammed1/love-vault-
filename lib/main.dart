import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _BootstrapApp());
}

class _BootstrapApp extends StatefulWidget {
  const _BootstrapApp();

  @override
  State<_BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<_BootstrapApp> {
  Object? _error;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      const url = String.fromEnvironment('SUPABASE_URL');
      const publishableKey =
          String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

      if (url.isEmpty || publishableKey.isEmpty) {
        throw StateError(
          'Love Vault is missing its Supabase build configuration.',
        );
      }

      await Supabase.initialize(url: url, publishableKey: publishableKey);

      if (Supabase.instance.client.auth.currentSession == null) {
        await Supabase.instance.client.auth.signInAnonymously();
      }

      if (!mounted) return;
      setState(() => _ready = true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return const LoveVaultApp();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Love Vault',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8E3A59)),
      ),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _error == null
                  ? const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.favorite, size: 64),
                        SizedBox(height: 20),
                        Text(
                          'Love Vault',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 20),
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Connecting securely...'),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 56),
                        const SizedBox(height: 16),
                        const Text(
                          'Love Vault could not start',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _error.toString(),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: () {
                            setState(() {
                              _error = null;
                              _ready = false;
                            });
                            _initialize();
                          },
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
