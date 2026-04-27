class Cat {
  final String id;
  final String name;
  final String? imageUrl;
  final CatGender gender;
  final CatAgeStage ageStage;
  final String breed;

  Cat({
    required this.id,
    required this.name,
    this.imageUrl,
    this.gender = CatGender.female,
    this.ageStage = CatAgeStage.kitten,
    this.breed = '',
  });

  // 示範數據
  static List<Cat> getDemoCats() {
    return [
      Cat(
        id: '1',
        name: '奶茶',
        gender: CatGender.female,
        ageStage: CatAgeStage.kitten,
        breed: '英國短毛貓',
      ),
    ];
  }
}

enum CatGender { male, female }

enum CatAgeStage {
  kitten,      // 幼貓 0-6月
  junior,      // 少年貓 7月-2歲
  adult,       // 成貓 3-7歲
  senior,      // 老年貓 8-10歲
  geriatric,   // 高齡貓 11+歲
}

extension CatAgeStageExtension on CatAgeStage {
  String get label {
    switch (this) {
      case CatAgeStage.kitten:
        return '幼貓';
      case CatAgeStage.junior:
        return '少年貓';
      case CatAgeStage.adult:
        return '成貓';
      case CatAgeStage.senior:
        return '老年貓';
      case CatAgeStage.geriatric:
        return '高齡貓';
    }
  }

  String get ageRange {
    switch (this) {
      case CatAgeStage.kitten:
        return '0-6個月';
      case CatAgeStage.junior:
        return '7個月~2歲';
      case CatAgeStage.adult:
        return '3-7歲';
      case CatAgeStage.senior:
        return '8-10歲';
      case CatAgeStage.geriatric:
        return '11+歲';
    }
  }
}
