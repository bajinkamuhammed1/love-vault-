import 'package:supabase_flutter/supabase_flutter.dart';

class RoomService {
  RoomService(this._client);
  final SupabaseClient _client;

  String normalizeCode(String input) {
    final raw = input.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (raw.length == 8) return '${raw.substring(0,4)}-${raw.substring(4)}';
    return input.trim().toUpperCase();
  }

  Future<Map<String,dynamic>?> currentRoom() async {
    final user=_client.auth.currentUser;if(user==null)return null;
    final m=await _client.from('room_members').select('room_id').eq('user_id',user.id).maybeSingle();
    if(m==null)return null;
    return Map<String,dynamic>.from(await _client.from('rooms').select('id,room_code,is_locked,created_at,relationship_started_on').eq('id',m['room_id']).single());
  }

  Future<Map<String,dynamic>> roomSnapshot(String roomId) async {
    final room=Map<String,dynamic>.from(await _client.from('rooms').select('id,room_code,is_locked,created_at,relationship_started_on').eq('id',roomId).single());
    final members=await _client.from('room_members').select('user_id,joined_at').eq('room_id',roomId).order('joined_at');
    final ids=members.map((e)=>e['user_id'].toString()).toList();
    final profiles=ids.isEmpty ? <dynamic>[] : await _client.from('profiles').select('id,display_name').inFilter('id',ids);
    final names={for(final p in profiles)p['id'].toString():p['display_name'].toString()};
    room['members']=[for(final m in members){...m,'display_name':names[m['user_id'].toString()]??'Player'}];
    return room;
  }

  Future<Map<String,dynamic>> myProfile() async {
    final id=_client.auth.currentUser!.id;
    return Map<String,dynamic>.from(await _client.from('profiles').select('id,display_name').eq('id',id).single());
  }
  Future<void> updateDisplayName(String name) async {
    await _client.from('profiles').update({'display_name':name.trim(),'updated_at':DateTime.now().toUtc().toIso8601String()}).eq('id',_client.auth.currentUser!.id);
  }

  Future<Map<String,dynamic>> createRoom(String displayName) async {
    final result=await _client.rpc('create_room',params:{'p_display_name':displayName.trim()});
    return Map<String,dynamic>.from((result as List).single as Map);
  }
  Future<void> setRelationshipStartDate(String roomId, DateTime date) async {\n    await _client.rpc('set_relationship_start_date',params:{'p_room_id':roomId,'p_started_on':'${date.year.toString().padLeft(4,'0')}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}'});\n  }\n  Future<Map<String,dynamic>> joinRoom({required String roomCode,required String displayName}) async {
    final result=await _client.rpc('join_room',params:{'p_room_code':normalizeCode(roomCode),'p_display_name':displayName.trim()});
    return Map<String,dynamic>.from((result as List).single as Map);
  }
}