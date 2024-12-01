import 'dart:ui';

class MarkingModel {
  final String? markingId;
  final String pageId;
  final double yPosition;
  final List<Offset?> points;
  final String name;
  final double score;

  MarkingModel({
    required this.markingId,
    required this.pageId,
    required this.yPosition,
    required this.points,
    required this.name,
    required this.score,
  });

  // from map
  factory MarkingModel.fromMap(Map<String, dynamic> map) {
    final String? markingId = map['markingId'] as String?;
    // Assuming 'pageId' and 'name' are non-nullable Strings in your map
    final String pageId = map['pageId'] as String;
    final String name = map['name'] as String;

    // Assuming 'yPosition' and 'score' are non-nullable doubles in your map
    // Use 'toDouble()' to ensure the value is a double, which is necessary if the value could be an int
    final double yPosition = (map['yPosition'] as num).toDouble();
    final double score = (map['score'] as num).toDouble();

    // Assuming 'points' is a list of maps that can be converted to 'Offset' objects
    // This part needs special attention to correctly convert each point from the map
    final List<Offset?> points =
        (map['points'] as List<dynamic>).map<Offset?>((dynamic item) {
      if (item == null) {
        return null;
      }
      final Map<String, dynamic> pointMap = item as Map<String, dynamic>;
      final double dx = (pointMap['dx'] as num).toDouble();
      final double dy = (pointMap['dy'] as num).toDouble();
      return Offset(dx, dy);
    }).toList();

    return MarkingModel(
      markingId: markingId,
      pageId: pageId,
      yPosition: yPosition,
      points: points,
      name: name,
      score: score,
    );
  }

  // to map
  Map<String, dynamic> toMap() {
    return {
      'markingId': markingId,
      'pageId': pageId,
      'yPosition': yPosition,
      'points': points
          .map((point) =>
              point != null ? {'dx': point.dx, 'dy': point.dy} : null)
          .toList(),
      'name': name,
      'score': score,
    };
  }

  // copy with
  MarkingModel copyWith({
    String? markingId,
    String? pageId,
    double? yPosition,
    List<Offset?>? points,
    String? name,
    double? score,
  }) {
    return MarkingModel(
      markingId: markingId ?? this.markingId,
      pageId: pageId ?? this.pageId,
      yPosition: yPosition ?? this.yPosition,
      points: points ?? this.points,
      name: name ?? this.name,
      score: score ?? this.score,
    );
  }
}
