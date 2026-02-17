import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../models/country_group_model.dart';
import '../models/country_data.dart';
import '../services/language_service.dart';

class CountryGroupManagementScreen extends StatefulWidget {
  const CountryGroupManagementScreen({super.key});

  @override
  State<CountryGroupManagementScreen> createState() => _CountryGroupManagementScreenState();
}

class _CountryGroupManagementScreenState extends State<CountryGroupManagementScreen> {
  List<CountryGroup> _countryGroups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCountryGroups();
  }

  Future<void> _loadCountryGroups() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys()
          .where((key) => key.startsWith('country_group_'))
          .toList();

      final groups = <CountryGroup>[];
      for (final key in keys) {
        final jsonStr = prefs.getString(key);
        if (jsonStr != null) {
          try {
            final group = CountryGroup.fromJsonString(jsonStr);
            groups.add(group);
          } catch (e) {
            if (kDebugMode) {
              debugPrint('Error parsing country group: $e');
            }
          }
        }
      }

      // Sort by updatedAt descending (most recent first)
      groups.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      setState(() {
        _countryGroups = groups;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading country groups: $e');
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteCountryGroup(CountryGroup group) async {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(languageService.translate('confirm')),
        content: Text('${languageService.translate('delete')} "${group.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(languageService.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(languageService.translate('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('country_group_${group.id}');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${languageService.translate('deleted')}: ${group.name}')),
          );
        }
        
        await _loadCountryGroups();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error deleting country group: $e');
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('삭제 중 오류가 발생했습니다')),
          );
        }
      }
    }
  }

  void _showGroupFormDialog({CountryGroup? editGroup}) {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final nameController = TextEditingController(text: editGroup?.name ?? '');
    final selectedCountries = List<String>.from(editGroup?.countries ?? []);
    String selectedColor = editGroup?.color ?? CountryGroup.colorPalette[0];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(editGroup == null 
            ? '새 국가 그룹 만들기' 
            : '국가 그룹 편집'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Group Name
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '그룹 이름',
                    hintText: '예: 동남아시아, 유럽 국가 등',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Color Picker
                const Text(
                  '그룹 색상',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: CountryGroup.colorPalette.map((color) {
                    final isSelected = color == selectedColor;
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          selectedColor = color;
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(int.parse(color.substring(1), radix: 16) + 0xFF000000),
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.black, width: 3)
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                
                // Selected countries count
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '선택된 국가: ${selectedCountries.length}개',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final selected = await _showCountrySelectionDialog(
                          context, 
                          selectedCountries,
                        );
                        if (selected != null) {
                          setDialogState(() {
                            selectedCountries.clear();
                            selectedCountries.addAll(selected);
                          });
                        }
                      },
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('국가 선택'),
                    ),
                  ],
                ),
                
                // Selected countries chips
                if (selectedCountries.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    constraints: const BoxConstraints(maxHeight: 150),
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: selectedCountries.map((country) {
                          return Chip(
                            label: Text(
                              country,
                              style: const TextStyle(fontSize: 12),
                            ),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setDialogState(() {
                                selectedCountries.remove(country);
                              });
                            },
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(languageService.translate('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                final groupName = nameController.text.trim();
                if (groupName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('그룹 이름을 입력하세요')),
                  );
                  return;
                }
                if (selectedCountries.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('최소 1개 이상의 국가를 선택하세요')),
                  );
                  return;
                }

                final now = DateTime.now();
                final group = CountryGroup(
                  id: editGroup?.id ?? now.millisecondsSinceEpoch.toString(),
                  name: groupName,
                  countries: selectedCountries,
                  color: selectedColor,
                  createdAt: editGroup?.createdAt ?? now,
                  updatedAt: now,
                );

                try {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString(
                    'country_group_${group.id}',
                    group.toJsonString(),
                  );

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(editGroup == null 
                        ? '국가 그룹이 생성되었습니다' 
                        : '국가 그룹이 수정되었습니다')),
                    );
                  }
                  await _loadCountryGroups();
                } catch (e) {
                  if (kDebugMode) {
                    debugPrint('Error saving country group: $e');
                  }
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('저장 중 오류가 발생했습니다')),
                    );
                  }
                }
              },
              child: Text(editGroup == null ? '생성' : '저장'),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<String>?> _showCountrySelectionDialog(
    BuildContext context,
    List<String> currentSelection,
  ) async {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final searchController = TextEditingController();
    List<String> filteredCountries = List.from(CountryData.allCountries);
    final selectedCountries = Set<String>.from(currentSelection);

    return await showDialog<List<String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          void filterCountries(String query) {
            setDialogState(() {
              if (query.isEmpty) {
                filteredCountries = List.from(CountryData.allCountries);
              } else {
                filteredCountries = CountryData.allCountries
                    .where((country) =>
                        country.toLowerCase().contains(query.toLowerCase()))
                    .toList();
              }
            });
          }

          return AlertDialog(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('국가 선택'),
                    const Spacer(),
                    Text(
                      '${selectedCountries.length}개 선택됨',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: '국가 검색...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              searchController.clear();
                              filterCountries('');
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: filterCountries,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        setDialogState(() {
                          selectedCountries.addAll(filteredCountries);
                        });
                      },
                      icon: const Icon(Icons.check_box, size: 18),
                      label: const Text('전체 선택'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () {
                        setDialogState(() {
                          selectedCountries.clear();
                        });
                      },
                      icon: const Icon(Icons.clear, size: 18),
                      label: const Text('선택 해제'),
                    ),
                  ],
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: filteredCountries.isEmpty
                  ? const Center(
                      child: Text('검색 결과가 없습니다'),
                    )
                  : ListView.builder(
                      itemCount: filteredCountries.length,
                      itemBuilder: (context, index) {
                        final country = filteredCountries[index];
                        final isSelected = selectedCountries.contains(country);
                        return CheckboxListTile(
                          title: Text(country),
                          value: isSelected,
                          onChanged: (bool? value) {
                            setDialogState(() {
                              if (value == true) {
                                selectedCountries.add(country);
                              } else {
                                selectedCountries.remove(country);
                              }
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          dense: true,
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(languageService.translate('cancel')),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, selectedCountries.toList()),
                child: const Text('완료'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('즐겨찾는 국가 그룹 관리'),
        backgroundColor: const Color(0xFF0038A8),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _countryGroups.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_off_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '생성된 국가 그룹이 없습니다',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '오른쪽 하단의 + 버튼을 눌러\n새 국가 그룹을 만들어보세요',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCountryGroups,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _countryGroups.length,
                    itemBuilder: (context, index) {
                      final group = _countryGroups[index];
                      final groupColor = Color(int.parse(group.color.substring(1), radix: 16) + 0xFF000000);
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ExpansionTile(
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: groupColor,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                group.countries.length.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            group.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            '${group.countries.length}개 국가 • ${_formatDate(group.updatedAt)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          trailing: PopupMenuButton(
                            icon: const Icon(Icons.more_vert),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                child: Row(
                                  children: [
                                    const Icon(Icons.edit, size: 18),
                                    const SizedBox(width: 8),
                                    Text(languageService.translate('edit')),
                                  ],
                                ),
                                onTap: () {
                                  Future.delayed(Duration.zero, () {
                                    _showGroupFormDialog(editGroup: group);
                                  });
                                },
                              ),
                              PopupMenuItem(
                                child: Row(
                                  children: [
                                    const Icon(Icons.delete, size: 18, color: Colors.red),
                                    const SizedBox(width: 8),
                                    Text(
                                      languageService.translate('delete'),
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  Future.delayed(Duration.zero, () {
                                    _deleteCountryGroup(group);
                                  });
                                },
                              ),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: group.countries.map((country) {
                                  return Chip(
                                    label: Text(
                                      country,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    backgroundColor: groupColor.withValues(alpha: 0.1),
                                    side: BorderSide(color: groupColor.withValues(alpha: 0.3)),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showGroupFormDialog(),
        backgroundColor: const Color(0xFF0038A8),
        icon: const Icon(Icons.add),
        label: const Text('새 그룹'),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return '방금 전';
        }
        return '${difference.inMinutes}분 전';
      }
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    }
  }
}
