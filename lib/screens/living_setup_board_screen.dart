import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';
import '../screens/home_screen.dart';
import 'board_screen.dart';

class LivingSetupBoardScreen extends StatefulWidget {
  final BoardCategory category;
  
  const LivingSetupBoardScreen({
    super.key,
    required this.category,
  });

  @override
  State<LivingSetupBoardScreen> createState() => _LivingSetupBoardScreenState();
}

class _LivingSetupBoardScreenState extends State<LivingSetupBoardScreen> {
  @override
  void initState() {
    super.initState();
    // Show welcome dialog after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWelcomeDialog();
    });
  }

  void _showWelcomeDialog() {
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
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      lang.translate('living_setup_title'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0038A8),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Introduction
                    Text(
                      lang.translate('living_setup_intro'),
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[800],
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Feature 1
                    _buildFeatureItem(
                      lang.translate('living_setup_feature1_title'),
                      lang.translate('living_setup_feature1_desc'),
                    ),
                    const SizedBox(height: 16),
                    
                    // Feature 2
                    _buildFeatureItem(
                      lang.translate('living_setup_feature2_title'),
                      lang.translate('living_setup_feature2_desc'),
                    ),
                    const SizedBox(height: 16),
                    
                    // Feature 3
                    _buildFeatureItem(
                      lang.translate('living_setup_feature3_title'),
                      lang.translate('living_setup_feature3_desc'),
                    ),
                    const SizedBox(height: 32),
                    
                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            lang.translate('close'),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            // Continue to board screen content
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0038A8),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            lang.translate('start_living_setup'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureItem(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6B4EFF),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            height: 1.5,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use the regular BoardScreen for the actual content
    return BoardScreen(category: widget.category);
  }
}
