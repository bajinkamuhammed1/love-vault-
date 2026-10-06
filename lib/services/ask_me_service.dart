import 'package:supabase_flutter/supabase_flutter.dart';

class AskMeService {
  AskMeService(this._client);
  final SupabaseClient _client;

  String get userId => _client.auth.currentUser!.id;

  Future<Map<String, dynamic>?> partner(String roomId) async {
    final rows = await _client.from('vault_members').select('user_id, display_name').eq('vault_id', roomId);
    for (final row in rows) {
      if (row['user_id'] != userId) {
        return {'id': row['user_id'], 'display_name': row['display_name']};
      }
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> questions(String roomId) async {
    final rows = await _client
        .from('ask_me_questions')
        .select('id, asker_id, target_id, question_text, answer_type, options, created_at')
        .eq('room_id', roomId)
        .order('created_at', ascending: false);
    final answers = await _client.from('ask_me_answers').select('question_id, user_id, answer_text, created_at');
    final byQuestion = {for (final a in answers) a['question_id'].toString(): a};
    return [for (final q in rows) {...q, 'answer': byQuestion[q['id'].toString()]}];
  }

  Future<void> create({
    required String roomId,
    required String targetId,
    required String text,
    required String answerType,
    List<String>? options,
  }) async {
    await _client.from('ask_me_questions').insert({
      'room_id': roomId,
      'asker_id': userId,
      'target_id': targetId,
      'question_text': text.trim(),
      'answer_type': answerType,
      'options': answerType == 'multiple_choice' ? options : null,
    });
  }

  Future<void> answer(String questionId, String answer) async {
    await _client.from('ask_me_answers').insert({
      'question_id': questionId,
      'user_id': userId,
      'answer_text': answer.trim(),
    });
  }
}
