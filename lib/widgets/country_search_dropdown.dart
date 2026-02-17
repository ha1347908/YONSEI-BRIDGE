import 'package:flutter/material.dart';
import '../models/country_data.dart';

class CountrySearchDropdown extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<String> onCountrySelected;
  final String hintText;

  const CountrySearchDropdown({
    super.key,
    this.initialValue,
    required this.onCountrySelected,
    this.hintText = 'Select Country',
  });

  @override
  State<CountrySearchDropdown> createState() => _CountrySearchDropdownState();
}

class _CountrySearchDropdownState extends State<CountrySearchDropdown> {
  String? _selectedCountry;

  @override
  void initState() {
    super.initState();
    _selectedCountry = widget.initialValue;
  }

  Future<void> _showCountryPicker() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _CountryPickerContent(
          scrollController: scrollController,
          initialSelection: _selectedCountry,
        ),
      ),
    );

    if (result != null) {
      setState(() => _selectedCountry = result);
      widget.onCountrySelected(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _showCountryPicker,
      child: InputDecorator(
        decoration: InputDecoration(
          hintText: widget.hintText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          suffixIcon: const Icon(Icons.arrow_drop_down),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        child: Text(
          _selectedCountry ?? widget.hintText,
          style: TextStyle(
            color: _selectedCountry != null ? Colors.black87 : Colors.grey,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _CountryPickerContent extends StatefulWidget {
  final ScrollController scrollController;
  final String? initialSelection;

  const _CountryPickerContent({
    required this.scrollController,
    this.initialSelection,
  });

  @override
  State<_CountryPickerContent> createState() => _CountryPickerContentState();
}

class _CountryPickerContentState extends State<_CountryPickerContent> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredCountries = CountryData.allCountries;
  bool _showPopular = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      final query = _searchController.text;
      _filteredCountries = CountryData.filterCountries(query);
      _showPopular = query.isEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Title
              Row(
                children: [
                  const Text(
                    'Select Your Country',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0038A8).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_filteredCountries.length} countries',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF0038A8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Search field
              TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search country...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ),

        // Country list
        Expanded(
          child: _filteredCountries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text(
                        'No country found.\nPlease check the spelling.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.only(bottom: 20),
                  children: [
                    // Popular countries section
                    if (_showPopular) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          children: [
                            Icon(Icons.star, size: 20, color: Colors.orange[700]),
                            const SizedBox(width: 8),
                            const Text(
                              'Popular Countries',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...CountryData.popularCountries.map((country) {
                        return _buildCountryTile(country, isPopular: true);
                      }),
                      const Divider(height: 32, thickness: 1),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Text(
                          'All Countries',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                    
                    // All countries
                    ..._filteredCountries.map((country) {
                      return _buildCountryTile(country);
                    }),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildCountryTile(String country, {bool isPopular = false}) {
    final isSelected = country == widget.initialSelection;
    
    return ListTile(
      leading: isPopular
          ? Icon(Icons.star, color: Colors.orange[700], size: 20)
          : null,
      title: Text(
        country,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? const Color(0xFF0038A8) : Colors.black87,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Color(0xFF0038A8))
          : null,
      onTap: () => Navigator.pop(context, country),
    );
  }
}
