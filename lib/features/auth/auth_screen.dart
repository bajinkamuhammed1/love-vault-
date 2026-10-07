import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _signUp = false;
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.length < 6) {
      setState(() => _message = 'Enter your email and a password of at least 6 characters.');
      return;
    }
    setState(() { _busy = true; _message = null; });
    try {
      final auth = Supabase.instance.client.auth;
      if (_signUp) {
        final response = await auth.signUp(email: email, password: password);
        if (!mounted) return;
        if (response.session == null) {
          setState(() => _message = 'Check your email and confirm your address, then come back and sign in.');
        }
      } else {
        await auth.signInWithPassword(email: email, password: password);
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _message = e.message);
    } catch (_) {
      if (mounted) setState(() => _message = 'Could not connect. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(26),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: CircleAvatar(radius: 34, backgroundColor: Color(0xFFE9365A), child: Icon(Icons.favorite, color: Colors.white, size: 34))),
                const SizedBox(height: 20),
                Text('Love Vault', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 8),
                Text('Sign in to your Love Vault account.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 28),
                TextField(controller: _email, keyboardType: TextInputType.emailAddress, autofillHints: const [AutofillHints.email], decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined))),
                const SizedBox(height: 12),
                TextField(controller: _password, obscureText: true, autofillHints: _signUp ? const [AutofillHints.newPassword] : const [AutofillHints.password], onSubmitted: (_) => _busy ? null : _submit(), decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline))),
                if (_message != null) Padding(padding: const EdgeInsets.only(top: 14), child: Text(_message!, textAlign: TextAlign.center)),
                const SizedBox(height: 18),
                FilledButton(onPressed: _busy ? null : _submit, child: Text(_busy ? 'Please wait…' : (_signUp ? 'Create account' : 'Sign in'))),
                const SizedBox(height: 10),
                TextButton(onPressed: _busy ? null : () => setState(() { _signUp = !_signUp; _message = null; }), child: Text(_signUp ? 'Already registered? Sign in' : 'First time here? Create account')),
                const SizedBox(height: 8),
                const Text('Signing in does not grant Love Vault access by itself. A new Partner must also use the Owner’s one-time code.', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'sans-serif', color: Color(0xFF777174))),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
