import 'dart:convert';

/// 已儲存的喵聲 Model
/// 
/// 用於儲存使用者保留的「喵一下」常用喵聲
class SavedMeowSound {
  final String id;
  final String catId;
  final String catName;
  final int modeId;
  final String modeName;
  final String meowText;
  final String assetPath;
  final String? note;
  final DateTime createdAt;

  SavedMeowSound({
    required this.id,
    required this.catId,
    required this.catName,
    required this.modeId,
    required this.modeName,
    required this.meowText,
    required this.assetPath,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'catId': catId,
      'catName': catName,
      'modeId': modeId,
      'modeName': modeName,
      'meowText': meowText,
      'assetPath': assetPath,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SavedMeowSound.fromJson(Map<String, dynamic> json) {
    return SavedMeowSound(
      id: json['id'] as String,
      catId: json['catId'] as String,
      catName: json['catName'] as String,
      modeId: json['modeId'] as int,
      modeName: json['modeName'] as String,
      meowText: json['meowText'] as String,
      assetPath: json['assetPath'] as String,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
