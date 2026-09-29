import 'package:supabase_flutter/supabase_flutter.dart';

class PlayService {
  PlayService(this._client);
  final SupabaseClient _client;

  Future<Map<String, dynamic>> start(String roomId) async {
    final result = await _client.rpc(
      'start_play_session',
      params: {'p_room_id': roomId, 'p_guess_enabled': false},
    );
    return Map<String, dynamic>.from((result as List).single as Map);
  }

  Future<void> submitAnswer(String sessionId, String answer) async {
    await _client.rpc(
      'submit_play_answer',
      params: {'p_session_id': sessionId, 'p_answer': answer.trim()},
    );
  }

  Future<Map<String, dynamic>> state(String sessionId) async {
    final result = await _client.rpc(
      'get_play_state',
      params: {'p_session_id': sessionId},
    );
    return Map<String, dynamic>.from(result as Map);
  }
}
