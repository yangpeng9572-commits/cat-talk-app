class Cat {
  final String id;
  final String name;
  final String? avatarPath;
  final String gender;  // 'male' or 'female'
  final String ageStage;  // 'kitten', 'junior', 'adult', 'senior', 'geriatric'
  final String breed;
  final double age;  // 年齡（歲）
  final DateTime createdAt;

  // Birthday fields
  final int? birthMonth;
  final int? birthDay;
  final int? birthYear;
  final String birthdayType; // 'exact' | 'monthDayOnly' | 'adoptionDay' | 'unknown'

  Cat({
    required this.id,
    required this.name,
    this.avatarPath,
    this.gender = 'female',
    this.ageStage = 'kitten',
    this.breed = '',
    this.age = 0,
    DateTime? createdAt,
    this.birthMonth,
    this.birthDay,
    this.birthYear,
    this.birthdayType = 'unknown',
  }) : createdAt = createdAt ?? DateTime.now();

  /// 從 JSON 建立
  factory Cat.fromJson(Map<String, dynamic> json) {
    // Safe handling of birthdayType - convert invalid values to 'unknown'
    String birthdayType = 'unknown';
    if (json['birthdayType'] != null) {
      final bt = json['birthdayType'] as String;
      if (bt == 'exact' || bt == 'monthDayOnly' || bt == 'adoptionDay' || bt == 'unknown') {
        birthdayType = bt;
      }
    }

    return Cat(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      avatarPath: json['avatarPath'],
      gender: json['gender'] ?? 'female',
      ageStage: json['ageStage'] ?? 'kitten',
      breed: json['breed'] ?? '',
      age: (json['age'] ?? 0).toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      birthMonth: json['birthMonth'] as int?,
      birthDay: json['birthDay'] as int?,
      birthYear: json['birthYear'] as int?,
      birthdayType: birthdayType,
    );
  }

  /// 轉換為 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarPath': avatarPath,
      'gender': gender,
      'ageStage': ageStage,
      'breed': breed,
      'age': age,
      'createdAt': createdAt.toIso8601String(),
      'birthMonth': birthMonth,
      'birthDay': birthDay,
      'birthYear': birthYear,
      'birthdayType': birthdayType,
    };
  }

  /// copyWith
  Cat copyWith({
    String? id,
    String? name,
    String? avatarPath,
    String? gender,
    String? ageStage,
    String? breed,
    double? age,
    DateTime? createdAt,
    int? birthMonth,
    int? birthDay,
    int? birthYear,
    String? birthdayType,
  }) {
    return Cat(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarPath: avatarPath ?? this.avatarPath,
      gender: gender ?? this.gender,
      ageStage: ageStage ?? this.ageStage,
      breed: breed ?? this.breed,
      age: age ?? this.age,
      createdAt: createdAt ?? this.createdAt,
      birthMonth: birthMonth ?? this.birthMonth,
      birthDay: birthDay ?? this.birthDay,
      birthYear: birthYear ?? this.birthYear,
      birthdayType: birthdayType ?? this.birthdayType,
    );
  }

  /// 取得性別標籤
  String get genderLabel => gender == 'male' ? '公' : '母';

  /// 取得年齡階段標籤
  String get ageStageLabel {
    switch (ageStage) {
      case 'kitten':
        return '幼貓 (0-6個月)';
      case 'junior':
        return '少年貓 (7個月~2歲)';
      case 'adult':
        return '成貓 (3-7歲)';
      case 'senior':
        return '老年貓 (8-10歲)';
      case 'geriatric':
        return '高齡貓 (11+歲)';
      default:
        return ageStage;
    }
  }

  /// 示範數據（移除，改用真實資料）
  static List<Cat> getDemoCats() {
    return [];
  }
}
