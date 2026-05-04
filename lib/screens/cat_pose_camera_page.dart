import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/kawaii_theme.dart';
import '../services/top_toast_service.dart';
import '../widgets/cat_pose_camera_frame.dart';
import 'cat_pose_preview_page.dart';
import 'pose_recognition_page.dart';

/// 姿勢觀察相機頁
/// 使用 camera package 在 App 內顯示 CameraPreview，拍照後進入預覽頁
class CatPoseCameraPage extends StatefulWidget {
  const CatPoseCameraPage({super.key});

  @override
  State<CatPoseCameraPage> createState() => _CatPoseCameraPageState();
}

class _CatPoseCameraPageState extends State<CatPoseCameraPage>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isTakingPhoto = false;
  bool _hasError = false;
  String _errorMessage = '';
  List<CameraDescription> _cameras = [];

  /// 提示文字列表
  static const _tips = [
    '讓我看清楚主子全身喔 🐾',
    '光線亮一點，姿勢會更好判斷',
    '盡量不要晃動手機',
    '避免拍到多隻貓',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    if (!mounted) return;

    setState(() {
      _isInitialized = false;
      _hasError = false;
    });

    // 1. 取得可用相機列表
    try {
      _cameras = await availableCameras();
    } catch (e) {
      _setError('無法取得相機列表');
      return;
    }

    if (_cameras.isEmpty) {
      _setError('找不到相機，請確認裝置有相機功能');
      return;
    }

    // 2. 篩選後鏡頭
    CameraDescription? rearCamera;
    try {
      rearCamera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
    } catch (_) {
      rearCamera = _cameras.first;
    }

    // 3. 建立 CameraController
    _controller = CameraController(
      rearCamera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    // 4. 初始化
    try {
      await _controller!.initialize();
    } on CameraException catch (e) {
      _setError('相機初始化失敗：${e.description ?? '未知錯誤'}');
      return;
    } catch (e) {
      _setError('相機初始化失敗，請稍後再試');
      return;
    }

    if (!mounted) return;

    setState(() {
      _isInitialized = true;
      _hasError = false;
    });
  }

  void _setError(String msg) {
    if (!mounted) return;
    setState(() {
      _hasError = true;
      _errorMessage = msg;
      _isInitialized = false;
    });
    TopToastService.error(context, message: msg);
  }

  Future<void> _takePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      TopToastService.error(context, message: '相機尚未就緒，請稍後再試');
      return;
    }

    if (_isTakingPhoto) return;

    setState(() => _isTakingPhoto = true);

    try {
      final XFile image = await _controller!.takePicture();

      if (!mounted) return;

      final imagePath = image.path;

      // 檢查檔案是否存在
      if (!File(imagePath).existsSync()) {
        TopToastService.error(context, message: '照片存取失敗，請稍後再試');
        setState(() => _isTakingPhoto = false);
        return;
      }

      // 導向預覽頁
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CatPosePreviewPage(imagePath: imagePath),
          ),
        );
      }
    } on CameraException catch (e) {
      if (mounted) {
        TopToastService.error(context, message: '拍攝失敗：${e.description ?? '請稍後再試'}');
      }
    } catch (e) {
      if (mounted) {
        TopToastService.error(context, message: '拍攝失敗，請稍後再試');
      }
    } finally {
      if (mounted) {
        setState(() => _isTakingPhoto = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: KawaiiTheme.primaryPink),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '🔍 姿勢觀察',
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
              // ===== CameraPreview + 引導框 =====
              Expanded(
                flex: 3,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // 相機預覽
                        if (_isInitialized && _controller != null)
                          CameraPreview(_controller!)
                        else if (_hasError)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.camera_alt_outlined,
                                    color: Colors.white54,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _errorMessage,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextButton(
                                    onPressed: _initCamera,
                                    child: const Text(
                                      '重試',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white54,
                            ),
                          ),
                        // 貓咪引導框（疊在 CameraPreview 上）
                        const CatPoseCameraFrame(),
                      ],
                    ),
                  ),
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
                    onPressed: _isTakingPhoto || !_isInitialized || _hasError
                        ? null
                        : _takePhoto,
                    icon: Icon(
                      _isTakingPhoto ? Icons.hourglass_empty : Icons.camera_alt,
                      size: 24,
                    ),
                    label: Text(
                      _isTakingPhoto ? '拍攝中...' : '開始拍照',
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
              ),
              const SizedBox(height: 12),
              // 動作庫入口
              TextButton.icon(
                onPressed: () {
                  if (!mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PoseRecognitionPage(),
                    ),
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
}