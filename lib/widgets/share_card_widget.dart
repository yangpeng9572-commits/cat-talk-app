import 'package:flutter/material.dart';
import '../models/translation_result.dart';
import '../theme/kawaii_theme.dart';

/// 分享卡片 Widget
/// 用於產生 1080x1080 分享圖片
class ShareCardWidget extends StatelessWidget {
  final String catName;
  final String diaryTitle;
  final String emotionSentence;
  final String topSpeech;
  final int bondScore;
  final String bondLevel;

  const ShareCardWidget({
    super.key,
    required this.catName,
    required this.diaryTitle,
    required this.emotionSentence,
    required this.topSpeech,
    required this.bondScore,
    required this.bondLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1080,
      height: 1080,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            KawaiiTheme.primaryPink.withOpacity(0.15),
            KawaiiTheme.creamWhite,
            KawaiiTheme.lavender.withOpacity(0.2),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              diaryTitle,
              style: TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.bold,
                color: KawaiiTheme.coral,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 20),

            // Emotion sentence
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                color: KawaiiTheme.softPink.withOpacity(0.5),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                emotionSentence,
                style: TextStyle(
                  fontSize: 38,
                  color: KawaiiTheme.coral.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 50),

            // Main speech (largest element)
            Expanded(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: KawaiiTheme.primaryPink.withOpacity(0.15),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Text(
                    topSpeech,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: KawaiiTheme.coral,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 50),

            // Bond score and level
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite,
                  color: Colors.pinkAccent.shade200,
                  size: 48,
                ),
                const SizedBox(width: 16),
                Text(
                  'Bond: $bondScore%',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w600,
                    color: Colors.pinkAccent.shade200,
                  ),
                ),
                const SizedBox(width: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: KawaiiTheme.lavender.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    bondLevel,
                    style: TextStyle(
                      fontSize: 32,
                      color: KawaiiTheme.coral.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Brand
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: KawaiiTheme.primaryPink.withOpacity(0.3),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  '來自 喵心語 Cat Talk',
                  style: TextStyle(
                    fontSize: 32,
                    color: KawaiiTheme.primaryPink.withOpacity(0.7),
                    letterSpacing: 3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Hashtags
            Center(
              child: Text(
                '#CatTalk #CatDiary #MyCatIsCute',
                style: TextStyle(
                  fontSize: 28,
                  color: KawaiiTheme.primaryPink.withOpacity(0.5),
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}