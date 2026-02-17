import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/language_service.dart';
import '../models/user_profile_extended.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String userId;
  final String nickname;
  
  const ProfileSetupScreen({
    super.key,
    required this.userId,
    required this.nickname,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Student Information
  StudentType _studentType = StudentType.degree;
  String? _selectedDepartment;
  String? _customDepartment;
  
  // Living Setup Information
  DateTime? _entryDate;
  HousingType? _housingType;
  String? _housingOther;
  KoreanLevel? _koreanLevel;
  final _dietaryController = TextEditingController();
  final List<String> _selectedInterests = [];
  
  // Visa Information
  String? _selectedVisa;
  String? _customVisa;

  @override
  void dispose() {
    _dietaryController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final lang = Provider.of<LanguageService>(context, listen: false);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _entryDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: lang.translate('select_entry_date'),
    );
    if (picked != null && picked != _entryDate) {
      setState(() {
        _entryDate = picked;
      });
    }
  }

  void _toggleInterest(String interestId) {
    setState(() {
      if (_selectedInterests.contains(interestId)) {
        _selectedInterests.remove(interestId);
      } else {
        _selectedInterests.add(interestId);
      }
    });
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      // Validate interests
      if (_selectedInterests.length < 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Provider.of<LanguageService>(context, listen: false).translate('select_interests')),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Create profile
      final profile = UserProfileExtended(
        userId: widget.userId,
        nickname: widget.nickname,
        studentType: _studentType,
        department: _selectedDepartment == 'other' 
            ? (_customDepartment ?? '') 
            : (_selectedDepartment ?? ''),
        entryDate: _entryDate,
        housingType: _housingType,
        housingOther: _housingType == HousingType.other ? _housingOther : null,
        koreanLevel: _koreanLevel,
        dietaryPreference: _dietaryController.text.trim().isNotEmpty 
            ? _dietaryController.text.trim() 
            : null,
        interests: _selectedInterests,
        visaType: _selectedVisa == 'other' ? _customVisa : _selectedVisa,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // TODO: Save to Firestore or local storage
      // For now, just show notification permission dialog
      if (mounted) {
        _showNotificationPermissionDialog();
      }
    }
  }

  void _showNotificationPermissionDialog() {
    final lang = Provider.of<LanguageService>(context, listen: false);
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '🔔',
                  style: TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 16),
                Text(
                  lang.translate('notification_permission_title'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0038A8),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  lang.translate('notification_permission_desc'),
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                _buildNotificationFeature(lang.translate('notification_feature1')),
                const SizedBox(height: 12),
                _buildNotificationFeature(lang.translate('notification_feature2')),
                const SizedBox(height: 12),
                _buildNotificationFeature(lang.translate('notification_feature3')),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop(); // Go back to previous screen
                      },
                      child: Text(lang.translate('skip')),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // TODO: Request notification permission
                        Navigator.of(context).pop();
                        Navigator.of(context).pop(); // Go back to previous screen
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0038A8),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                      child: Text(lang.translate('turn_on_notifications')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationFeature(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);
    final langCode = lang.currentLanguage;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('complete_profile')),
        backgroundColor: const Color(0xFF0038A8),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Student Type
              Text(
                lang.translate('student_type'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<StudentType>(
                      title: Text(lang.translate('degree_student')),
                      value: StudentType.degree,
                      groupValue: _studentType,
                      onChanged: (value) {
                        setState(() {
                          _studentType = value!;
                          if (_studentType == StudentType.exchange) {
                            _selectedDepartment = 'international_affairs';
                          } else {
                            _selectedDepartment = null;
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<StudentType>(
                      title: Text(lang.translate('exchange_student')),
                      value: StudentType.exchange,
                      groupValue: _studentType,
                      onChanged: (value) {
                        setState(() {
                          _studentType = value!;
                          if (_studentType == StudentType.exchange) {
                            _selectedDepartment = 'international_affairs';
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Department
              Text(
                lang.translate('department'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (_studentType == StudentType.exchange)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    DepartmentData.getDepartmentName('international_affairs', langCode),
                    style: const TextStyle(fontSize: 16),
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  value: _selectedDepartment,
                  decoration: InputDecoration(
                    hintText: lang.translate('select_department'),
                    border: const OutlineInputBorder(),
                  ),
                  items: DepartmentData.departments
                      .where((dept) => dept['id'] != 'international_affairs')
                      .map((dept) {
                    return DropdownMenuItem(
                      value: dept['id'],
                      child: Text(dept[langCode] ?? dept['en'] ?? ''),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDepartment = value;
                    });
                  },
                  validator: (value) {
                    if (_studentType == StudentType.degree && value == null) {
                      return lang.translate('select_department');
                    }
                    return null;
                  },
                ),
              if (_selectedDepartment == 'other') ...[
                const SizedBox(height: 8),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: lang.translate('department'),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    _customDepartment = value;
                  },
                  validator: (value) {
                    if (_selectedDepartment == 'other' && (value == null || value.isEmpty)) {
                      return lang.translate('department');
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 16),

              // Entry Date
              Text(
                lang.translate('entry_date'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _entryDate != null
                            ? DateFormat('yyyy-MM-dd').format(_entryDate!)
                            : lang.translate('select_entry_date'),
                        style: TextStyle(
                          color: _entryDate != null ? Colors.black : Colors.grey,
                        ),
                      ),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Housing Type
              Text(
                lang.translate('housing_type'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: Text(lang.translate('dormitory')),
                    selected: _housingType == HousingType.dormitory,
                    onSelected: (selected) {
                      setState(() {
                        _housingType = selected ? HousingType.dormitory : null;
                      });
                    },
                  ),
                  ChoiceChip(
                    label: Text(lang.translate('studio')),
                    selected: _housingType == HousingType.studio,
                    onSelected: (selected) {
                      setState(() {
                        _housingType = selected ? HousingType.studio : null;
                      });
                    },
                  ),
                  ChoiceChip(
                    label: Text(lang.translate('housing_other')),
                    selected: _housingType == HousingType.other,
                    onSelected: (selected) {
                      setState(() {
                        _housingType = selected ? HousingType.other : null;
                      });
                    },
                  ),
                ],
              ),
              if (_housingType == HousingType.other) ...[
                const SizedBox(height: 8),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: lang.translate('housing_other'),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    _housingOther = value;
                  },
                ),
              ],
              const SizedBox(height: 16),

              // Korean Proficiency
              Text(
                lang.translate('korean_proficiency'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Column(
                children: [
                  RadioListTile<KoreanLevel>(
                    title: Text(lang.translate('no_topik')),
                    value: KoreanLevel.noTopik,
                    groupValue: _koreanLevel,
                    onChanged: (value) {
                      setState(() {
                        _koreanLevel = value;
                      });
                    },
                  ),
                  RadioListTile<KoreanLevel>(
                    title: Text(lang.translate('level_1_2')),
                    value: KoreanLevel.level12,
                    groupValue: _koreanLevel,
                    onChanged: (value) {
                      setState(() {
                        _koreanLevel = value;
                      });
                    },
                  ),
                  RadioListTile<KoreanLevel>(
                    title: Text(lang.translate('level_3_4')),
                    value: KoreanLevel.level34,
                    groupValue: _koreanLevel,
                    onChanged: (value) {
                      setState(() {
                        _koreanLevel = value;
                      });
                    },
                  ),
                  RadioListTile<KoreanLevel>(
                    title: Text(lang.translate('level_5_6')),
                    value: KoreanLevel.level56,
                    groupValue: _koreanLevel,
                    onChanged: (value) {
                      setState(() {
                        _koreanLevel = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Dietary Preference
              Text(
                lang.translate('dietary_preference'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _dietaryController,
                decoration: InputDecoration(
                  hintText: lang.translate('dietary_hint'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Interests
              Text(
                lang.translate('interests'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                lang.translate('select_interests'),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: InterestTags.interests.map((interest) {
                  final interestId = interest['id']!;
                  final isSelected = _selectedInterests.contains(interestId);
                  return FilterChip(
                    label: Text(interest[langCode] ?? interest['en'] ?? ''),
                    selected: isSelected,
                    onSelected: (selected) {
                      _toggleInterest(interestId);
                    },
                    selectedColor: const Color(0xFF6B4EFF).withValues(alpha: 0.3),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Visa Type
              Text(
                lang.translate('visa_type'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedVisa,
                decoration: InputDecoration(
                  hintText: lang.translate('select_visa'),
                  border: const OutlineInputBorder(),
                ),
                items: VisaData.visaTypes.map((visa) {
                  return DropdownMenuItem(
                    value: visa['id'],
                    child: Text(visa[langCode] ?? visa['en'] ?? ''),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedVisa = value;
                  });
                },
              ),
              if (_selectedVisa == 'other') ...[
                const SizedBox(height: 8),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: lang.translate('visa_type'),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    _customVisa = value;
                  },
                ),
              ],
              const SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0038A8),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  lang.translate('complete_profile'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(lang.translate('skip')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
