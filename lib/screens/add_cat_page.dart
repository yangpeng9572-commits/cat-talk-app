import 'dart:io';
import '../widgets/top_toast.dart';
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

  // Birthday fields
  int? _birthMonth;
  int? _birthDay;
  int? _birthYear;
  String _birthdayType = 'unknown'; // 'exact', 'monthDayOnly', 'adoptionDay', 'unknown'
  bool _isUnknownBirthday = false;
  bool _isAdoptionDay = false;
  String _dateType = 'birthday'; // 'birthday' or 'adoption'
  bool _isLoading = false;

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
        TopToast.error(context, message: '無法開啟相機：$e');
      }
    }
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
      if (_birthMonth != null && _birthDay != null && _birthYear != null) {
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
              onTap: _pickImage,
              child: Stack(
                children: [
                  _avatarPath != null
                      ? CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey.shade200,
                          child: ClipOval(
                            child: Image.file(
                              File(_avatarPath!),
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      : CircleAvatar(
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
            const SizedBox(height: 24),

            // 生日區塊
            _buildBirthdaySection(),
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
                onPressed: _isLoading
                    ? null
                    : () async {
                        FocusScope.of(context).unfocus();

                        if (_isLoading) return;
                        setState(() => _isLoading = true);

                        try {
                          final name = _nameController.text.trim();
                          if (name.isEmpty) {
                            TopToast.error(context, message: '請先幫貓咪取個名字 🐱');
                            setState(() => _isLoading = false);
                            return;
                          }

                          final birthdayError = _validateBirthday();
                          if (birthdayError != null) {
                            TopToast.error(context, message: birthdayError ?? '生日資料有誤');
                            setState(() => _isLoading = false);
                            return;
                          }

                          final cat = Cat(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            name: name,
                            breed: _breed.isNotEmpty ? _breed : '混種貓',
                            gender: _isMale ? 'male' : 'female',
                            age: _age,
                            ageStage: _getAgeStage(_age),
                            avatarPath: _avatarPath,
                            birthMonth: _birthMonth,
                            birthDay: _birthDay,
                            birthYear: _birthYear,
                            birthdayType: _birthdayType,
                          );

                          final prefs = await SharedPreferences.getInstance();
                          final catService = CatService(prefs);
                          await catService.addCat(cat);

                          if (!mounted) return;

                          Navigator.of(context).pop(cat.id);
                        } catch (e) {
                          if (!mounted) return;

                          setState(() => _isLoading = false);

                          TopToast.error(context, message: '新增失敗：$e');
                        }
                      },
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        '添加',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
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
                      if (_birthMonth == 2 && _birthDay == 29 && !_isLeapYear(v!)) {
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
