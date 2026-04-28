import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/translation_result.dart';

/// Share card service
/// Generates cute cat diary share images + Threads captions
class ShareCardService {
  static final ShareCardService _instance = ShareCardService._internal();
  factory ShareCardService() => _instance;
  ShareCardService._internal();

  // Emotion sentences mapping
  static const Map<EmotionType, String> _emotionSentences = {
    EmotionType.affectionate: 'Today she wanted to cuddle all day',
    EmotionType.hungry: 'Today she kept reminding about food',
    EmotionType.playful: 'Today she really wanted to play',
    EmotionType.attention: 'Today she wanted attention',
    EmotionType.anxious: 'Today she seemed a bit worried',
    EmotionType.angry: 'Today she did not want to be disturbed',
    EmotionType.uncomfortable: 'Today she felt a bit uncomfortable',
    EmotionType.greeting: 'Today she was greeting me',
    EmotionType.other: 'Today she had her own little mood',
  };

  static const String _noEmotionSentence = 'Today she is special';

  // Threads intro templates
  static const Map<EmotionType, List<String>> _threadsIntros = {
    EmotionType.affectionate: [
      'I used this app to listen to my cat today...',
      'My cat has been extra clingy lately',
      'I tried AI to translate my cats meows...',
    ],
    EmotionType.hungry: [
      'My cat has been meowing non-stop',
      'This AI translation is so accurate...',
      'My cat is meowing again, and it said:',
    ],
    EmotionType.playful: [
      'She has been so loud today',
      'My cat has gone crazy, keeps meowing',
      'I tested this AI to translate cat meows...',
    ],
    EmotionType.attention: [
      'My cat keeps demanding attention',
      'The cat is meowing again, and the translation says...',
      'My cat has been meowing, AI says:',
    ],
    EmotionType.anxious: [
      'My cat has been acting weird today',
      'The AI translation says she feels anxious...',
      'I heard her meow today, and AI said:',
    ],
    EmotionType.angry: [
      'My cat is in a bad mood today',
      'My cat is angry, translation says...',
      'The AI cat translator says she is not happy...',
    ],
    EmotionType.uncomfortable: [
      'My cat does not feel well today',
      'AI translation says she feels uncomfortable...',
      'The cat meow translation result worries me...',
    ],
    EmotionType.greeting: [
      'My cat greeted me today',
      'AI translation says she was saying hello...',
      'The result from this app is so cute...',
    ],
    EmotionType.other: [
      'My cat has new tricks again',
      'I tested this AI translation...',
      'The cat meow translation results are in...',
    ],
  };

  static const List<String> _noEmotionIntros = [
    'I tried this AI translation app today...',
    'My cat has not made a sound yet, just recording',
    'First time using this app to translate cat meows...',
  ];

  // Threads ending questions
  static const Map<EmotionType, List<String>> _threadsQuestions = {
    EmotionType.affectionate: [
      'Do your cats say things like this too?',
      'Does anyone else find AI translation accurate?',
      'Does your cat cuddle like this?',
    ],
    EmotionType.hungry: [
      'Do you have this at home?',
      'The pressure is real, do your cats do this?',
      'How do you deal with hungry attacks?',
    ],
    EmotionType.playful: [
      'Is every cat like this?',
      'Does your cat meow like this too?',
      'Does anyone else find this funny?',
    ],
    EmotionType.attention: [
      'Does your cat demand attention like this?',
      'How do you respond to her?',
      'She just wants attention right?',
    ],
    EmotionType.anxious: [
      'Have you dealt with cat anxiety before?',
      'How do you calm her?',
      'What do you do when cats feel anxious?',
    ],
    EmotionType.angry: [
      'Does your cat do this too?',
      'Is letting her alone the right thing?',
      'How do you calm an angry cat?',
    ],
    EmotionType.uncomfortable: [
      'Have you had a similar situation?',
      'Would you take her to the vet?',
      'How do you monitor when cats are uncomfortable?',
    ],
    EmotionType.greeting: [
      'Does your cat greet you like this?',
      'Do you always respond to her?',
      'What do you do when cats greet you?',
    ],
    EmotionType.other: [
      'What does your cat say?',
      'Has anyone tried this app too?',
      'Do you think the translation is accurate?',
    ],
  };

  static const List<String> _noEmotionQuestions = [
    'What does your cat say?',
    'Has anyone tried this app too?',
    'Do you think AI translation is accurate?',
  ];

  // Fixed Hashtags
  static const List<String> _fixedHashtags = [
    '#CatTalk',
    '#CatDiary',
    '#MyCatIsCute',
  ];

  // Random Hashtags
  static const List<String> _randomHashtags = [
    '#CatLife',
    '#CatOwner',
    '#CatLover',
    '#MyCat',
    '#CatMoments',
    '#Meow',
    '#CatSlave',
  ];

  /// Get emotion sentence
  String _getEmotionSentence(EmotionType? emotion) {
    if (emotion == null) return _noEmotionSentence;
    return _emotionSentences[emotion] ?? _noEmotionSentence;
  }

  /// Generate share card image (Uint8List)
  /// Size: 1080 x 1080 (square, suitable for IG/Threads)
  Future<Uint8List?> generateShareCardImage({
    required String catName,
    required String diaryText,
    required EmotionType? emotion,
    required String topSpeech,
    required int bondScore,
    required GlobalKey repaintBoundaryKey,
  }) async {
    try {
      final boundary = repaintBoundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  /// Save share card image to file
  Future<String?> saveShareCardImage({
    required String catName,
    required String diaryText,
    required EmotionType? emotion,
    required String topSpeech,
    required int bondScore,
    required GlobalKey repaintBoundaryKey,
  }) async {
    try {
      final imageBytes = await generateShareCardImage(
        catName: catName,
        diaryText: diaryText,
        emotion: emotion,
        topSpeech: topSpeech,
        bondScore: bondScore,
        repaintBoundaryKey: repaintBoundaryKey,
      );

      if (imageBytes == null) return null;

      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/cat_talk_share_$timestamp.png';
      final file = File(filePath);
      await file.writeAsBytes(imageBytes);
      return filePath;
    } catch (e) {
      return null;
    }
  }

  /// Generate Threads caption
  String generateThreadsCaption({
    required String catName,
    required String speech,
    required EmotionType? emotion,
  }) {
    // Intro
    final intros = emotion != null
        ? _threadsIntros[emotion] ?? _noEmotionIntros
        : _noEmotionIntros;
    final intro = intros[DateTime.now().second % intros.length];

    // Question
    final questions = emotion != null
        ? _threadsQuestions[emotion] ?? _noEmotionQuestions
        : _noEmotionQuestions;
    final question = questions[DateTime.now().second % questions.length];

    // Random Hashtags (take 2)
    final shuffledHashtags = List<String>.from(_randomHashtags)..shuffle();
    final randomTags = shuffledHashtags.take(2).toList();

    // All Hashtags
    final allTags = [..._fixedHashtags, ...randomTags];

    return '''$intro

She actually said:

"$speech"

$question

${allTags.join(' ')}''';
  }

  /// Generate general share text (for when no translation is available)
  String generateGeneralShareText({
    required String catName,
    required String moodSentence,
    required int bondScore,
  }) {
    final tags = '#CatTalk #CatDiary #MyCatIsCute #CatLife';
    return '''$catName today mini diary

$moodSentence

Bond: $bondScore%

$tags''';
  }
}