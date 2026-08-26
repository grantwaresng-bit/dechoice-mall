import 'item_model.dart';

class CategoryModel {
  final String id;
  final String segmentId;
  final String name;
  final List<ItemModel> items;

  CategoryModel({
    required this.id,
    required this.segmentId,
    required this.name,
    required this.items,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    var rawItems = map['items'] as List<dynamic>? ?? [];
    List<ItemModel> parsedItems = rawItems
        .map((itemMap) => ItemModel.fromMap(itemMap as Map<String, dynamic>))
        .toList();

    return CategoryModel(
      id: map['id'] ?? '',
      segmentId: map['segment_id'] ?? '',
      name: map['name'] ?? '',
      items: parsedItems,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'segment_id': segmentId,
      'name': name,
      'items': items.map((item) => item.toMap()).toList(),
    };
  }
}