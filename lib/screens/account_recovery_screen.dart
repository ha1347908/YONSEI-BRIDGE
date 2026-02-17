import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';
import 'package:url_launcher/url_launcher.dart';

class AccountRecoveryScreen extends StatelessWidget {
  const AccountRecoveryScreen({super.key});

  Future<void> _contactAdmin() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'admin@yonseibridge.com',
      query: 'subject=Account Recovery Request',
    );
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('account_recovery')),
        backgroundColor: const Color(0xFF0038A8),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0038A8).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_reset,
                    size: 60,
                    color: Color(0xFF0038A8),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Title
              Text(
                lang.translate('account_recovery_title'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0038A8),
                ),
              ),
              const SizedBox(height: 16),
              
              // Description
              Text(
                lang.translate('account_recovery_desc'),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 32),
              
              // Step 1
              _buildRecoveryStep(
                context,
                '1',
                lang.translate('recovery_step1'),
                lang.translate('recovery_step1_desc'),
                Icons.email,
                const Color(0xFF0038A8),
              ),
              const SizedBox(height: 24),
              
              // Step 2
              _buildRecoveryStep(
                context,
                '2',
                lang.translate('recovery_step2'),
                lang.translate('recovery_step2_desc'),
                Icons.badge,
                const Color(0xFF6B4EFF),
              ),
              const SizedBox(height: 24),
              
              // Step 3
              _buildRecoveryStep(
                context,
                '3',
                lang.translate('recovery_step3'),
                lang.translate('recovery_step3_desc'),
                Icons.check_circle,
                const Color(0xFF4CAF50),
              ),
              const SizedBox(height: 48),
              
              // Contact Button
              Center(
                child: ElevatedButton.icon(
                  onPressed: _contactAdmin,
                  icon: const Icon(Icons.mail_outline),
                  label: Text(
                    lang.translate('contact_admin'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0038A8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecoveryStep(
    BuildContext context,
    String stepNumber,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step Number Circle
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
        const SizedBox(width: 16),
        
        // Step Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
