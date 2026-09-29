import 'package:supabase_flutter/supabase_flutter.dart';

class RoomService {
  RoomService(this._client);

  final SupabaseClient _client;

  Future<Map<String, dynamic>?> currentRoom() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final membership = await _client
        .from('room_members')
        .select('room_id')
        .eq('user_id', user.id)
        .maybeSingle();

    if (membership == null) return null;

    final room = await _client
        .from('rooms')
        .select('id, room_code, is_locked, created_at')
        .eq('id', membership['room_id'])
        .single();

    return Map<String, dynamic>.from(room);
  }

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
