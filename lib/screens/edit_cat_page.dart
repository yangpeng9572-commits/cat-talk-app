import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cat.dart';
import '../services/cat_service.dart';
import '../services/top_toast_service.dart';

class EditCatPage extends StatefulWidget {
  final Cat cat;

  const EditCatPage({super.key, required this.cat});

  @override
  State<EditCatPage> createState() => _EditCatPageState();
}

class _EditCatPageState extends State<EditCatPage> {
  late TextEditingController _nameController;
  late String _gender;
  late double _age;
  late String _breed;
  String? _avatarPath;
  final ImagePicker _imagePicker = ImagePicker();

  // Birthday fields
  late int? _birthMonth;
  late int? _birthDay;
  late int? _birthYear;
  late String _birthdayType;
  late bool _isUnknownBirthday;
  late bool _isAdoptionDay;
  String _dateType = 'birthday'; // 'birthday' or 'adoption'

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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.cat.name);
    _gender = widget.cat.gender;
    _age = widget.cat.age;
    _breed = widget.cat.breed;
    _avatarPath = widget.cat.avatarPath;

    _birthMonth = widget.cat.birthMonth;
    _birthDay = widget.cat.birthDay;
    _birthYear = widget.cat.birthYear;
    _birthdayType = widget.cat.birthdayType;

    // Initialize date type from birthdayType
    _dateType = (_birthdayType == 'adoptionDay') ? 'adoption' : 'birthday';

    // Initialize checkbox states from birthdayType
    _isUnknownBirthday = _birthdayType == 'unknown';
    _isAdoptionDay = _birthdayType == 'adoptionDay';
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
        if (!mounted) return;
        setState(() {
          _avatarPath = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        TopToastService.error(context, message: '無法開啟相機：$e');
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
              color: Colors.orange.withValues(alpha: 0.1),
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

  int _getDaysInMonth(int month, [int? year]) {
    if (month == 2) {
      if (year != null && _isLeapYear(year)) return 29;
      return 28;
    }
    if ([4, 6, 9, 11].contains(month)) return 30;
    return 31;
  }

  bool _isLeapYear(int year) {
    return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
  }

  void _onBirthdayTypeChanged() {
    setState(() {
      if (_isUnknownBirthday) {
        _isAdoptionDay = false;
        _birthMonth = null;
        _birthDay = null;
        _birthYear = null;
        _birthdayType = 'unknown';
      } else if (_isAdoptionDay) {
        _birthMonth = null;
        _birthDay = null;
        _birthYear = null;
        _birthdayType = 'adoptionDay';
      } else if (_birthMonth != null && _birthDay != null && _birthYear != null) {
        _birthdayType = 'exact';
      } else if (_birthMonth != null && _birthDay != null) {
        _birthdayType = 'monthDayOnly';
      }
    });
  }

  void _onBirthFieldChanged() {
    setState(() {
      if (_isUnknownBirthday) {
        _birthdayType = 'unknown';
      } else if (_isAdoptionDay) {
        _birthdayType = 'adoptionDay';
      } else if (_birthMonth != null && _birthDay != null && _birthYear != null) {
        _birthdayType = 'exact';
      } else if (_birthMonth != null && _birthDay != null) {
        _birthdayType = 'monthDayOnly';
      }
    });
  }

  String? _validateBirthday() {
    if (_isUnknownBirthday || _isAdoptionDay) return null;

    if (_birthMonth == null && _birthDay == null) return null;

    if (_birthMonth != null && (_birthMonth! < 1 || _birthMonth! > 12)) {
      return '請輸入 1-12 月';
    }

    if (_birthDay != null) {
      int maxDay = _getDaysInMonth(_birthMonth ?? 1, _birthYear);
      if (_birthDay! < 1 || _birthDay! > maxDay) {
        return '請輸入正確日期';
      }
    }

    return null;
  }

  Future<void> _saveCat() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      TopToastService.error(context, message: '名字不能為空 🐱');
      return;
    }

    final birthdayError = _validateBirthday();
    if (birthdayError != null) {
      TopToastService.error(context, message: birthdayError ?? '生日資料有誤');
      return;
    }

    // Build updated cat - always use actual state values (which may be null for unknown/adoptionDay)
    final updatedCat = Cat(
      id: widget.cat.id, // preserve id
      name: name,
      gender: _gender,
      age: _age,
      ageStage: _getAgeStage(_age),
      breed: _breed.isNotEmpty ? _breed : '混種貓',
      avatarPath: _avatarPath,
      birthMonth: _birthMonth,
      birthDay: _birthDay,
      birthYear: _birthYear,
      birthdayType: _birthdayType,
    );

    final prefs = await SharedPreferences.getInstance();
    final catService = CatService(prefs);
    await catService.updateCat(updatedCat);

    if (!mounted) return;
    TopToastService.success(context, message: '儲存成功 🐾');
    Navigator.of(context).pop(updatedCat);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('編輯貓咪'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saveCat,
            child: const Text('儲存', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 頭像編輯區
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 56,
                          backgroundColor: const Color(0xFFFFE0B2),
                          backgroundImage: _avatarPath != null &&
                                  !_avatarPath!.startsWith('content://') &&
                                  File(_avatarPath!).existsSync()
                              ? FileImage(File(_avatarPath!))
                              : null,
                          child: _avatarPath != null &&
                                  !_avatarPath!.startsWith('content://') &&
                                  File(_avatarPath!).existsSync()
                              ? null
                              : const Icon(Icons.pets, size: 48, color: Color(0xFFFF8A65)),
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
                    const SizedBox(height: 8),
                    const Text('更換照片', style: TextStyle(fontSize: 14, color: Colors.orange)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

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
            const SizedBox(height: 24),

            // 生日區塊
            _buildBirthdaySection(),
            const SizedBox(height: 48),

            // 儲存按鈕
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
                onPressed: _saveCat,
                child: const Text('儲存變更', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),

            // 刪除貓咪按鈕
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade400,
                  side: BorderSide(color: Colors.red.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _showDeleteConfirmation,
                child: const Text('刪除這隻貓咪', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確定要刪除？'),
        content: Text('確定要刪除「${widget.cat.name}」嗎？這個動作無法復原。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context); // 關閉 dialog
              _deleteCat(); // 執行刪除
            },
            child: const Text('確定刪除'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCat() async {
    final prefs = await SharedPreferences.getInstance();
    final catService = CatService(prefs);
    final deletedCatId = widget.cat.id;
    await catService.deleteCat(deletedCatId);
    if (!mounted) return;
    TopToastService.success(context, message: '已刪除 🐱');
    Navigator.pop(context, true); // 回傳 true 給上一層刷新，通知 caller 貓已被刪除
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
    final isMale = _gender == 'male';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('性別', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _gender = 'female'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: !isMale ? Colors.orange : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!isMale) const Icon(Icons.check, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '女孩 👧',
                        style: TextStyle(
                          color: !isMale ? Colors.white : Colors.grey.shade600,
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
                onTap: () => setState(() => _gender = 'male'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: isMale ? Colors.blue : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isMale) const Icon(Icons.check, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '男孩 👦',
                        style: TextStyle(
                          color: isMale ? Colors.white : Colors.grey.shade600,
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
          inactiveColor: Colors.orange.withValues(alpha: 0.2),
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

  Widget _buildBirthdaySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text('🎂', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text('生日 / 領養日', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '不知道也沒關係，我們可以先用領養日記錄她的小日子。',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),

        // 日期類型：生日 / 領養日
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                value: 'birthday',
                groupValue: _dateType,
                onChanged: _dateType == 'birthday'
                    ? null
                    : (v) {
                        setState(() {
                          _dateType = v!;
                          if (_dateType == 'adoption') {
                            _birthMonth = null;
                            _birthDay = null;
                            _birthYear = null;
                            _birthdayType = 'adoptionDay';
                          } else {
                            _birthdayType = (_birthMonth != null && _birthDay != null && _birthYear != null)
                                ? 'exact'
                                : (_birthMonth != null && _birthDay != null)
                                    ? 'monthDayOnly'
                                    : 'unknown';
                          }
                        });
                      },
                title: const Text('生日'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                value: 'adoption',
                groupValue: _dateType,
                onChanged: _dateType == 'adoption'
                    ? null
                    : (v) {
                        setState(() {
                          _dateType = v!;
                          if (_dateType == 'adoption') {
                            _birthMonth = null;
                            _birthDay = null;
                            _birthYear = null;
                            _birthdayType = 'adoptionDay';
                          }
                        });
                      },
                title: const Text('領養日'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 領養日提示
        if (_dateType == 'adoption')
          Text(
            '我們會記錄這天為你們相遇的日子 🏠',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),

        // 生日日期選擇（只有選「生日」時顯示）
        if (_dateType == 'birthday') ...[
          const SizedBox(height: 16),
          // 月份
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('月份', style: TextStyle(fontSize: 14)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButton<int?>(
                        value: _birthMonth,
                        hint: const Text('選擇月份'),
                        isExpanded: true,
                        items: List.generate(12, (i) {
                          final m = i + 1;
                          return DropdownMenuItem(value: m, child: Text('$m 月'));
                        }),
                        onChanged: (v) {
                          setState(() {
                            _birthMonth = v;
                            if (_birthDay != null) {
                              final maxDay = _getDaysInMonth(v ?? 1, _birthYear);
                              if (_birthDay! > maxDay) _birthDay = maxDay;
                            }
                          });
                          _onBirthFieldChanged();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('日期', style: TextStyle(fontSize: 14)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButton<int?>(
                        value: _birthDay,
                        hint: const Text('選擇日期'),
                        isExpanded: true,
                        items: _birthMonth != null
                            ? List.generate(_getDaysInMonth(_birthMonth!, _birthYear), (i) {
                                final d = i + 1;
                                return DropdownMenuItem(value: d, child: Text('$d 日'));
                              })
                            : [],
                        onChanged: (v) {
                          setState(() => _birthDay = v);
                          _onBirthFieldChanged();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 年份（可選）
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('年份（可選）', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButton<int?>(
                  value: _birthYear,
                  hint: const Text('選擇年份'),
                  isExpanded: true,
                  items: List.generate(25, (i) {
                    final y = DateTime.now().year - i;
                    return DropdownMenuItem(value: y, child: Text('$y 年'));
                  }),
                  onChanged: (v) {
                    setState(() {
                      _birthYear = v;
                      if (_birthMonth == 2 && _birthDay == 29 && v != null && !_isLeapYear(v)) {
                        _birthDay = 28;
                      }
                    });
                    _onBirthFieldChanged();
                  },
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}