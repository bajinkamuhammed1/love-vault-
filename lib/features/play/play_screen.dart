import 'dart:async';
import 'dart:math';

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
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _games = [];
  Map<String, dynamic>? _game;
  int _index = 0;
  bool _busy = false;
  String? _error;
  Timer? _poller;

  @override
  void initState() {
    super.initState();
    _play = PlayService(Supabase.instance.client);
    _loadLobby();
    _poller = Timer.periodic(const Duration(seconds: 3), (_) => _refreshGame());
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  Future<void> _loadLobby() async {
    try {
      final values = await Future.wait([_play.categories(), _play.games(widget.roomId)]);
      if (!mounted) return;
      setState(() {
        _categories = values[0];
        _games = values[1];
        _error = null;
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load Play.');
    }
  }

  Future<void> _refreshGame() async {
    final game = _game;
    if (game == null) return;
    try {
      final next = await _play.gameState(game['game_id'].toString());
      if (mounted) setState(() => _game = next);
    } catch (_) {}
  }

  Future<void> _spin() async {
    if (_busy || _categories.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final category = _categories[Random.secure().nextInt(_categories.length)];
      if (mounted) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => _SpinDialog(category: category),
        );
      }
      if (!mounted) return;
      final id = await _play.startGame(widget.roomId, category['id'].toString());
      final game = await _play.gameState(id);
      if (mounted) {
        setState(() {
          _game = game;
          _index = 0;
        });
        await _loadLobby();
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not start this spin.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openGame(String id) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final game = await _play.gameState(id);
      final questions = game['questions'] as List? ?? const [];
      var first = 0;
      for (var i = 0; i < questions.length; i++) {
        final q = questions[i] as Map;
        if (q['my_answer'] == null || q['my_guess'] == null) {
          first = i;
          break;
        }
      }
      if (mounted) setState(() {
        _game = game;
        _index = first;
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not open that game.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _answer(Map<String, dynamic> q, String value) async {
    final game = _game;
    if (game == null || _busy) return;
    setState(() => _busy = true);
    try {
      await _play.saveAnswer(game['game_id'].toString(), q['question_id'].toString(), value);
      final next = await _play.gameState(game['game_id'].toString());
      if (mounted) setState(() => _game = next);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not save your answer.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _guess(Map<String, dynamic> q, String value) async {
    final game = _game;
    if (game == null || _busy) return;
    setState(() => _busy = true);
    try {
      await _play.saveGuess(game['game_id'].toString(), q['question_id'].toString(), value);
      final next = await _play.gameState(game['game_id'].toString());
      if (mounted) setState(() => _game = next);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not save your guess.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _next(int length) {
    if (_index < length - 1) {
      setState(() => _index++);
    } else {
      setState(() {
        _game = null;
        _index = 0;
      });
      _loadLobby();
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = _game;
    if (game == null) return _lobby(context);
    final questions = game['questions'] as List? ?? const [];
    if (questions.isEmpty) return const Center(child: Text('This game has no questions.'));
    if (_index >= questions.length) _index = questions.length - 1;
    if (_index < 0) _index = 0;
    final q = Map<String, dynamic>.from(questions[_index] as Map);
    final category = Map<String, dynamic>.from(game['category'] as Map? ?? {});
    final options = (q['options'] as List? ?? const []).map((e) => e.toString()).toList();
    final partner = game['partner_name']?.toString() ?? 'Partner';
    final answered = q['my_answer'] != null;
    final guessed = q['my_guess'] != null;
    final revealed = q['reveal_ready'] == true;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
      children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${category['emoji'] ?? '💕'} ${category['name'] ?? 'Play'}', style: Theme.of(context).textTheme.headlineSmall),
            Text('Question ${_index + 1} of ${questions.length}'),
          ])),
          TextButton(
            onPressed: _busy ? null : () {
              setState(() => _game = null);
              _loadLobby();
            },
            child: const Text('Games'),
          ),
        ]),
        const SizedBox(height: 14),
        LinearProgressIndicator(value: (_index + 1) / questions.length, borderRadius: BorderRadius.circular(12)),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFFF0F3), Color(0xFFFFF8EE)]),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(children: [
            Text(q['text']?.toString() ?? '', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            Text(
              !answered
                  ? 'Choose your answer'
                  : !guessed
                      ? 'Now guess what $partner chose'
                      : revealed
                          ? 'Answer revealed'
                          : 'Your guess is locked in',
              textAlign: TextAlign.center,
            ),
          ]),
        ),
        const SizedBox(height: 18),
        if (!answered)
          for (final option in options)
            _Choice(text: option, onTap: _busy ? null : () => _answer(q, option))
        else if (!guessed)
          for (final option in options)
            _Choice(text: option, onTap: _busy ? null : () => _guess(q, option))
        else ...[
          if (revealed)
            _RevealCard(correct: q['correct'] == true, partner: partner, answer: q['partner_answer']?.toString() ?? '')
          else
            _WaitingCard(partner: partner, guess: q['my_guess']?.toString() ?? ''),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _busy ? null : () => _next(questions.length),
            icon: Icon(_index == questions.length - 1 ? Icons.grid_view_rounded : Icons.arrow_forward),
            label: Text(_index == questions.length - 1 ? 'Back to games' : 'Next question'),
          ),
        ],
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
      ],
    );
  }

  Widget _lobby(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 110),
      children: [
        const Center(child: Text('💕', style: TextStyle(fontSize: 52))),
        const SizedBox(height: 10),
        Text('Spin for us', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        const Text('The spinner picks an enabled category. The questions stay private in Settings until a game starts.', textAlign: TextAlign.center),
        const SizedBox(height: 24),
        Center(
          child: SizedBox(
            width: 190,
            height: 190,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFEDF1),
                border: Border.all(color: const Color(0xFFE9365A), width: 3),
              ),
              child: const Center(child: Icon(Icons.casino_outlined, size: 66, color: Color(0xFFE9365A))),
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _busy || _categories.isEmpty ? null : _spin,
          icon: const Icon(Icons.favorite),
          label: Text(_busy ? 'Spinning…' : 'Spin & start 7 questions'),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        const SizedBox(height: 30),
        Row(children: [
          Text('Our games', style: Theme.of(context).textTheme.titleLarge),
          const Spacer(),
          IconButton(onPressed: _busy ? null : _loadLobby, icon: const Icon(Icons.refresh)),
        ]),
        const SizedBox(height: 8),
        if (_games.isEmpty)
          const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('No spins yet. Start one whenever you want.', textAlign: TextAlign.center))),
        for (final game in _games)
          Builder(builder: (context) {
            final category = Map<String, dynamic>.from(game['play_categories'] as Map? ?? {});
            final complete = game['status'] == 'complete';
            return Card(
              child: ListTile(
                leading: CircleAvatar(child: Text(category['emoji']?.toString() ?? '💕')),
                title: Text(category['name']?.toString() ?? 'Question game'),
                subtitle: Text(complete ? 'Completed • open results' : 'In progress • answer anytime'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _busy ? null : () => _openGame(game['id'].toString()),
              ),
            );
          }),
      ],
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({required this.text, required this.onTap});
  final String text;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE9E4E5)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(children: [
          const Icon(Icons.circle_outlined, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ]),
      ),
    ),
  );
}

class _RevealCard extends StatelessWidget {
  const _RevealCard({required this.correct, required this.partner, required this.answer});
  final bool correct;
  final String partner;
  final String answer;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: correct ? const Color(0xFFF1FAF3) : const Color(0xFFFFF1F4),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(children: [
      Icon(correct ? Icons.check_circle : Icons.favorite_outline, size: 46, color: correct ? Colors.green : const Color(0xFFE9365A)),
      const SizedBox(height: 8),
      Text(correct ? 'You got it 💕' : 'Not quite 💗', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 6),
      Text(
        correct ? 'You knew $partner — the answer was “$answer”.' : '$partner chose “$answer”. Now you know them a little better.',
        textAlign: TextAlign.center,
      ),
    ]),
  );
}

class _WaitingCard extends StatelessWidget {
  const _WaitingCard({required this.partner, required this.guess});
  final String partner;
  final String guess;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(color: const Color(0xFFFFF7F9), borderRadius: BorderRadius.circular(24)),
    child: Column(children: [
      const Icon(Icons.lock_clock_outlined, color: Color(0xFFE9365A), size: 38),
      const SizedBox(height: 8),
      Text('Guess saved: “$guess”', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 6),
      Text('$partner has not answered this one yet. You do not have to wait — continue and the reveal will be here later.', textAlign: TextAlign.center),
    ]),
  );
}

class _SpinDialog extends StatefulWidget {
  const _SpinDialog({required this.category});
  final Map<String, dynamic> category;
  @override
  State<_SpinDialog> createState() => _SpinDialogState();
}

class _SpinDialogState extends State<_SpinDialog> {
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) Navigator.pop(context);
    });
  }
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => AlertDialog(
    content: Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(width: 68, height: 68, child: CircularProgressIndicator(strokeWidth: 7)),
        const SizedBox(height: 22),
        Text('Spinning…', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Text('${widget.category['emoji'] ?? '💕'} ${widget.category['name']}', textAlign: TextAlign.center),
      ]),
    ),
  );
}
