import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;

/// Privacy Screen Mask Service
/// Automatically shows a privacy mask when app goes to background
/// to prevent sensitive data from being visible in app switcher/screenshots
class PrivacyScreenService {
  static final PrivacyScreenService _instance = PrivacyScreenService._internal();
  
  factory PrivacyScreenService() => _instance;
  
  PrivacyScreenService._internal();
  
  static const platform = MethodChannel('com.campusbridge.campus_bridge/security');
  
  OverlayEntry? _overlayEntry;
  bool _isShowing = false;
  bool _isNativeProtectionEnabled = false;
  
  /// Initialize privacy screen observer
  /// Call this in main.dart to enable automatic privacy masking
  Future<void> initialize(BuildContext context) async {
    // Enable native privacy protection on Android
    if (Platform.isAndroid) {
      await enableNativeProtection();
    }
  }
  
  /// Enable native privacy protection (Android only)
  /// Prevents screenshots and screen recording at system level
  Future<bool> enableNativeProtection() async {
    if (!Platform.isAndroid) return false;
    
    try {
      final result = await platform.invokeMethod('enablePrivacyProtection');
      _isNativeProtectionEnabled = result == true;
      return _isNativeProtectionEnabled;
    } catch (e) {
      return false;
    }
  }
  
  /// Disable native privacy protection (Android only)
  /// Use with caution - only disable if specifically needed
  Future<bool> disableNativeProtection() async {
    if (!Platform.isAndroid) return false;
    
    try {
      final result = await platform.invokeMethod('disablePrivacyProtection');
      _isNativeProtectionEnabled = !(result == true);
      return result == true;
    } catch (e) {
      return false;
    }
  }
  
  /// Show privacy mask overlay
  void showPrivacyMask(BuildContext context) {
    if (_isShowing) return;
    
    _overlayEntry = OverlayEntry(
      builder: (context) => _buildPrivacyMask(context),
    );
    
    Overlay.of(context).insert(_overlayEntry!);
    _isShowing = true;
  }
  
  /// Hide privacy mask overlay
  void hidePrivacyMask() {
    if (!_isShowing) return;
    
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isShowing = false;
  }
  
  /// Build privacy mask widget
  Widget _buildPrivacyMask(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF003366), // Yonsei Blue
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo container
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Image.asset(
                'assets/images/yonsei_bridge_logo.png',
                width: 150,
                height: 150,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback if logo is not available
                  return const Icon(
                    Icons.school,
                    size: 150,
                    color: Color(0xFF003366),
                  );
                },
              ),
            ),
            const SizedBox(height: 30),
            // App name
            const Text(
              'YONSEI BRIDGE',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 10),
            // Subtitle
            Text(
              'Privacy Protected',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Dispose resources
  void dispose() {
    hidePrivacyMask();
  }
}
