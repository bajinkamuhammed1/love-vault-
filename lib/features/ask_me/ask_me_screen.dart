import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/ask_me_service.dart';

class AskMeScreen extends StatefulWidget {
  const AskMeScreen({super.key, required this.roomId});
  final String roomId;
  @override
  State<AskMeScreen> createState() => _AskMeScreenState();
}

class _AskMeScreenState extends State<AskMeScreen> {
  late final AskMeService _service;
  late Future<List<Map<String, dynamic>>> _future;
  int _filter = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _service = AskMeService(Supabase.instance.client);
    _future = _service.questions(widget.roomId);
  }

  Future<void> _reload() async {
    final next = _service.questions(widget.roomId);
    setState(() => _future = next);
    await next;
  }

  Future<void> _compose() async {
    final partner = await _service.partner(widget.roomId);
    if (!mounted) return;
    if (partner == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your partner needs to connect first.')));
      return;
    }
    final created = await showModalBottomSheet<bool>(
      context: context, isScrollControlled: true, useSafeArea: true,
      builder: (_) => _ComposeSheet(service: _service, vaultId: widget.roomId, partner: partner),
    );
    if (created == true) await _reload();
  }

  Future<void> _answer(Map<String, dynamic> item) async {
    final value = await showModalBottomSheet<String>(
      context: context, isScrollControlled: true, useSafeArea: true,
      builder: (_) => _AnswerSheet(item: item),
    );
    if (value == null || value.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await _service.answer(item['id'].toString(), value);
      await _reload();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not send the answer.')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : _compose, icon: const Icon(Icons.add_rounded), label: const Text('Ask'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: FilledButton.icon(onPressed: _reload, icon: const Icon(Icons.refresh), label: const Text('Try again')));
          final all = snapshot.data ?? const <Map<String, dynamic>>[];
          final incoming = all.where((q) => q['recipient_id'] == _service.userId && q['answer'] == null).toList();
          final sent = all.where((q) => q['sender_id'] == _service.userId).toList();
          final answered = all.where((q) => q['answer'] != null).toList();
          final shown = _filter == 0 ? incoming : (_filter == 1 ? sent : answered);
          return RefreshIndicator(
            onRefresh: _reload,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 28, 22, 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Ask', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 6),
                    Text(incoming.isEmpty ? 'A private place for questions worth answering.' : '${incoming.length} waiting for you.', style: Theme.of(context).textTheme.bodyLarge),
                  ]),
                )),
                SliverToBoxAdapter(child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal, padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Row(children: [
                    _Tab(label: 'For you', count: incoming.length, selected: _filter == 0, onTap: () => setState(() => _filter = 0)),
                    _Tab(label: 'Sent', count: sent.length, selected: _filter == 1, onTap: () => setState(() => _filter = 1)),
                    _Tab(label: 'Answered', count: answered.length, selected: _filter == 2, onTap: () => setState(() => _filter = 2)),
                  ]),
                )),
                if (shown.isEmpty)
                  SliverFillRemaining(hasScrollBody: false, child: Center(child: Padding(
                    padding: const EdgeInsets.all(36),
                    child: Text(_filter == 0 ? 'Nothing waiting for you right now.' : _filter == 1 ? 'You have not sent a question yet.' : 'Answered questions will collect here.', textAlign: TextAlign.center),
                  )))
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                    sliver: SliverList.builder(
                      itemCount: shown.length,
                      itemBuilder: (context, i) {
                        final q = shown[i];
                        final mine = q['sender_id'] == _service.userId;
                        final canAnswer = q['recipient_id'] == _service.userId && q['answer'] == null;
                        final answer = q['answer']?.toString();
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Icon(mine ? Icons.north_east_rounded : Icons.south_west_rounded, size: 18),
                                const SizedBox(width: 8),
                                Expanded(child: Text(mine ? 'You asked' : 'For you', style: Theme.of(context).textTheme.labelLarge)),
                                Text(answer == null ? 'Waiting' : 'Answered', style: Theme.of(context).textTheme.labelSmall),
                              ]),
                              const SizedBox(height: 14),
                              Text(q['question']?.toString() ?? '', style: Theme.of(context).textTheme.titleMedium),
                              if (q['question_type'] == 'multiple_choice') ...[
                                const SizedBox(height: 6), Text('Multiple choice', style: Theme.of(context).textTheme.bodySmall),
                              ],
                              if (answer != null) ...[
                                const Divider(height: 28),
                                Text(mine ? 'Partner’s answer' : 'Your answer', style: Theme.of(context).textTheme.labelLarge),
                                const SizedBox(height: 6), Text(answer),
                              ] else if (canAnswer) ...[
                                const SizedBox(height: 16),
                                FilledButton(onPressed: _busy ? null : () => _answer(q), child: const Text('Answer privately')),
                              ] else ...[
                                const SizedBox(height: 12), const Text('Waiting for an answer…'),
                              ],
                            ]),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.count, required this.selected, required this.onTap});
  final String label; final int count; final bool selected; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(selected: selected, onSelected: (_) => onTap(), label: Text('$label  $count')),
  );
}

class _ComposeSheet extends StatefulWidget {
  const _ComposeSheet({required this.service, required this.vaultId, required this.partner});
  final AskMeService service; final String vaultId; final Map<String, dynamic> partner;
  @override State<_ComposeSheet> createState() => _ComposeSheetState();
}

class _ComposeSheetState extends State<_ComposeSheet> {
  final _question = TextEditingController();
  final _options = List.generate(4, (_) => TextEditingController());
  bool _multiple = false, _busy = false;
  @override void dispose() { _question.dispose(); for (final c in _options) { c.dispose(); } super.dispose(); }

  Future<void> _send() async {
    final question = _question.text.trim();
    final choices = _options.map((c) => c.text.trim()).where((v) => v.isNotEmpty).toList();
    if (question.isEmpty || (_multiple && choices.length < 2)) return;
    setState(() => _busy = true);
    try {
      await widget.service.create(
        vaultId: widget.vaultId, recipientId: widget.partner['user_id'].toString(), question: question,
        questionType: _multiple ? 'multiple_choice' : 'text', choices: _multiple ? choices : null,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not send the question.')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.partner['display_name']?.toString().trim();
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 18, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Ask ${name == null || name.isEmpty ? 'your partner' : name}', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6), const Text('Only the two of you can see this question.'), const SizedBox(height: 18),
        TextField(controller: _question, maxLength: 1000, minLines: 2, maxLines: 5, decoration: const InputDecoration(labelText: 'Question', border: OutlineInputBorder())),
        SegmentedButton<bool>(
          segments: const [ButtonSegment(value: false, label: Text('Written')), ButtonSegment(value: true, label: Text('Choice'))],
          selected: {_multiple}, onSelectionChanged: _busy ? null : (v) => setState(() => _multiple = v.first),
        ),
        if (_multiple) ...[
          const SizedBox(height: 14),
          for (var i = 0; i < _options.length; i++)
            Padding(padding: const EdgeInsets.only(bottom: 8), child: TextField(
              controller: _options[i], maxLength: 200,
              decoration: InputDecoration(labelText: 'Option ${i + 1}', border: const OutlineInputBorder()),
            )),
        ],
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: _busy ? null : _send, icon: const Icon(Icons.send_outlined), label: Text(_busy ? 'Sending…' : 'Send question')),
      ])),
    );
  }
}

class _AnswerSheet extends StatefulWidget {
  const _AnswerSheet({required this.item});
  final Map<String, dynamic> item;
  @override State<_AnswerSheet> createState() => _AnswerSheetState();
}

class _AnswerSheetState extends State<_AnswerSheet> {
  final _text = TextEditingController();
  String? _selected;
  @override void dispose() { _text.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final multiple = widget.item['question_type'] == 'multiple_choice';
    final options = (widget.item['choices'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 18, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Your answer'), const SizedBox(height: 8),
        Text(widget.item['question']?.toString() ?? '', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 18),
        if (multiple)
          for (final option in options)
            RadioListTile<String>(value: option, groupValue: _selected, onChanged: (v) => setState(() => _selected = v), title: Text(option), contentPadding: EdgeInsets.zero)
        else
          TextField(controller: _text, minLines: 3, maxLines: 7, maxLength: 2000, decoration: const InputDecoration(labelText: 'Write your answer', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        FilledButton(onPressed: () {
          final value = multiple ? _selected : _text.text.trim();
          if (value != null && value.isNotEmpty) Navigator.pop(context, value);
        }, child: const Text('Send answer')),
      ])),
    );
  }
}
