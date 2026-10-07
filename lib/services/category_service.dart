import 'package:supabase_flutter/supabase_flutter.dart';

class CategoryService {
  CategoryService(this._client);
  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> questionBank() async {
    final categories = await _client.from('play_categories').select('id,name,emoji,enabled,sort_order').order('sort_order');
    final questions = await _client.from('play_questions').select('id,category_id,question,choices,sort_order').order('sort_order');
    return [
      for (final raw in categories)
        {
          ...Map<String, dynamic>.from(raw),
          'questions': questions.where((q) => q['category_id'].toString() == raw['id'].toString()).map((q) => Map<String, dynamic>.from(q)).toList(),
        },
    ];
  }

  Future<void> setEnabled(String categoryId, bool enabled) async {
    await _client.from('play_categories').update({'enabled': enabled}).eq('id', categoryId);
  }

  Future<void> updateQuestion({required String questionId, required String text, required List<String> choices}) async {
    await _client.from('play_questions').update({
      'question': text.trim(),
      'choices': choices.map((e) => e.trim()).toList(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', questionId);
  }
}
