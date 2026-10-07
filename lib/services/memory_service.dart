import 'package:supabase_flutter/supabase_flutter.dart';

class MemoryService {
  MemoryService(this._client);
  final SupabaseClient _client;
  String get userId => _client.auth.currentUser!.id;

  Future<List<Map<String,dynamic>>> list(String roomId) async {
    final rows=await _client.from('memories').select('id, author_id, title, body, memory_date, created_at, is_featured, location_label').eq('vault_id',roomId).order('memory_date',ascending:false).order('created_at',ascending:false);
    return [for(final r in rows) Map<String,dynamic>.from(r)];
  }
  Future<void> create({required String roomId,required String title,required String body,required DateTime date,String? locationLabel,bool featured=false}) async {
    await _client.from('memories').insert({'vault_id':roomId,'author_id':userId,'title':title.trim(),'body':body.trim(),'memory_date':_date(date),'location_label':_nullable(locationLabel),'is_featured':featured});
  }
  Future<void> update({required String id,required String title,required String body,required DateTime date,String? locationLabel,bool featured=false}) async {
    await _client.from('memories').update({'title':title.trim(),'body':body.trim(),'memory_date':_date(date),'location_label':_nullable(locationLabel),'is_featured':featured}).eq('id',id).eq('author_id',userId);
  }
  Future<void> delete(String id) async {
    await _client.from('memories').delete().eq('id',id).eq('author_id',userId);
  }
  String? _nullable(String? value){final v=value?.trim()??'';return v.isEmpty?null:v;}
  String _date(DateTime d)=>'${d.year.toString().padLeft(4,'0')}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
}
