import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/category_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.roomId});
  final String roomId;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final CategoryService _categories;
  late Future<List<Map<String, dynamic>>> _future;
  final Set<int> _saving = {};

  @override
  void initState() {
    super.initState();
    _categories = CategoryService(Supabase.instance.client);
    _future = _categories.listForRoom(widget.roomId);
  }

  void _reload() => setState(() {
        _future = _categories.listForRoom(widget.roomId);
      });

  Future<void> _toggle(Map<String, dynamic> category, bool enabled) async {
    final id = category['id'] as int;
    setState(() => _saving.add(id));
    try {
      await _categories.setEnabled(
        roomId: widget.roomId,
        categoryId: id,
        enabled: enabled,
      );
      _reload();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update that category.')),
      );
    } finally {
      if (mounted) setState(() => _saving.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: FilledButton.icon(
                onPressed: _reload,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            );
          }

          final categories = snapshot.data ?? const [];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Question Categories',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 6),
              const Text(
                'Choose which categories can appear when either partner spins. These settings are shared by your private room.',
              ),
              const SizedBox(height: 16),
              for (final category in categories)
                Card(
                  child: SwitchListTile.adaptive(
                    secondary: Text(
                      category['emoji']?.toString() ?? '💬',
                      style: const TextStyle(fontSize: 26),
                    ),
                    title: Text(category['name']?.toString() ?? 'Category'),
                    subtitle: _saving.contains(category['id'])
                        ? const Text('Saving…')
                        : Text('${(category['questions'] as List?)?.length ?? 0} questions'),
                    value: category['enabled'] == true,
                    onChanged: _saving.contains(category['id'])
                        ? null
                        : (value) => _toggle(category, value),
                  ),
                ),
              for (final category in categories)
                ExpansionTile(
                  leading: Text(category['emoji']?.toString() ?? '💬', style: const TextStyle(fontSize: 22)),
                  title: Text('${category['name']} question library'),
                  subtitle: Text('${(category['questions'] as List?)?.length ?? 0} available'),
                  children: [
                    for (final q in (category['questions'] as List?) ?? const [])
                      ListTile(leading: const Icon(Icons.question_mark, size: 18), title: Text(q.toString())),
                  ],
                ),
              if (categories.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No active categories are available.',
                      textAlign: TextAlign.center),
                ),
            ],
          );
        },
      ),
    );
  }
}
