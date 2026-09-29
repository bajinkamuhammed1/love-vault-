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

  Future<void> _addQuestion(Map<String,dynamic> category) async {
    final q=TextEditingController(); final opts=List.generate(4,(_)=>TextEditingController());
    final ok=await showDialog<bool>(context:context,builder:(context)=>AlertDialog(
      title:Text('Add to ${category['name']}'),
      content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:q,maxLength:300,decoration:const InputDecoration(labelText:'Your question')),
        const Text('Add 2–4 choices. Both partners will see this question.'),
        for(int i=0;i<4;i++)TextField(controller:opts[i],decoration:InputDecoration(labelText:'Option ${i+1}')),
      ])),
      actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('Add question'))],
    ));
    if(ok==true){
      final choices=opts.map((e)=>e.text.trim()).where((e)=>e.isNotEmpty).toList();
      if(q.text.trim().length<3||choices.length<2){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Add a question and at least 2 options.')));return;}
      try{await _categories.addQuestion(roomId:widget.roomId,categoryId:category['id'] as int,text:q.text,options:choices);_reload();if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Question added for both of you.')));}
      catch(_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Could not add that question.')));}
    }
    q.dispose();for(final x in opts)x.dispose();
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
                    ListTile(leading:const Icon(Icons.add_circle_outline),title:const Text('Add your own question'),subtitle:const Text('Both partners can add questions'),onTap:()=>_addQuestion(category)),
                    for (final q in (category['questions'] as List?) ?? const [])
                      ListTile(leading: Icon((q as Map)['custom']==true?Icons.favorite_outline:Icons.question_mark,size:18),title:Text(q['text'].toString()),subtitle:Text(((q['options'] as List?)??const[]).join(' • '))),
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
