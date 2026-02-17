import 'dart:convert';

class CountryGroup {
  final String id;
  final String name;
  final List<String> countries;
  final String color;
  final DateTime createdAt;
  final DateTime updatedAt;

  CountryGroup({
    required this.id,
    required this.name,
    required this.countries,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CountryGroup.fromJson(Map<String, dynamic> json) {
    return CountryGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      countries: List<String>.from(json['countries'] as List),
      color: json['color'] as String? ?? '#0038A8',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  factory CountryGroup.fromJsonString(String jsonStr) {
    final json = jsonDecode(jsonStr);
    return CountryGroup.fromJson(json);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'countries': countries,
      'color': color,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  CountryGroup copyWith({
    String? id,
    String? name,
    List<String>? countries,
    String? color,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CountryGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      countries: countries ?? this.countries,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // 기본 색상 팔레트
  static const List<String> colorPalette = [
    '#0038A8', // Yonsei Blue
    '#FF6B6B', // Red
    '#4ECDC4', // Teal
    '#45B7D1', // Sky Blue
    '#FFA07A', // Light Salmon
    '#98D8C8', // Mint
    '#F7DC6F', // Yellow
    '#BB8FCE', // Purple
    '#85C1E2', // Light Blue
    '#F8B739', // Orange
  ];
}
