import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final TextEditingController _nameController = TextEditingController();

  final List<String> _breeds = [
    '英國短毛貓',
    '美國短毛貓',
    '波斯貓',
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
    if (age < 0.5) return '幼貓 (0-6個月)';
    if (age < 2) return '少年貓 (7個月~2歲)';
    if (age < 7) return '成貓 (3-7歲)';
    if (age < 10) return '老年貓 (8-10歲)';
    return '高齡貓 (11+歲)';
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
            // 頭像
            GestureDetector(
              onTap: () {
                // 選擇照片
              },
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade200,
                    child: const Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                  ),
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
                        content: Text('請輸入貓咪的名字 🐱'),
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
                  );
                  
                  // 儲存
                  final prefs = await SharedPreferences.getInstance();
                  final catService = CatService(prefs);
                  await catService.addCat(cat);
                  
                  if (mounted) {
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
                      Icon(!_isMale ? Icons.check : Icons.female, color: !_isMale ? Colors.white : Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        '女孩',
                        style: TextStyle(
                          color: !_isMale ? Colors.white : Colors.grey,
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
                    color: _isMale ? Colors.orange : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_isMale ? Icons.check : Icons.male, color: _isMale ? Colors.white : Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        '男孩',
                        style: TextStyle(
                          color: _isMale ? Colors.white : Colors.grey,
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_age.toStringAsFixed(1)} 歲',
                style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _getAgeStage(_age),
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.orange,
            inactiveTrackColor: Colors.orange.shade100,
            thumbColor: Colors.orange,
            overlayColor: Colors.orange.withOpacity(0.2),
          ),
          child: Slider(
            value: _age,
            min: 0,
            max: 20,
            divisions: 40,
            onChanged: (value) {
              setState(() => _age = value);
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0', style: TextStyle(color: Colors.grey.shade500)),
            Text('20+', style: TextStyle(color: Colors.grey.shade500)),
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
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButton<String>(
            value: _breed.isEmpty ? null : _breed,
            hint: const Text('選擇品種'),
            isExpanded: true,
            underline: const SizedBox(),
            items: _breeds.map((breed) {
              return DropdownMenuItem(value: breed, child: Text(breed));
            }).toList(),
            onChanged: (value) {
              setState(() => _breed = value ?? '');
            },
          ),
        ),
      ],
    );
  }
}
