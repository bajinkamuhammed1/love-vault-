import 'package:supabase_flutter/supabase_flutter.dart';

class SurpriseService {
  SurpriseService(this._client);
  final SupabaseClient _client;
  String get userId => _client.auth.currentUser!.id;

  Future<Map<String,dynamic>?> partner(String roomId) async {
    final members=await _client.from('vault_members').select('user_id, display_name').eq('vault_id',roomId);
    for(final m in members){
      if(m['user_id']!=userId){
        return {'id':m['user_id'],'display_name':m['display_name']};
      }
    }
    return null;
  }

  Future<List<Map<String,dynamic>>> list(String roomId) async {
    final rows=await _client.rpc('list_surprises',params:{'p_room_id':roomId});
    return [for(final r in rows) Map<String,dynamic>.from(r as Map)];
  }

  Future<void> create({required String roomId,required String recipientId,required String title,required String body,DateTime? revealAt}) async {
    await _client.from('surprises').insert({
      'room_id':roomId,'sender_id':userId,'recipient_id':recipientId,
      'title':title.trim(),'body':body.trim(),'reveal_at':revealAt?.toUtc().toIso8601String(),
    });
  }

  Future<void> markOpened(String id) async {
    await _client.from('surprises').update({'opened_at':DateTime.now().toUtc().toIso8601String()}).eq('id',id).eq('recipient_id',userId);
  }
}
