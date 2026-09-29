import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/play_service.dart';

class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key, required this.roomId});
  final String roomId;

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  late final PlayService _play;
  final _answer = TextEditingController();
  Map<String, dynamic>? _state;
  bool _busy = false;
  String? _error;
  Timer? _poller;

  @override
  void initState() {
    super.initState();
    _play = PlayService(Supabase.instance.client);
  }

  @override
  void dispose() {
    _poller?.cancel();
    _answer.dispose();
    super.dispose();
  }

  Future<void> _spin() async {
    setState(() { _busy = true; _error = null; });
    try {
      final started = await _play.start(widget.roomId);
      final id = started['session_id'].toString();
      final state = await _play.state(id);
      if (!mounted) return;
      setState(() => _state = state);
      _startPolling(id);
    } catch (e) {
      if (mounted) setState(() => _error = _friendly(e.toString()));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _startPolling(String id) {
    _poller?.cancel();
    _poller = Timer.periodic(const Duration(seconds: 2), (_) => _refresh(id));
  }

  Future<void> _refresh(String id) async {
    try {
      final state = await _play.state(id);
      if (!mounted) return;
      setState(() => _state = state);
      if (state['status'] == 'revealed' || state['status'] == 'complete') {
        _poller?.cancel();
      }
    } catch (_) {}
  }

  Future<void> _submit() async {
    final state = _state;
    if (state == null || _answer.text.trim().isEmpty) return;
    setState(() { _busy = true; _error = null; });
    try {
      await _play.submitAnswer(state['session_id'].toString(), _answer.text);
      await _refresh(state['session_id'].toString());
    } catch (e) {
      if (mounted) setState(() => _error = _friendly(e.toString()));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _friendly(String raw) {
    if (raw.contains('partner has not joined')) return 'Your partner needs to join the room first.';
    if (raw.contains('No enabled')) return 'Turn on at least one question category in Settings.';
    return 'Could not continue the game. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    if (state == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.casino_outlined, size: 72),
              const SizedBox(height: 16),
              Text('Spin for a question', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text('The spinner chooses from the categories enabled for your room.'),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _busy ? null : _spin,
                icon: const Icon(Icons.casino),
                label: const Text('Spin'),
              ),
            ],
          ),
        ),
      );
    }

    final revealed = state['status'] == 'revealed' || state['status'] == 'complete';
    final answered = state['my_answer'] != null;
    final answers = (state['answers'] as List?) ?? const [];

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: Text(
            '${state['category_emoji'] ?? ''} ${state['category_name'] ?? ''}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              state['question_text']?.toString() ?? '',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (!answered) ...[
          TextField(
            controller: _answer,
            minLines: 3,
            maxLines: 6,
            maxLength: 2000,
            decoration: const InputDecoration(
              labelText: 'Your answer',
              border: OutlineInputBorder(),
            ),
          ),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: const Text('Lock In Answer'),
          ),
        ] else if (!revealed) ...[
          const Center(child: Icon(Icons.lock_clock_outlined, size: 44)),
          const SizedBox(height: 10),
          Text(
            'Answer locked in. Waiting for your partner… (${state['answer_count']}/2)',
            textAlign: TextAlign.center,
          ),
        ] else ...[
          Text('Answer reveal', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          for (final item in answers)
            Card(
              child: ListTile(
                title: Text((item as Map)['display_name']?.toString() ?? 'Player'),
                subtitle: Text(item['answer']?.toString() ?? ''),
              ),
            ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _busy ? null : () {
              _answer.clear();
              setState(() => _state = null);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Spin Again'),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
      ],
    );
  }
}
