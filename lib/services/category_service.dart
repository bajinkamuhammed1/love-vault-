import 'package:supabase_flutter/supabase_flutter.dart';

class CategoryService {
  CategoryService(this._client);
  final SupabaseClient _client;

  String get _userId => _client.auth.currentUser!.id;

  Future<List<Map<String, dynamic>>> questionBank() async {
    final categories = await _client.from('play_categories').select('id,name,emoji,enabled,sort_order,is_custom,created_by').order('sort_order');
    final questions = await _client.from('play_questions').select('id,category_id,question,choices,sort_order,question_type,is_custom,created_by').order('sort_order');
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

  Future<String> createCategory({required String name, required String emoji}) async {
    final row = await _client.from('play_categories').insert({
      'name': name.trim(),
      'emoji': emoji.trim().isEmpty ? '💕' : emoji.trim(),
      'enabled': true,
      'sort_order': 10000,
      'is_custom': true,
      'created_by': _userId,
    }).select('id').single();
    return row['id'].toString();
  }

  Future<void> addQuestion({
    required String categoryId,
    required String text,
    required String type,
    required List<String> choices,
    required int sortOrder,
  }) async {
    await _client.from('play_questions').insert({
      'category_id': categoryId,
      'question': text.trim(),
      'question_type': type,
      'choices': type == 'choice' ? choices.map((e) => e.trim()).where((e) => e.isNotEmpty).toList() : <String>[],
      'sort_order': sortOrder,
      'is_custom': true,
      'created_by': _userId,
    });
  }

  Future<void> updateQuestion({required String questionId, required String text, required String type, required List<String> choices}) async {
    await _client.from('play_questions').update({
      'question': text.trim(),
      'question_type': type,
      'choices': type == 'choice' ? choices.map((e) => e.trim()).where((e) => e.isNotEmpty).toList() : <String>[],
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', questionId);
  }

  Future<void> deleteQuestion(String questionId) async {
    await _client.from('play_questions').delete().eq('id', questionId).eq('is_custom', true);
  }

  Future<void> deleteCategory(String categoryId) async {
    await _client.from('play_questions').delete().eq('category_id', categoryId).eq('is_custom', true);
    await _client.from('play_categories').delete().eq('id', categoryId).eq('is_custom', true);
  }
}
