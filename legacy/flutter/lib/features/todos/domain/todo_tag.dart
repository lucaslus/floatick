import 'package:characters/characters.dart';

class TodoTag {
  const TodoTag({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.createdAt,
  });

  static const int maxNameLength = 10;

  final String id;
  final String name;
  final int colorValue;
  final DateTime createdAt;

  TodoTag copyWith({String? name, int? colorValue}) {
    return TodoTag(
      id: id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt,
    );
  }

  factory TodoTag.fromJson(Map<String, dynamic> json) {
    final name = _requiredString(json, 'name');
    if (name.characters.length > maxNameLength) {
      throw const FormatException(
        'Tag field "name" must contain at most 10 characters.',
      );
    }

    final colorValue = json['colorValue'];
    if (colorValue is! int ||
        colorValue.isNegative ||
        colorValue > 0xFFFFFFFF) {
      throw const FormatException(
        'Tag field "colorValue" must be a 32-bit ARGB integer.',
      );
    }

    return TodoTag(
      id: _requiredString(json, 'id'),
      name: name,
      colorValue: colorValue,
      createdAt: _requiredDate(json, 'createdAt'),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'colorValue': colorValue,
      'createdAt': createdAt.toUtc().toIso8601String(),
    };
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Tag field "$key" must be a non-empty string.');
    }
    return value.trim();
  }

  static DateTime _requiredDate(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String) {
      throw FormatException('Tag field "$key" must be an ISO-8601 string.');
    }
    return DateTime.parse(value);
  }

  @override
  bool operator ==(Object other) {
    return other is TodoTag &&
        other.id == id &&
        other.name == name &&
        other.colorValue == colorValue &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(id, name, colorValue, createdAt);
}
