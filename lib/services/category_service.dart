import 'package:supabase_flutter/supabase_flutter.dart';

class CategoryService {
  CategoryService(this._client);
  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> listForRoom(String roomId) async {
    final settings = await _client
        .from('room_category_settings')
        .select('category_id, enabled')
        .eq('room_id', roomId);

    final categories = await _client
        .from('categories')
        .select('id, name, emoji, active, sort_order')
        .eq('active', true)
        .order('sort_order');

    final questions = await _client.from('questions').select('category_id, text, options').eq('active', true);
    final custom = await _client.from('room_questions').select('id, category_id, text, options, created_by').eq('room_id', roomId).eq('active', true);
    final enabledById = <String, bool>{
      for (final row in settings)
        row['category_id'].toString(): row['enabled'] == true,
    };

    return [
      for (final category in categories)
        {
          ...category,
          'enabled': enabledById[category['id'].toString()] ?? true,
          'questions': questions.where((q) => q['category_id'].toString() == category['id'].toString()).map((q) => {'text':q['text'],'options':q['options'],'custom':false}).toList()
            + custom.where((q) => q['category_id'].toString() == category['id'].toString()).map((q) => {'id':q['id'],'text':q['text'],'options':q['options'],'custom':true,'created_by':q['created_by']}).toList(),
        }
    ];
  }

  Future<void> addQuestion({required String roomId,required int categoryId,required String text,required List<String> options}) async {
    await _client.from('room_questions').insert({'room_id':roomId,'category_id':categoryId,'created_by':_client.auth.currentUser!.id,'text':text.trim(),'options':options.map((e)=>e.trim()).where((e)=>e.isNotEmpty).toList()});
  }

  Future<void> setEnabled({
    required String roomId,
    required int categoryId,
    required bool enabled,
  }) async {
    await _client
        .from('room_category_settings')
        .update({'enabled': enabled})
        .eq('room_id', roomId)
        .eq('category_id', categoryId);
  }
}
