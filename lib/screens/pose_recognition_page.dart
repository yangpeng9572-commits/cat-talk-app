import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

class PoseRecognitionPage extends StatefulWidget {
  const PoseRecognitionPage({super.key});

  @override
  State<PoseRecognitionPage> createState() => _PoseRecognitionPageState();
}

class _PoseRecognitionPageState extends State<PoseRecognitionPage>
    with SingleTickerProviderStateMixin {
  bool _isAnalyzing = false;
  bool _isCameraInitialized = false;
  bool _hasPermission = false;
  bool _isCameraError = false;
  
  CameraController? _cameraController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    // 檢查相機權限
    final status = await Permission.camera.status;
    
    if (status.isDenied) {
      final result = await Permission.camera.request();
      if (!result.isGranted) {
        setState(() => _hasPermission = false);
        return;
      }
    }
    
    if (status.isPermanentlyDenied) {
      setState(() => _hasPermission = false);
      return;
    }

    setState(() => _hasPermission = true);

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _isCameraError = true);
        return;
      }

      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      debugPrint('相機初始化失敗: $e');
      setState(() => _isCameraError = true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _takePhotoAndAnalyze() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _showErrorDialog('相機無法使用，請稍後再試');
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _isCameraInitialized = false;
    });
    _pulseController.repeat();

    try {
      // 拍照
      final XFile photo = await _cameraController!.takePicture();
      
      // 等待分析動畫
      await Future.delayed(const Duration(seconds: 2));
      
      // 模擬分析結果
      _simulateResult(photo.path);
    } catch (e) {
      debugPrint('拍照失敗: $e');
      setState(() => _isAnalyzing = false);
      _showErrorDialog('拍照失敗，請稍後再試');
    }
  }

  void _simulateResult(String photoPath) {
    // 模擬姿勢分析結果
    final results = [
      ('尾巴豎直向上', '🐱 開心問候！你的貓看到你很高興'),
      ('耳朵向前', '🎾 好奇興奮！你的貓想要玩耍'),
      ('瞳孔放大', '😿 有些害怕！環境可能有威脅'),
      ('揉麵包', '💕 滿足幸福！你的貓很放鬆'),
      ('飛機耳', '😾 緊張警戒！不要突然靠近'),
    ];

    final result = results[DateTime.now().second % results.length];
    
    setState(() {
      _isAnalyzing = false;
    });
    _pulseController.stop();

    _showResultDialog(result.$1, result.$2, photoPath);
  }

  void _showResultDialog(String pose, String advice, String photoPath) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            // 顯示拍的照片
            if (photoPath.isNotEmpty)
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: FileImage(File(photoPath)),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            const Text(
              '🔍 姿勢分析結果',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              pose,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              advice,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _restartCamera();
                },
                child: const Text('再拍一張', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _restartCamera() async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
    }
    await _initializeCamera();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('📷 ', style: TextStyle(fontSize: 24)),
            Text('相機問題'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('關閉'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              _restartCamera();
            },
            child: const Text('重試'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('📷 ', style: TextStyle(fontSize: 24)),
            Text('需要相機權限'),
          ],
        ),
        content: const Text(
          '姿勢辨識需要使用相機功能，請到設定中開啟相機權限。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('開啟設定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('姿勢辨識'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (_isCameraInitialized)
            IconButton(
              icon: const Icon(Icons.flip_camera_ios),
              onPressed: () async {
                // 切換前後相機（如果有多個相機）
                // 目前先不支援
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // 權限被拒絕
    if (!_hasPermission) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.camera_alt_outlined,
                  size: 64,
                  color: Colors.orange.shade400,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '需要相機權限',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '請允許使用相機，這樣才能進行姿勢辨識',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _showPermissionDeniedDialog,
                child: const Text('開啟設定'),
              ),
            ],
          ),
        ),
      );
    }

    // 相機錯誤
    if (_isCameraError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.shade400,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '相機無法使用',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '抱歉，您的裝置不支援相機功能',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _restartCamera,
                child: const Text('重試'),
              ),
            ],
          ),
        ),
      );
    }

    // 分析中
    if (_isAnalyzing) {
      return _buildAnalyzingView();
    }

    // 相機就緒
    if (_isCameraInitialized && _cameraController != null) {
      return _buildCameraView();
    }

    // 載入中
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.orange),
          SizedBox(height: 16),
          Text(
            '相機初始化中...',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    return Column(
      children: [
        // 說明
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '對準你的貓咪，按下按鈕拍照並分析姿勢',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ],
          ),
        ),

        // 相機預覽
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: CameraPreview(_cameraController!),
            ),
          ),
        ),

        // 拍照按鈕
        Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: double.infinity,
            height: 64,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
              ),
              onPressed: _takePhotoAndAnalyze,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, size: 28),
                  SizedBox(width: 12),
                  Text(
                    '拍照並分析',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyzingView() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 120 + (_pulseController.value * 20),
                  height: 120 + (_pulseController.value * 20),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(
                      alpha: 0.3 * (1 - _pulseController.value),
                    ),
                    shape: BoxShape.circle,
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              '🔍 分析中...',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              '請稍候，正在分析姿勢',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
