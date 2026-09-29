import 'package:supabase_flutter/supabase_flutter.dart';
class CategoryService{
 CategoryService(this._client);final SupabaseClient _client;
 Future<List<Map<String,dynamic>>> listForRoom(String roomId)async{
  final settings=await _client.from('room_category_settings').select('category_id, enabled').eq('room_id',roomId);
  final categories=await _client.from('categories').select('id, name, emoji, active, sort_order').eq('active',true).order('sort_order');
  final questions=await _client.from('questions').select('id, category_id, text, options, room_id, created_by').eq('active',true).or('room_id.is.null,room_id.eq.$roomId');
  final enabled={for(final row in settings)row['category_id'].toString():row['enabled']==true};
  return [for(final category in categories){...category,'enabled':enabled[category['id'].toString()]??true,'questions':questions.where((q)=>q['category_id'].toString()==category['id'].toString()).map((q)=>{...q,'custom':q['room_id']!=null}).toList()}];
 }
 Future<void> addQuestion({required String roomId,required int categoryId,required String text,required List<String> options})async{
  final choices=options.map((e)=>e.trim()).where((e)=>e.isNotEmpty).toList();
  await _client.from('questions').insert({'room_id':roomId,'category_id':categoryId,'created_by':_client.auth.currentUser!.id,'text':text.trim(),'options':choices});
 }
 Future<void> setEnabled({required String roomId,required int categoryId,required bool enabled})async{
  await _client.from('room_category_settings').update({'enabled':enabled}).eq('room_id',roomId).eq('category_id',categoryId);
 }
}