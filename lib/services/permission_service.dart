import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class PermissionService {
  /// Request notification permission
  static Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Request location permission
  static Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  /// Request all required permissions with user-friendly dialogs
  static Future<void> requestAllPermissions(BuildContext context) async {
    // Request Notification Permission
    final notificationGranted = await Permission.notification.status;
    if (!notificationGranted.isGranted) {
      final shouldRequest = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('알림 권한 필요'),
          content: const Text(
            '리빙셋업 및 중요한 공지사항 알림을 받으시려면 알림 권한이 필요합니다.\n\n'
            '알림 권한을 허용하시겠습니까?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('나중에'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0038A8),
                foregroundColor: Colors.white,
              ),
              child: const Text('허용'),
            ),
          ],
        ),
      );

      if (shouldRequest == true) {
        await Permission.notification.request();
      }
    }

    // Request Location Permission
    final locationGranted = await Permission.location.status;
    if (!locationGranted.isGranted) {
      final shouldRequest = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('위치 권한 필요'),
          content: const Text(
            '주변 병원, 식당 등의 정보를 제공받으시려면 위치 권한이 필요합니다.\n\n'
            '위치 권한을 허용하시겠습니까?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('나중에'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0038A8),
                foregroundColor: Colors.white,
              ),
              child: const Text('허용'),
            ),
          ],
        ),
      );

      if (shouldRequest == true) {
        await Permission.location.request();
      }
    }
  }

  /// Check if notification permission is granted
  static Future<bool> isNotificationPermissionGranted() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// Check if location permission is granted
  static Future<bool> isLocationPermissionGranted() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  /// Open app settings
  static Future<void> openSettings() async {
    await openAppSettings();
  }
}
