/// 喵聲模式服務
/// 
/// 提供 15 種喵語文字與聲音模式
/// 聲音檔使用 asset path，尚未有真實檔案時顯示友善提示
class MeowSoundModeService {
  static final MeowSoundModeService _instance = MeowSoundModeService._internal();
  factory MeowSoundModeService() => _instance;
  MeowSoundModeService._internal();

  /// 15 種喵語文字
  static const List<String> meowTexts = [
    '~喵喵🐾~喵～喵嗚💕~喵喵🐾~喵~喵嗚💕',
    '~喵～🐾~喵喵~喵嗚💕~喵～~喵喵🐾',
    '~喵嗚💕~喵喵🐾~喵～~喵喵~喵嗚💕',
    '~喵喵~喵喵🐾~喵～💕~喵嗚~喵～',
    '~喵～喵～🐾~喵嗚💕~喵喵~喵嗚~',
    '~喵嗚~喵嗚💕~喵喵🐾~喵～~喵喵',
    '~喵🐾~喵喵💕~喵嗚~喵～~喵喵🐾',
    '~喵喵喵🐾~喵～💕~喵嗚~喵~喵嗚',
    '~喵～~喵嗚🐾~喵喵💕~喵喵~喵～',
    '~喵嗚💕~喵～~喵喵🐾~喵嗚~喵喵',
    '~喵喵🐾~喵嗚~喵～💕~喵喵~喵嗚',
    '~喵～💕~喵喵🐾~喵嗚~喵～~喵喵',
    '~喵嗚🐾~喵喵~喵喵💕~喵～~喵嗚',
    '~喵喵💕~喵～🐾~喵嗚~喵喵~喵～',
    '~喵～喵嗚💕~喵喵🐾~喵~喵喵~喵嗚',
  ];

  /// 15 種聲音模式
  static const List<MeowSoundMode> modes = [
    MeowSoundMode(id: 1,  name: '溫柔短喵',   assetPath: 'assets/sounds/meow_01_gentle.mp3'),
    MeowSoundMode(id: 2,  name: '撒嬌喵喵',   assetPath: 'assets/sounds/meow_02_cute.mp3'),
    MeowSoundMode(id: 3,  name: '小奶貓喵',   assetPath: 'assets/sounds/meow_03_kitten.mp3'),
    MeowSoundMode(id: 4,  name: '好奇喵',     assetPath: 'assets/sounds/meow_04_curious.mp3'),
    MeowSoundMode(id: 5,  name: '呼喚喵',     assetPath: 'assets/sounds/meow_05_calling.mp3'),
    MeowSoundMode(id: 6,  name: '開心喵',     assetPath: 'assets/sounds/meow_06_happy.mp3'),
    MeowSoundMode(id: 7,  name: '短促注意喵', assetPath: 'assets/sounds/meow_07_attention.mp3'),
    MeowSoundMode(id: 8,  name: '慢慢喵嗚',   assetPath: 'assets/sounds/meow_08_slow_mew.mp3'),
    MeowSoundMode(id: 9,  name: '雙聲喵喵',   assetPath: 'assets/sounds/meow_09_double.mp3'),
    MeowSoundMode(id: 10, name: '高低起伏喵',  assetPath: 'assets/sounds/meow_10_pitch_mix.mp3'),
    MeowSoundMode(id: 11, name: '呼嚕聲',     assetPath: 'assets/sounds/meow_11_purr.mp3'),
    MeowSoundMode(id: 12, name: '柔和呼嚕+短喵', assetPath: 'assets/sounds/meow_12_purr_meow.mp3'),
    MeowSoundMode(id: 13, name: '逗貓聲',     assetPath: 'assets/sounds/meow_13_teaser.mp3'),
    MeowSoundMode(id: 14, name: '小鳥聲',     assetPath: 'assets/sounds/meow_14_bird.mp3'),
    MeowSoundMode(id: 15, name: '貓聲+逗貓聲混合', assetPath: 'assets/sounds/meow_15_mix_play.mp3'),
  ];

  /// 取得所有模式
  List<MeowSoundMode> getAllModes() => modes;

  /// 依 ID 取得模式
  MeowSoundMode? getModeById(int id) {
    try {
      return modes.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 依索引取得模式
  MeowSoundMode getModeByIndex(int index) {
    return modes[index % modes.length];
  }

  /// 取得對應的喵語文字（依 mode index）
  String getMeowTextByModeIndex(int index) {
    return meowTexts[index % meowTexts.length];
  }

  /// 取得所有喵語文字
  List<String> getAllMeowTexts() => meowTexts;
}

/// 單一喵聲模式
class MeowSoundMode {
  final int id;
  final String name;
  final String assetPath;

  const MeowSoundMode({
    required this.id,
    required this.name,
    required this.assetPath,
  });
}
