import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/segment_model.dart';
import '../models/category_model.dart';

class SupabaseService {
  final _supabase = Supabase.instance.client;

  // 1. Fetch all segments for the Home Screen
  Future<List<SegmentModel>> getSegments() async {
    final response = await _supabase
        .from('segments')
        .select()
        .order('display_order', ascending: true);

    return (response as List<dynamic>)
        .map((map) => SegmentModel.fromMap(map as Map<String, dynamic>))
        .toList();
  }

  // 2. Fetch categories and their related items for a specific segment
  // Note: We use a join here to fetch items linked to these categories
  Future<List<CategoryModel>> getCategoriesWithItems(String segmentId) async {
    final response = await _supabase
        .from('categories')
        .select('id, segment_id, name, items(*)')
        .eq('segment_id', segmentId);

    return (response as List<dynamic>)
        .map((map) => CategoryModel.fromMap(map as Map<String, dynamic>))
        .toList();
  }

  // 3. Fetch special offers for a specific segment (includes segment-specific + general banners)
  Future<List<Map<String, dynamic>>> getSpecialOffers(String segmentId) async {
    final response = await _supabase
        .from('special_offers')
        .select()
        .or('segment_id.eq.$segmentId,segment_id.is.null')
        .eq('is_active', true)
        .order('display_order', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  // 4. Fetch available delivery locations for checkout
  Future<List<Map<String, dynamic>>> getDeliveryLocations() async {
    try {
      final response = await _supabase
          .from('delivery_locations')
          .select()
          .order('location_name', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching delivery locations: $e');
      return [];
    }
  }
}