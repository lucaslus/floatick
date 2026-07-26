import 'package:characters/characters.dart';

class StickyBoardWindowFrame {
  const StickyBoardWindowFrame({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;
  final double top;
  final double width;
  final double height;

  factory StickyBoardWindowFrame.fromJson(Map<String, dynamic> json) {
    return StickyBoardWindowFrame(
      left: _requiredFiniteDouble(json, 'left'),
      top: _requiredFiniteDouble(json, 'top'),
      width: _requiredPositiveDouble(json, 'width'),
      height: _requiredPositiveDouble(json, 'height'),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'left': left,
      'top': top,
      'width': width,
      'height': height,
    };
  }

  static double _requiredFiniteDouble(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! num || !value.toDouble().isFinite) {
      throw FormatException(
        'Sticky board window frame "$key" must be a finite number.',
      );
    }
    return value.toDouble();
  }

  static double _requiredPositiveDouble(Map<String, dynamic> json, String key) {
    final value = _requiredFiniteDouble(json, key);
    if (value <= 0) {
      throw FormatException(
        'Sticky board window frame "$key" must be positive.',
      );
    }
    return value;
  }

  @override
  bool operator ==(Object other) {
    return other is StickyBoardWindowFrame &&
        other.left == left &&
        other.top == top &&
        other.width == width &&
        other.height == height;
  }

  @override
  int get hashCode => Object.hash(left, top, width, height);
}

class StickyBoard {
  const StickyBoard({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.createdAt,
    this.isPinned = false,
    this.windowFrame,
  });

  static const int maxNameLength = 32;

  final String id;
  final String name;
  final int colorValue;
  final DateTime createdAt;
  final bool isPinned;
  final StickyBoardWindowFrame? windowFrame;

  StickyBoard copyWith({
    String? name,
    int? colorValue,
    bool? isPinned,
    StickyBoardWindowFrame? windowFrame,
  }) {
    return StickyBoard(
      id: id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt,
      isPinned: isPinned ?? this.isPinned,
      windowFrame: windowFrame ?? this.windowFrame,
    );
  }

  factory StickyBoard.fromJson(Map<String, dynamic> json) {
    final name = _requiredString(json, 'name');
    if (name.characters.length > maxNameLength) {
      throw const FormatException(
        'Sticky board field "name" must contain at most 32 characters.',
      );
    }

    final colorValue = json['colorValue'];
    if (colorValue is! int ||
        colorValue.isNegative ||
        colorValue > 0xFFFFFFFF) {
      throw const FormatException(
        'Sticky board field "colorValue" must be a 32-bit ARGB integer.',
      );
    }

    final isPinned = json['isPinned'];
    if (isPinned is! bool) {
      throw const FormatException(
        'Sticky board field "isPinned" must be a Boolean.',
      );
    }

    final rawWindowFrame = json['windowFrame'];
    if (rawWindowFrame != null && rawWindowFrame is! Map<dynamic, dynamic>) {
      throw const FormatException(
        'Sticky board field "windowFrame" must be a JSON object.',
      );
    }

    return StickyBoard(
      id: _requiredString(json, 'id'),
      name: name,
      colorValue: colorValue,
      createdAt: _requiredDate(json, 'createdAt'),
      isPinned: isPinned,
      windowFrame: rawWindowFrame == null
          ? null
          : StickyBoardWindowFrame.fromJson(
              Map<String, dynamic>.from(rawWindowFrame),
            ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'colorValue': colorValue,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'isPinned': isPinned,
      if (windowFrame != null) 'windowFrame': windowFrame!.toJson(),
    };
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException(
        'Sticky board field "$key" must be a non-empty string.',
      );
    }
    return value.trim();
  }

  static DateTime _requiredDate(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String) {
      throw FormatException(
        'Sticky board field "$key" must be an ISO-8601 string.',
      );
    }
    return DateTime.parse(value);
  }

  @override
  bool operator ==(Object other) {
    return other is StickyBoard &&
        other.id == id &&
        other.name == name &&
        other.colorValue == colorValue &&
        other.createdAt == createdAt &&
        other.isPinned == isPinned &&
        other.windowFrame == windowFrame;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, colorValue, createdAt, isPinned, windowFrame);
  }
}
