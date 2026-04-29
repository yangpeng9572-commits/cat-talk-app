import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// 姿勢辨識頁面
/// 使用 Google ML Kit 偵測人體姿勢，推斷與貓咪的互動類型
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
  
  // ML Kit Pose Detector
  late PoseDetector _poseDetector;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _initializeCamera();
    _initializePoseDetector();
  }

  void _initializePoseDetector() {
    final options = PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.base,
    );
    _poseDetector = PoseDetector(options: options);
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
    _poseDetector.close();
    super.dispose();
  }

  Future<void> _takePhotoAndAnalyze() async {
    // 防止重複點擊
    if (_isAnalyzing) return;
    
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
      
      // 使用 ML Kit 分析姿勢
      await _analyzePose(photo.path);
    } catch (e) {
      debugPrint('拍照失敗: $e');
      setState(() => _isAnalyzing = false);
      _showErrorDialog('姿勢分析失敗，請稍後再試');
    }
  }

  Future<void> _analyzePose(String photoPath) async {
    try {
      final inputImage = InputImage.fromFilePath(photoPath);
      final poses = await _poseDetector.processImage(inputImage);
      
      if (!mounted) return;

      if (poses.isEmpty) {
        _showNoPersonDialog(photoPath);
        return;
      }

      // 分析姿勢並產生結果
      final result = _analyzePoseResult(poses.first);
      _showResultDialog(result.pose, result.advice, result.interactionType, photoPath);
      
    } catch (e) {
      debugPrint('姿勢分析失敗: $e');
      _showNoPersonDialog(photoPath);
    }
  }

  /// 分析姿勢結果
  _PoseAnalysisResult _analyzePoseResult(Pose pose) {
    // 取得關鍵點
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
    final nose = pose.landmarks[PoseLandmarkType.nose];

    // 預設結果
    String poseName = '放鬆站立';
    String advice = '你的貓咪正在觀察你，保持溫柔的姿態吧 💕';
    String interactionType = 'observe';

    // 計算肩膀高度（判断是否蹲下）
    final bool isCrouching = _isCrouching(leftShoulder, rightShoulder, leftHip, rightHip);
    
    // 計算手臂姿勢
    final armPose = _analyzeArmPose(
      leftShoulder, rightShoulder,
      leftElbow, rightElbow,
      leftWrist, rightWrist,
    );

    // 根據姿勢組合判斷互動類型
    if (isCrouching) {
      if (armPose == 'extended') {
        poseName = '蹲下伸手';
        advice = '🐱 你的貓咪感到好奇！這個姿勢很像在邀請玩耍';
        interactionType = 'play';
      } else if (armPose == 'bent') {
        poseName = '蹲下靠近';
        advice = '💕 你正在溫柔地靠近，貓咪感受到你的善意';
        interactionType = 'pet';
      } else {
        poseName = '蹲下觀察';
        advice = '🐾 貓咪正在觀察你，保持耐心很重要';
        interactionType = 'observe';
      }
    } else if (armPose == 'extended') {
      poseName = '伸手互動';
      advice = '🤲 伸手是友善的姿態，貓咪可能在回應你';
      interactionType = 'feed';
    } else if (armPose == 'raised') {
      poseName = '高舉雙手';
      advice = '🙀 高舉雙手可能讓貓咪感到威脅，建議降低姿勢';
      interactionType = 'scare';
    } else {
      // 檢查是否有面對貓咪（鼻子指向）
      if (nose != null) {
        poseName = '溫柔注視';
        advice = '👀 貓咪感受到你的關注，這是建立信任的好時機';
        interactionType = 'bond';
      }
    }

    return _PoseAnalysisResult(
      pose: poseName,
      advice: advice,
      interactionType: interactionType,
    );
  }

  /// 判斷是否蹲下
  bool _isCrouching(PoseLandmark? leftShoulder, PoseLandmark? rightShoulder,
      PoseLandmark? leftHip, PoseLandmark? rightHip) {
    if (leftShoulder == null || rightShoulder == null ||
        leftHip == null || rightHip == null) {
      return false;
    }

    // 計算肩膀和臀部的垂直距離
    final shoulderY = (leftShoulder.y + rightShoulder.y) / 2;
    final hipY = (leftHip.y + rightHip.y) / 2;
    
    // 如果肩膀和臀部的距離較小於腿長，可能在蹲下
    final torsoHeight = (hipY - shoulderY).abs();
    
    // 檢查膝蓋位置（如果可用的話）
    // 蹲下時，膝盖會低於臀部
    return hipY < shoulderY + 50; // 簡化的判斷
  }

  /// 分析手臂姿勢
  String _analyzeArmPose(
    PoseLandmark? leftShoulder, PoseLandmark? rightShoulder,
    PoseLandmark? leftElbow, PoseLandmark? rightElbow,
    PoseLandmark? leftWrist, PoseLandmark? rightWrist,
  ) {
    if (leftWrist == null && rightWrist == null) {
      return 'none';
    }

    // 計算手臂伸展程度
    int extendedCount = 0;
    int bentCount = 0;

    // 檢查左臂
    if (leftShoulder != null && leftElbow != null && leftWrist != null) {
      final upperArmLength = _distance(leftShoulder, leftElbow);
      final forearmLength = _distance(leftElbow, leftWrist);
      final totalArmLength = upperArmLength + forearmLength;
      
      // 計算手腕和肩膀的距離
      final wristToShoulder = _distance(leftWrist, leftShoulder);
      
      // 如果手腕到肩膀的距離接近整隻手臂長度，手臂是伸展的
      if (wristToShoulder > totalArmLength * 0.7) {
        extendedCount++;
      } else if (wristToShoulder < totalArmLength * 0.5) {
        bentCount++;
      }
    }

    // 檢查右臂
    if (rightShoulder != null && rightElbow != null && rightWrist != null) {
      final upperArmLength = _distance(rightShoulder, rightElbow);
      final forearmLength = _distance(rightElbow, rightWrist);
      final totalArmLength = upperArmLength + forearmLength;
      
      final wristToShoulder = _distance(rightWrist, rightShoulder);
      
      if (wristToShoulder > totalArmLength * 0.7) {
        extendedCount++;
      } else if (wristToShoulder < totalArmLength * 0.5) {
        bentCount++;
      }
    }

    // 檢查是否高舉（手腕高於肩膀）
    final leftWristAbove = leftWrist != null && leftShoulder != null && 
        leftWrist.y < leftShoulder.y - 30;
    final rightWristAbove = rightWrist != null && rightShoulder != null && 
        rightWrist.y < rightShoulder.y - 30;

    if (leftWristAbove || rightWristAbove) {
      return 'raised';
    }

    if (extendedCount > 0) return 'extended';
    if (bentCount > 0) return 'bent';
    return 'none';
  }

  /// 計算兩點之間的距離
  double _distance(PoseLandmark a, PoseLandmark b) {
    return ((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y));
  }

  void _showNoPersonDialog(String photoPath) {
    setState(() => _isAnalyzing = false);
    _pulseController.stop();

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
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🤔', style: TextStyle(fontSize: 60)),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '沒有偵測到人影',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '請確保你在鏡頭範圍內，並且光線充足\n这样我才能分析你的姿勢 💕',
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
                child: const Text('再試一次', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showResultDialog(String pose, String advice, String interactionType, String photoPath) {
    setState(() => _isAnalyzing = false);
    _pulseController.stop();

    // 根據互動類型選擇表情
    String emoji;
    switch (interactionType) {
      case 'play':
        emoji = '🎾';
        break;
      case 'pet':
        emoji = '💕';
        break;
      case 'feed':
        emoji = '🍽';
        break;
      case 'scare':
        emoji = '😿';
        break;
      case 'bond':
        emoji = '🐱';
        break;
      default:
        emoji = '🐾';
    }

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
            Text(
              emoji,
              style: const TextStyle(fontSize: 48),
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
    setState(() {
      _isCameraInitialized = false;
      _isAnalyzing = false;
    });
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
                onPressed: () => Navigator.pop(context),
                child: const Text('返回上一頁'),
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
                  '對準你的貓咪（或自己），按下按鈕分析姿勢',
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

/// 姿勢分析結果
class _PoseAnalysisResult {
  final String pose;
  final String advice;
  final String interactionType;

  _PoseAnalysisResult({
    required this.pose,
    required this.advice,
    required this.interactionType,
  });
}
