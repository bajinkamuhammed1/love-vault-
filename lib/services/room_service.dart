import 'package:supabase_flutter/supabase_flutter.dart';

class RoomService {
  RoomService(this._client);

  final SupabaseClient _client;

  Future<Map<String, dynamic>> createRoom(String displayName) async {
    final result = await _client.rpc(
      'create_room',
      params: {'p_display_name': displayName.trim()},
    );
    return Map<String, dynamic>.from((result as List).single as Map);
  }

  Future<Map<String, dynamic>> joinRoom({
    required String roomCode,
    required String displayName,
  }) async {
    final result = await _client.rpc(
      'join_room',
      params: {
        'p_room_code': roomCode.trim().toUpperCase(),
        'p_display_name': displayName.trim(),
      },
    );
    return Map<String, dynamic>.from((result as List).single as Map);
  }
}
