import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_task.dart';
import '../services/cat_pose_photo_service.dart';
import '../services/daily_task_service.dart';
import '../theme/kawaii_theme.dart';
import '../services/top_toast_service.dart';

/// 貓咪姿勢拍照預覽頁
/// 顯示拍攝的照片，提供重新拍攝或使用此照片的選項
class CatPosePreviewPage extends StatefulWidget {
  final String imagePath;

  const CatPosePreviewPage({
    super.key,
    required this.imagePath,
  });

  @override
  State<CatPosePreviewPage> createState() => _CatPosePreviewPageState();
}

class _CatPosePreviewPageState extends State<CatPosePreviewPage> {
  final ImagePicker _imagePicker = ImagePicker();
  final CatPosePhotoService _photoService = CatPosePhotoService();
  late DailyTaskService _taskService;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initTaskService();
  }

  Future<void> _initTaskService() async {
    final prefs = await SharedPreferences.getInstance();
    _taskService = DailyTaskService(prefs);
  }

  @override
  Widget build(BuildContext context) {
    final file = File(widget.imagePath);
    final fileExists = file.existsSync();

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
          '✅ 確認照片',
          style: TextStyle(
            color: KawaiiTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // 照片預覽區
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(17),
                child: fileExists
                    ? Image.file(
                        file,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      )
                    : Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.broken_image,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                '找不到照片檔案',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ),

          // 提示文字
          if (fileExists)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                '這張照片會用於後續姿勢辨識',
                style: TextStyle(
                  color: KawaiiTheme.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          const SizedBox(height: 16),

          // 按鈕區
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                // 使用此照片按鈕
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: fileExists && !_isProcessing
                        ? _usePhoto
                        : null,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle, size: 24),
                    label: Text(
                      _isProcessing ? '處理中...' : '使用此照片',
                      style: const TextStyle(
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
                const SizedBox(height: 12),
                // 重新拍攝按鈕
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing ? null : _retakePhoto,
                    icon: const Icon(Icons.camera_alt_outlined, size: 24),
                    label: const Text(
                      '重新拍攝',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: KawaiiTheme.primaryPink,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      side: const BorderSide(
                        color: KawaiiTheme.primaryPink,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _usePhoto() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      // 單純儲存照片，不做任何 AI 或品質檢查（P2-2A MVP）
      final result = await _photoService.savePosePhotoPath(widget.imagePath);

      if (!mounted) return;

      if (result != null) {
        _taskService.updateTaskProgress(TaskType.pose_photo);
        TopToastService.success(context, message: '照片已準備好，之後會用於姿勢觀察 🐾');
        Navigator.pop(context);
      } else {
        TopToastService.error(context, message: '照片儲存失敗，請再試一次');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _retakePhoto() async {
    // 檢查相機權限
    final status = await Permission.camera.request();

    if (!status.isGranted) {
      if (mounted) {
        TopToastService.error(context, message: '相機開啟失敗，請確認權限後再試一次。');
      }
      return;
    }

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image == null) {
        // 使用者取消，不做任何事
        return;
      }

      final imagePath = image.path;

      if (!File(imagePath).existsSync()) {
        if (mounted) {
          TopToastService.error(context, message: '照片存取失敗，請確認權限後再試一次。');
        }
        return;
      }

      // 直接替換當前預覽頁的 imagePath，避免 Navigator 堆疊問題
      if (mounted) {
        setState(() {
          // widget.imagePath 是 final，但我們用新路徑重建
        });
        // 使用 pushReplacement 避免堆疊問題
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CatPosePreviewPage(imagePath: imagePath),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        TopToastService.error(context, message: '相機開啟失敗，請確認權限後再試一次。');
      }
    }
  }
}
