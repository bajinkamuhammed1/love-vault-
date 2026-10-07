import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/category_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.roomId});
  final String roomId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Love Vault', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Text('Shared settings for the two of you.'),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(18),
              leading: const CircleAvatar(child: Icon(Icons.quiz_outlined)),
              title: const Text('Question Bank'),
              subtitle: const Text('200 categories • 1,400 questions • shared editing'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const _QuestionBankScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionBankScreen extends StatefulWidget {
  const _QuestionBankScreen();
  @override
  State<_QuestionBankScreen> createState() => _QuestionBankScreenState();
}

class _QuestionBankScreenState extends State<_QuestionBankScreen> {
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

  Future<void> _toggle(Map<String, dynamic> category, bool enabled) async {
    final id = category['id'].toString();
    setState(() => _saving.add(id));
    try {
      await _service.setEnabled(id, enabled);
      if (!mounted) return;
      setState(_reload);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not update this category.')));
    } finally {
      if (mounted) setState(() => _saving.remove(id));
    }
  }

  Future<void> _editQuestion(Map<String, dynamic> question) async {
    final text = TextEditingController(text: question['question']?.toString());
    final existing = (question['choices'] as List? ?? const []).map((e) => e.toString()).toList();
    final choices = List.generate(4, (i) => TextEditingController(text: i < existing.length ? existing[i] : ''));

    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit question'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: text, maxLength: 300, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'Question')),
              const SizedBox(height: 8),
              for (var i = 0; i < choices.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextField(controller: choices[i], decoration: InputDecoration(labelText: 'Choice ${i + 1}')),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save for both')),
        ],
      ),
    );

    if (save == true) {
      final cleanChoices = choices.map((e) => e.text.trim()).where((e) => e.isNotEmpty).toList();
      if (text.text.trim().length < 3 || cleanChoices.length < 2) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Keep a question and at least 2 choices.')));
      } else {
        try {
          await _service.updateQuestion(questionId: question['id'].toString(), text: text.text, choices: cleanChoices);
          if (mounted) {
            setState(_reload);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Question updated for both of you.')));
          }
        } catch (_) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save that question.')));
        }
      }
    }
    text.dispose();
    for (final controller in choices) {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Question Bank')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) {
            return Center(child: FilledButton.icon(onPressed: () => setState(_reload), icon: const Icon(Icons.refresh), label: const Text('Try again')));
          }
          final all = snapshot.data ?? const [];
          final query = _search.trim().toLowerCase();
          final categories = all.where((category) {
            if (query.isEmpty) return true;
            if (category['name'].toString().toLowerCase().contains(query)) return true;
            return (category['questions'] as List? ?? const []).any((q) => (q as Map)['question'].toString().toLowerCase().contains(query));
          }).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
            children: [
              Text('Our Question Bank', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 6),
              const Text('These questions feed the Play spinner. They stay here in Settings, not on the spin screen. Either of you can edit a question and both of you see the change.'),
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) => setState(() => _search = value),
                decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search 200 categories', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              for (final category in categories)
                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ExpansionTile(
                    leading: Text(category['emoji']?.toString() ?? '💕', style: const TextStyle(fontSize: 24)),
                    title: Text(category['name']?.toString() ?? 'Category'),
                    subtitle: Text('${(category['questions'] as List? ?? const []).length} questions'),
                    trailing: Switch.adaptive(
                      value: category['enabled'] == true,
                      onChanged: _saving.contains(category['id'].toString()) ? null : (value) => _toggle(category, value),
                    ),
                    children: [
                      for (final raw in category['questions'] as List? ?? const [])
                        Builder(builder: (context) {
                          final q = Map<String, dynamic>.from(raw as Map);
                          return ListTile(
                            leading: CircleAvatar(radius: 15, child: Text(q['sort_order'].toString())),
                            title: Text(q['question'].toString()),
                            subtitle: Text((q['choices'] as List? ?? const []).join(' • ')),
                            trailing: const Icon(Icons.edit_outlined),
                            onTap: () => _editQuestion(q),
                          );
                        }),
                    ],
                  ),
                ),
              if (categories.isEmpty) const Padding(padding: EdgeInsets.all(32), child: Text('No matching categories.', textAlign: TextAlign.center)),
            ],
          );
        },
      ),
    );
  }
}
