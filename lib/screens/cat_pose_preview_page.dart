import 'dart:io';
import 'dart:typed_data';
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
          '📸 照片預覽',
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
      // P2-3 MVP: 姿勢照片品質檢查（解析實際圖片尺寸）
      final file = File(widget.imagePath);
      int? imgWidth;
      int? imgHeight;
      List<int>? bytes;

      if (file.existsSync()) {
        bytes = await file.readAsBytes();
      }

      // 解析 PNG / JPEG 圖片尺寸（header-only，不載入完整圖片）
      if (bytes != null && bytes.length > 24) {
        try {
          // PNG: signature + IHDR chunk (width at offset 16, height at offset 20, big-endian)
          if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
            imgWidth  = (bytes[16] << 24) | (bytes[17] << 16) | (bytes[18] << 8) | bytes[19];
            imgHeight = (bytes[20] << 24) | (bytes[21] << 16) | (bytes[22] << 8) | bytes[23];
          }
          // JPEG: scan for SOF0/SOF1/SOF2 (FF C0 / FF C2 / FF C3)
          else if (bytes[0] == 0xFF && bytes[1] == 0xD8) {
            int offset = 2;
            while (offset < bytes.length - 8) {
              if (bytes[offset] == 0xFF &&
                  bytes[offset + 1] >= 0xC0 && bytes[offset + 1] <= 0xCF &&
                  bytes[offset + 1] != 0xC4 && bytes[offset + 1] != 0xC8 &&
                  bytes[offset + 1] != 0xCC) {
                imgHeight = (bytes[offset + 5] << 8) | bytes[offset + 6];
                imgWidth  = (bytes[offset + 7] << 8) | bytes[offset + 8];
                break;
              }
              final len = (bytes[offset + 2] << 8) | bytes[offset + 3];
              offset += 2 + len;
            }
          }
        } catch (_) {}
      }

      final result = await _photoService.savePosePhotoPath(widget.imagePath);

      if (!mounted) return;

      if (result != null) {
        _taskService.updateTaskProgress(TaskType.pose_photo);
        // P2-3: 根據實際圖片解析度給予不同提示
        final int minDim = [imgWidth, imgHeight].whereType<int>().fold(0, (a, b) => a == 0 ? b : (a < b ? a : b));
        String qualityMsg;
        if (minDim > 0 && minDim < 640) {
          qualityMsg = '已保存（解析度偏低，建議光線充足） 🐾';
        } else if (minDim >= 1280) {
          qualityMsg = '已保存高畫質照片 🐾';
        } else {
          qualityMsg = '已保存照片，之後可用於姿勢辨識 🐾';
        }
        TopToastService.success(context, message: qualityMsg);
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
