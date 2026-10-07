import 'package:supabase_flutter/supabase_flutter.dart';

class AskMeService {
  AskMeService(this._client);
  final SupabaseClient _client;
  String get userId => _client.auth.currentUser!.id;

  Future<Map<String, dynamic>?> partner(String vaultId) async {
    final rows = await _client.from('vault_members').select('user_id, display_name, avatar_emoji, slot').eq('vault_id', vaultId).order('slot');
    for (final row in rows) {
      if (row['user_id'] != userId) return Map<String, dynamic>.from(row);
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> questions(String vaultId) async {
    final rows = await _client.from('ask_me').select('id, vault_id, sender_id, recipient_id, question, question_type, choices, answer, answered_at, created_at').eq('vault_id', vaultId).order('created_at', ascending: false);
    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  Future<void> create({required String vaultId, required String recipientId, required String question, required String questionType, List<String>? choices}) async {
    await _client.rpc('create_ask_me', params: {
      'p_vault_id': vaultId, 'p_recipient_id': recipientId, 'p_question': question.trim(),
      'p_question_type': questionType, 'p_choices': questionType == 'multiple_choice' ? choices : null,
    });
  }

  Future<void> answer(String questionId, String answer) async {
    await _client.rpc('answer_ask_me', params: {'p_question_id': questionId, 'p_answer': answer.trim()});
  }
}
