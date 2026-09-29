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
  bool _joining = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Enter the name your partner should see.');
      return;
    }
    await _run(() => widget.roomService.createRoom(_name.text));
  }

  Future<void> _join() async {
    if (_name.text.trim().isEmpty || _code.text.trim().isEmpty) {
      setState(() => _error = 'Enter your name and the room code.');
      return;
    }
    await _run(() => widget.roomService.joinRoom(
          roomCode: _code.text,
          displayName: _name.text,
        ));
  }

  Future<void> _run(Future<Map<String, dynamic>> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      widget.onConnected();
    } catch (e) {
      if (mounted) setState(() => _error = _friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('Room not found')) return 'That room code was not found.';
    if (raw.contains('already full')) return 'That room already has two people.';
    if (raw.contains('already belongs')) return 'This device is already connected to a room.';
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.favorite, size: 64),
                  const SizedBox(height: 18),
                  Text(
                    'Love Vault',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'A private space for two.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _name,
                    maxLength: 50,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Your display name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Create'), icon: Icon(Icons.add)),
                      ButtonSegment(value: true, label: Text('Join'), icon: Icon(Icons.login)),
                    ],
                    selected: {_joining},
                    onSelectionChanged: _busy
                        ? null
                        : (value) => setState(() {
                              _joining = value.first;
                              _error = null;
                            }),
                  ),
                  if (_joining) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _code,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Room code',
                        hintText: 'AB12CD34 (dash optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _busy ? null : (_joining ? _join : _create),
                    icon: _busy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(_joining ? Icons.login : Icons.favorite_outline),
                    label: Text(_joining ? 'Join Room' : 'Create Room'),
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
