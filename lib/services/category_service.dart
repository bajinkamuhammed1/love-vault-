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

    final enabledById = <String, bool>{
      for (final row in settings)
        row['category_id'].toString(): row['enabled'] == true,
    };

    return [
      for (final category in categories)
        {
          ...category,
          'enabled': enabledById[category['id'].toString()] ?? true,
        }
    ];
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
