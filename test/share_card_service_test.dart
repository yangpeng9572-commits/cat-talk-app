import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cat_talk/services/share_card_service.dart';
import 'package:cat_talk/models/translation_result.dart';

void main() {
  group('ShareCardService 測試', () {
    late ShareCardService service;

    setUp(() {
      service = ShareCardService();
    });

    test('generateThreadsCaption affectionate 情緒生成正確', () {
      final caption = service.generateThreadsCaption(
        catName: '奶茶',
        speech: '抱抱我嘛～我想黏著你 💕',
        emotion: EmotionType.affectionate,
      );

      expect(caption, contains('She actually said:'));
      expect(caption, contains('"抱抱我嘛～我想黏著你 💕"'));
      expect(caption, contains('#CatTalk'));
      expect(caption, contains('#CatDiary'));
      expect(caption, contains('#MyCatIsCute'));
    });

    test('generateThreadsCaption hungry 情緒生成正確', () {
      final caption = service.generateThreadsCaption(
        catName: '奶茶',
        speech: '我有點餓餓了…你是不是忘記我了',
        emotion: EmotionType.hungry,
      );

      expect(caption, contains('She actually said:'));
      expect(caption, contains('我有點餓餓了…你是不是忘記我了'));
    });

    test('generateThreadsCaption playful 情緒生成正確', () {
      final caption = service.generateThreadsCaption(
        catName: '奶茶',
        speech: '陪我玩一下嘛！',
        emotion: EmotionType.playful,
      );

      expect(caption, contains('She actually said:'));
      expect(caption, contains('陪我玩一下嘛！'));
    });

    test('generateThreadsCaption null 情緒生成正確', () {
      final caption = service.generateThreadsCaption(
        catName: '奶茶',
        speech: '今天也很想跟你說說話',
        emotion: null,
      );

      expect(caption, contains('She actually said:'));
      expect(caption, contains('今天也很想跟你說說話'));
    });

    test('generateGeneralShareText 生成正確', () {
      final text = service.generateGeneralShareText(
        catName: '奶茶',
        moodSentence: '今天她很黏人 💕',
        bondScore: 76,
      );

      expect(text, contains('奶茶 today mini diary'));
      expect(text, contains('今天她很黏人 💕'));
      expect(text, contains('Bond: 76%'));
      expect(text, contains('#CatTalk'));
    });

    test('每種情緒都能產生 Threads caption', () {
      for (final emotion in EmotionType.values) {
        final caption = service.generateThreadsCaption(
          catName: '奶茶',
          speech: '測試句子',
          emotion: emotion,
        );

        expect(caption, isNotEmpty);
        expect(caption, contains('She actually said:'));
        expect(caption, contains('#CatTalk'));
      }
    });
  });
}