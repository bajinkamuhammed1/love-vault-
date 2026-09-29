import 'package:supabase_flutter/supabase_flutter.dart';

class PlayService {
  PlayService(this._client);
  final SupabaseClient _client;

  Future<List<Map<String,dynamic>>> categories(String roomId) async {
    final r=await _client.rpc('list_play_categories',params:{'p_room_id':roomId});
    return (r as List).map((e)=>Map<String,dynamic>.from(e as Map)).toList();
  }
  Future<int?> nextCategory(String roomId) async {
    final r=await _client.rpc('next_play_category',params:{'p_room_id':roomId});
    return r==null?null:(r as num).toInt();
  }
  Future<String> startCategory(String roomId,int categoryId) async =>
      (await _client.rpc('start_category_game',params:{'p_room_id':roomId,'p_category_id':categoryId})).toString();
  Future<String?> currentGame(String roomId) async {
    final r=await _client.rpc('get_current_category_game',params:{'p_room_id':roomId});
    return r?.toString();
  }
  Future<Map<String,dynamic>> gameState(String gameId) async =>
      Map<String,dynamic>.from(await _client.rpc('get_category_game_state',params:{'p_game_id':gameId}) as Map);
  Future<void> saveAnswer(String gameId,int questionId,String answer) async =>
      _client.rpc('save_category_answer',params:{'p_game_id':gameId,'p_question_id':questionId,'p_answer':answer});
  Future<void> saveGuess(String gameId,int questionId,String guess) async =>
      _client.rpc('save_category_guess',params:{'p_game_id':gameId,'p_question_id':questionId,'p_guess':guess});
  Future<void> quit(String gameId) async => _client.rpc('quit_category_game',params:{'p_game_id':gameId});
}
