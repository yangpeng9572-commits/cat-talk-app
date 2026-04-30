import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../models/cat.dart';
import '../services/cat_service.dart';

class AddCatPage extends StatefulWidget {
  const AddCatPage({super.key});

  @override
  State<AddCatPage> createState() => _AddCatPageState();
}

class _AddCatPageState extends State<AddCatPage> {
  bool _isMale = false;
  double _age = 0;
  String _breed = '';
  String? _avatarPath;
  final TextEditingController _nameController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  final List<String> _breeds = [
    '英國短毛貓',
    '美國短毛貓',
    '波斯貓',
    '緬甸貓',
    '緬因貓',
    '布偶貓',
    '暹羅貓',
    '孟加拉豹貓',
    '蘇格蘭折耳貓',
    '俄羅斯藍貓',
    '混種貓',
    '其他',
  ];

  String _getAgeStage(double age) {
    if (age < 0.5) return 'kitten';
    if (age < 2) return 'junior';
    if (age < 7) return 'adult';
    if (age < 10) return 'senior';
    return 'geriatric';
  }

  String _getAgeStageLabel(double age) {
    if (age < 0.5) return '幼貓 (0-6個月)';
    if (age < 2) return '少年貓 (7個月~2歲)';
    if (age < 7) return '成貓 (3-7歲)';
    if (age < 10) return '老年貓 (8-10歲)';
    return '高齡貓 (11+歲)';
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('選擇照片', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPickOption(
                  icon: Icons.camera_alt,
                  label: '拍照',
                  onTap: () => Navigator.pop(context, 'camera'),
                ),
                _buildPickOption(
                  icon: Icons.photo_library,
                  label: '相簿',
                  onTap: () => Navigator.pop(context, 'gallery'),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _avatarPath = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('無法開啟相機：$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildPickOption({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: Colors.orange),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('添加貓咪'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('跳過', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 頭像 - 可點擊選擇照片
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  // 頭像圓形
                  _avatarPath != null
                      ? CircleAvatar(
                          radius: 60,
                          backgroundImage: FileImage(File(_avatarPath!)),
                          backgroundColor: Colors.grey.shade200,
                        )
                      : CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey.shade200,
                          child: const Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                        ),
                  // 相機按鈕
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text('點擊上方大頭貼新增照片', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 32),

            // 名字
            _buildNameField(),
            const SizedBox(height: 24),

            // 性別
            _buildGenderSelector(),
            const SizedBox(height: 24),

            // 年齡
            _buildAgeSlider(),
            const SizedBox(height: 24),

            // 品種
            _buildBreedSelector(),
            const SizedBox(height: 48),

            // 添加按鈕
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () async {
                  // 驗證名字
                  final name = _nameController.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('請先幫貓咪取個名字 🐱'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  
                  // 建立新貓咪
                  final cat = Cat(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: name,
                    breed: _breed.isNotEmpty ? _breed : '混種貓',
                    gender: _isMale ? 'male' : 'female',
                    age: _age,
                    ageStage: _getAgeStage(_age),
                    avatarPath: _avatarPath,
                  );
                  
                  // 儲存
                  final prefs = await SharedPreferences.getInstance();
                  final catService = CatService(prefs);
                  await catService.addCat(cat);
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('已新增她的小檔案 💕'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.pop(context, cat);
                  }
                },
                child: const Text('添加', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('名字', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: '給你的貓取個名字',
            prefixIcon: const Icon(Icons.pets, color: Colors.orange),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.orange, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('性別', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _isMale = false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: !_isMale ? Colors.orange : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!_isMale) const Icon(Icons.check, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '女孩 👧',
                        style: TextStyle(
                          color: !_isMale ? Colors.white : Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _isMale = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _isMale ? Colors.blue : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isMale) const Icon(Icons.check, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '男孩 👦',
                        style: TextStyle(
                          color: _isMale ? Colors.white : Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAgeSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('年齡', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            Text(
              '${_age.toStringAsFixed(1)} 歲',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _getAgeStageLabel(_age),
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
        Slider(
          value: _age,
          min: 0,
          max: 20,
          divisions: 40,
          activeColor: Colors.orange,
          inactiveColor: Colors.orange.withOpacity(0.2),
          onChanged: (value) => setState(() => _age = value),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0歲', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            Text('20+歲', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ],
        ),
      ],
    );
  }

  Widget _buildBreedSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('品種', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _breed.isEmpty ? null : _breed,
              hint: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('選擇品種', style: TextStyle(color: Colors.grey)),
              ),
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              borderRadius: BorderRadius.circular(12),
              items: _breeds.map((breed) {
                return DropdownMenuItem(
                  value: breed,
                  child: Text(breed),
                );
              }).toList(),
              onChanged: (value) => setState(() => _breed = value ?? ''),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
