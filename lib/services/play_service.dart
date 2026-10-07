import 'package:supabase_flutter/supabase_flutter.dart';

class PlayService {
  PlayService(this._client);
  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> categories() async {
    final rows = await _client.from('play_categories').select('id,name,emoji,sort_order').eq('enabled', true).order('sort_order');
    return rows.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> games(String vaultId) async {
    final rows = await _client.from('play_games').select('id,status,created_at,category_id,play_categories(name,emoji)').eq('vault_id', vaultId).order('created_at', ascending: false).limit(30);
    return rows.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<String> startGame(String vaultId, String categoryId) async {
    final id = await _client.rpc('start_play_game', params: {'p_vault_id': vaultId, 'p_category_id': categoryId});
    return id.toString();
  }

  Future<Map<String, dynamic>> gameState(String gameId) async {
    final value = await _client.rpc('get_play_game_state', params: {'p_game_id': gameId});
    return Map<String, dynamic>.from(value as Map);
  }

  Future<void> saveAnswer(String gameId, String questionId, String answer) async {
    await _client.rpc('save_play_answer', params: {'p_game_id': gameId, 'p_question_id': questionId, 'p_answer': answer});
  }

  Future<void> saveGuess(String gameId, String questionId, String guess) async {
    await _client.rpc('save_play_guess', params: {'p_game_id': gameId, 'p_question_id': questionId, 'p_guess': guess});
  }
}
