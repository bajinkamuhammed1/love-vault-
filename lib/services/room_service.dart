import 'package:supabase_flutter/supabase_flutter.dart';

class RoomService {
  RoomService(this._client);
  final SupabaseClient _client;

  String get userId => _client.auth.currentUser!.id;

  Future<Map<String,dynamic>?> currentRoom() async {
    final membership=await _client.from('vault_members').select('vault_id').eq('user_id',userId).maybeSingle();
    if(membership==null)return null;
    return roomSnapshot(membership['vault_id'].toString());
  }

  Future<Map<String,dynamic>> roomSnapshot(String vaultId) async {
    final vault=Map<String,dynamic>.from(await _client.from('vault').select('id,name,relationship_start_date,created_at').eq('id',vaultId).single());
    final members=await _client.from('vault_members').select('user_id,slot,display_name,joined_at').eq('vault_id',vaultId).order('slot');
    return {
      'id': vault['id'],
      'room_code': '',
      'is_locked': true,
      'created_at': vault['created_at'],
      'relationship_started_on': vault['relationship_start_date'],
      'members': [for(final m in members) Map<String,dynamic>.from(m)],
    };
  }

  Future<Map<String,dynamic>> myProfile() async {
    return Map<String,dynamic>.from(await _client.from('vault_members').select('user_id,display_name,slot').eq('user_id',userId).single());
  }

  Future<void> updateDisplayName(String name) async {
    await _client.from('vault_members').update({'display_name':name.trim()}).eq('user_id',userId);
  }

  Future<Map<String,dynamic>> joinVault(String displayName) async {
    final vaultId=await _client.rpc('join_love_vault',params:{'p_display_name':displayName.trim()});
    return roomSnapshot(vaultId.toString());
  }
}
