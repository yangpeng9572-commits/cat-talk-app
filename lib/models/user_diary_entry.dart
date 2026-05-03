import 'dart:convert';

/// 使用者日記 Entry Model
///
/// 用於儲存使用者自行記錄的貓咪生活日記
/// - 第一階段（v1）：純文字
/// - 第二階段（P3-4）：加入照片
class UserDiaryEntry {
  final String id;
  final String catId;
  final String catName;
  final DateTime date;
  final String content;
  final String? photoPath; // P3-4: 照片路徑（可為 null）
  final List<String> tags; // P3-4 Phase 2: 標籤
  final DateTime createdAt;

  UserDiaryEntry({
    required this.id,
    required this.catId,
    required this.catName,
    required this.date,
    required this.content,
    this.photoPath, // P3-4: 照片路徑（可為 null）
    this.tags = const [], // P3-4 Phase 2: 標籤（預設空）
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'catId': catId,
      'catName': catName,
      'date': date.toIso8601String(),
      'content': content,
      'photoPath': photoPath, // P3-4: 照片路徑
      'tags': tags, // P3-4 Phase 2: 標籤
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserDiaryEntry.fromJson(Map<String, dynamic> json) {
    return UserDiaryEntry(
      id: json['id'] as String,
      catId: json['catId'] as String,
      catName: json['catName'] as String,
      date: DateTime.parse(json['date'] as String),
      content: json['content'] as String,
      photoPath: json['photoPath'] as String?, // P3-4: 照片路徑
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [], // P3-4 Phase 2: 標籤
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
