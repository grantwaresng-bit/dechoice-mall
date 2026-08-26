class SegmentModel {
  final String id;
  final String name;
  final String imageUrl;
  final int displayOrder;

  SegmentModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.displayOrder,
  });

  factory SegmentModel.fromMap(Map<String, dynamic> map) {
    return SegmentModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      imageUrl: map['image_url'] ?? '',
      displayOrder: map['display_order'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'image_url': imageUrl,
      'display_order': displayOrder,
    };
  }
}