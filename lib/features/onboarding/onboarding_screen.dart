import 'package:flutter/material.dart';
import '../../services/room_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.roomService,
    required this.onConnected,
  });

  final RoomService roomService;
  final VoidCallback onConnected;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _name = TextEditingController();
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    if (_name.text.trim().isEmpty || _code.text.trim().isEmpty) {
      setState(() => _error = 'Enter your name and the pairing code.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await widget.roomService.redeemPairingCode(
        _code.text,
        _name.text,
      );
      widget.onConnected();
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().toLowerCase();
      setState(() {
        _error = message.contains('expired')
            ? 'That code is invalid or expired. Ask for a new one.'
            : 'Could not connect. Check the code and try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(26),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: CircleAvatar(
                      radius: 34,
                      child: Icon(Icons.favorite),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Connect to Love Vault',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter the one-time pairing code created by the Love Vault owner.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _name,
                    maxLength: 50,
                    decoration: const InputDecoration(
                      labelText: 'Your display name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _code,
                    autocorrect: false,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Pairing code',
                      prefixIcon: Icon(Icons.key_outlined),
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _busy ? null : _join,
                    icon: const Icon(Icons.link),
                    label: Text(_busy ? 'Connecting…' : 'Connect'),
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
