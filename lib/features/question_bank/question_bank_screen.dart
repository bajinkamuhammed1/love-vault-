import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/category_service.dart';

class QuestionBankScreen extends StatefulWidget {
  const QuestionBankScreen({super.key});
  @override
  State<QuestionBankScreen> createState() => _QuestionBankScreenState();
}

class _QuestionBankScreenState extends State<QuestionBankScreen> {
  late final CategoryService _service;
  late Future<List<Map<String, dynamic>>> _future;
  String _search = '';
  final Set<String> _saving = {};

  @override
  void initState() {
    super.initState();
    _service = CategoryService(Supabase.instance.client);
    _reload();
  }

  void _reload() => _future = _service.questionBank();
  void _refresh() => setState(_reload);

  Future<void> _toggle(Map<String, dynamic> category, bool enabled) async {
    final id = category['id'].toString();
    setState(() => _saving.add(id));
    try {
      await _service.setEnabled(id, enabled);
      _refresh();
    } catch (_) {
      _message('Could not update this category.');
    } finally {
      if (mounted) setState(() => _saving.remove(id));
    }
  }

  void _message(String text) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _addCategory() async {
    final name = TextEditingController();
    final emoji = TextEditingController(text: '💕');
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create our category'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, autofocus: true, maxLength: 60, decoration: const InputDecoration(labelText: 'Category name', hintText: 'Our inside jokes')),
          TextField(controller: emoji, maxLength: 4, decoration: const InputDecoration(labelText: 'Emoji', hintText: '💕')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create')),
        ],
      ),
    );
    if (save == true && name.text.trim().length >= 2) {
      try {
        final id = await _service.createCategory(name: name.text, emoji: emoji.text);
        _refresh();
        _message('Category created. Add your first question 💕');
        if (mounted) await _questionEditor(categoryId: id, sortOrder: 1);
      } catch (_) {
        _message('Could not create that category.');
      }
    }
    name.dispose();
    emoji.dispose();
  }

  Future<void> _questionEditor({required String categoryId, required int sortOrder, Map<String, dynamic>? question}) async {
    final text = TextEditingController(text: question?['question']?.toString() ?? '');
    var type = question?['question_type']?.toString() ?? 'choice';
    final existing = (question?['choices'] as List? ?? const []).map((e) => e.toString()).toList();
    final options = <TextEditingController>[
      for (final value in existing) TextEditingController(text: value),
      if (existing.isEmpty) ...[TextEditingController(), TextEditingController(), TextEditingController(), TextEditingController()],
    ];

    final result = await showDialog<({String type, String text, List<String> choices})>(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setDialogState) {
        return AlertDialog(
          title: Text(question == null ? 'Add a question' : 'Edit question'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: const Color(0xFFFFF0F3), borderRadius: BorderRadius.circular(18)),
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'choice', icon: Icon(Icons.list_alt), label: Text('Choices')),
                      ButtonSegment(value: 'written', icon: Icon(Icons.edit_note), label: Text('Written')),
                    ],
                    selected: {type},
                    onSelectionChanged: (value) => setDialogState(() => type = value.first),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  type == 'choice'
                      ? 'Your partner chooses from the options, then you can guess each other’s answer.'
                      : 'You both write privately. When both replies are in, you reveal them and mark your partner’s response.',
                ),
                const SizedBox(height: 16),
                TextField(controller: text, maxLength: 300, minLines: 2, maxLines: 5, decoration: const InputDecoration(labelText: 'Question', border: OutlineInputBorder())),
                if (type == 'choice') ...[
                  const SizedBox(height: 8),
                  for (var i = 0; i < options.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        Expanded(child: TextField(controller: options[i], decoration: InputDecoration(labelText: 'Option ${i + 1}', border: const OutlineInputBorder()))),
                        if (options.length > 2)
                          IconButton(
                            tooltip: 'Remove option',
                            onPressed: () => setDialogState(() {
                              final removed = options.removeAt(i);
                              removed.dispose();
                            }),
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                      ]),
                    ),
                  OutlinedButton.icon(
                    onPressed: () => setDialogState(() => options.add(TextEditingController())),
                    icon: const Icon(Icons.add),
                    label: const Text('Add another option'),
                  ),
                ],
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final clean = options.map((e) => e.text.trim()).where((e) => e.isNotEmpty).toList();
                if (text.text.trim().length < 3 || (type == 'choice' && clean.length < 2)) return;
                Navigator.pop(context, (type: type, text: text.text.trim(), choices: clean));
              },
              child: const Text('Save for both'),
            ),
          ],
        );
      }),
    );

    if (result != null) {
      try {
        if (question == null) {
          await _service.addQuestion(categoryId: categoryId, text: result.text, type: result.type, choices: result.choices, sortOrder: sortOrder);
        } else {
          await _service.updateQuestion(questionId: question['id'].toString(), text: result.text, type: result.type, choices: result.choices);
        }
        _refresh();
        _message(question == null ? 'Question added to your shared bank.' : 'Question updated for both of you.');
      } catch (_) {
        _message('Could not save that question.');
      }
    }
    text.dispose();
    for (final controller in options) {
      controller.dispose();
    }
  }

  Future<void> _deleteQuestion(Map<String, dynamic> q) async {
    if (q['is_custom'] != true) return;
    final yes = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Delete this question?'),
      content: const Text('It will disappear from future spins. Games already started keep their selected questions.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
      ],
    ));
    if (yes == true) {
      try { await _service.deleteQuestion(q['id'].toString()); _refresh(); } catch (_) { _message('Could not delete that question.'); }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFFFBFC),
    appBar: AppBar(title: const Text('Question Bank')),
    floatingActionButton: FloatingActionButton.extended(onPressed: _addCategory, icon: const Icon(Icons.add), label: const Text('New category')),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: FilledButton.icon(onPressed: _refresh, icon: const Icon(Icons.refresh), label: const Text('Try again')));
        final all = snapshot.data ?? const [];
        final query = _search.trim().toLowerCase();
        final categories = all.where((c) => query.isEmpty || c['name'].toString().toLowerCase().contains(query) || (c['questions'] as List? ?? const []).any((q) => (q as Map)['question'].toString().toLowerCase().contains(query))).toList();
        final enabled = all.where((c) => c['enabled'] == true).length;
        final totalQuestions = all.fold<int>(0, (sum, c) => sum + (c['questions'] as List? ?? const []).length);

        return ListView(padding: const EdgeInsets.fromLTRB(18, 18, 18, 110), children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFFE8EE), Color(0xFFFFF5E9)]),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('💕', style: TextStyle(fontSize: 34)),
              const SizedBox(height: 8),
              Text('Our questions', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 6),
              const Text('A private library for the two of you. Turn topics on or off for Spin, edit prompts together, or create your own.'),
              const SizedBox(height: 16),
              Wrap(spacing: 8, runSpacing: 8, children: [
                Chip(label: Text('$enabled active categories')),
                Chip(label: Text('$totalQuestions questions')),
                const Chip(avatar: Icon(Icons.lock_outline, size: 17), label: Text('Shared only')),
              ]),
            ]),
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: (value) => setState(() => _search = value),
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search categories or questions', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(18)))),
          ),
          const SizedBox(height: 16),
          for (final category in categories)
            Card(
              margin: const EdgeInsets.only(bottom: 11),
              clipBehavior: Clip.antiAlias,
              child: ExpansionTile(
                leading: CircleAvatar(backgroundColor: const Color(0xFFFFEDF1), child: Text(category['emoji']?.toString() ?? '💕')),
                title: Text(category['name']?.toString() ?? 'Category', style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${(category['questions'] as List? ?? const []).length} questions${category['is_custom'] == true ? ' • Yours' : ''}'),
                trailing: Switch.adaptive(value: category['enabled'] == true, onChanged: _saving.contains(category['id'].toString()) ? null : (value) => _toggle(category, value)),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: Row(children: [
                      Expanded(child: OutlinedButton.icon(
                        onPressed: () => _questionEditor(categoryId: category['id'].toString(), sortOrder: (category['questions'] as List? ?? const []).length + 1),
                        icon: const Icon(Icons.add),
                        label: const Text('Add question'),
                      )),
                    ]),
                  ),
                  for (final raw in category['questions'] as List? ?? const [])
                    Builder(builder: (context) {
                      final q = Map<String, dynamic>.from(raw as Map);
                      final written = q['question_type'] == 'written';
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                        leading: CircleAvatar(radius: 16, child: Icon(written ? Icons.edit_note : Icons.checklist, size: 18)),
                        title: Text(q['question'].toString()),
                        subtitle: Text(written ? 'Written answer • partner marks it' : '${(q['choices'] as List? ?? const []).length} choices'),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(onPressed: () => _questionEditor(categoryId: category['id'].toString(), sortOrder: q['sort_order'] as int? ?? 1, question: q), icon: const Icon(Icons.edit_outlined)),
                          if (q['is_custom'] == true) IconButton(onPressed: () => _deleteQuestion(q), icon: const Icon(Icons.delete_outline)),
                        ]),
                      );
                    }),
                ],
              ),
            ),
          if (categories.isEmpty) const Padding(padding: EdgeInsets.all(36), child: Text('No matching questions.', textAlign: TextAlign.center)),
        ]);
      },
    ),
  );
}
