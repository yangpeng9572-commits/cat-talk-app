import 'dart:convert';

/// 使用者日記 Entry Model
/// 
/// 用於儲存使用者自行記錄的貓咪生活日記（第一階段：純文字）
class UserDiaryEntry {
  final String id;
  final String catId;
  final String catName;
  final DateTime date;
  final String content;
  final DateTime createdAt;

  UserDiaryEntry({
    required this.id,
    required this.catId,
    required this.catName,
    required this.date,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'catId': catId,
      'catName': catName,
      'date': date.toIso8601String(),
      'content': content,
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
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
