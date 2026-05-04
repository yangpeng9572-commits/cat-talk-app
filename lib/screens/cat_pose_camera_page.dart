import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/kawaii_theme.dart';
import '../services/top_toast_service.dart';
import '../widgets/cat_pose_camera_frame.dart';
import 'cat_pose_preview_page.dart';
import 'pose_recognition_page.dart';

/// 貓咪姿勢拍照頁
/// v1：使用 image_picker 拍照，提供引導框提示使用者將貓咪置於框內
class CatPoseCameraPage extends StatefulWidget {
  const CatPoseCameraPage({super.key});

  @override
  State<CatPoseCameraPage> createState() => _CatPoseCameraPageState();
}

class _CatPoseCameraPageState extends State<CatPoseCameraPage> {
  final ImagePicker _imagePicker = ImagePicker();

  /// 提示文字列表
  static const _tips = [
    '讓我看清楚主子全身喔 🐾',
    '光線亮一點，姿勢會更好判斷',
    '盡量不要晃動手機',
    '避免拍到多隻貓',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KawaiiTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: KawaiiTheme.primaryPink),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '🐱 貓咪姿勢拍照',
          style: TextStyle(
            color: KawaiiTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8E8FF),
              KawaiiTheme.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
              // 拍照引導區
              Expanded(
                flex: 3,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B7FBF).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: const CatPoseCameraFrame(),
                ),
              ),
              const SizedBox(height: 16),
              // 提示文字
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: _tips.map((tip) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            color: KawaiiTheme.primaryPink,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            tip,
                            style: const TextStyle(
                              color: KawaiiTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              // 拍照按鈕
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera_alt, size: 24),
                    label: const Text(
                      '開始拍照',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KawaiiTheme.primaryPink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 4,
                      shadowColor: KawaiiTheme.primaryPink.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // 動作庫入口（已從首頁移至姿勢拍照流程內）
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PoseRecognitionPage()),
                  );
                },
                icon: const Icon(Icons.collections_bookmark, size: 18),
                label: const Text('看動作庫當參考'),
                style: TextButton.styleFrom(
                  foregroundColor: KawaiiTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _takePhoto() async {
    // 1. 檢查相機權限
    final status = await Permission.camera.request();

    if (!status.isGranted) {
      if (mounted) {
        TopToastService.error(context, message: '相機開啟失敗，請確認權限後再試一次。');
      }
      return;
    }

    try {
      // 2. 使用 image_picker 拍照
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image == null) {
        // 使用者取消拍照，不做任何事
        return;
      }

      final imagePath = image.path;

      // 3. 檢查檔案是否存在
      if (!File(imagePath).existsSync()) {
        if (mounted) {
          TopToastService.error(context, message: '照片存取失敗，請確認權限後再試一次。');
        }
        return;
      }

      // 4. 導向預覽頁
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CatPosePreviewPage(imagePath: imagePath),
          ),
        );
      }
    } catch (e) {
      // 5. 發生錯誤
      if (mounted) {
        TopToastService.error(context, message: '相機開啟失敗，請確認權限後再試一次。');
      }
    }
  }
}
