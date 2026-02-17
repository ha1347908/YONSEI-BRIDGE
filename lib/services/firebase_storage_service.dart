import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class FirebaseStorageService extends ChangeNotifier {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Upload profile photo to Firebase Storage
  Future<String?> uploadProfilePhoto(String userId, XFile imageFile) async {
    try {
      // Create a reference to the file location
      final String fileName = 'profile_$userId${path.extension(imageFile.name)}';
      final Reference ref = _storage.ref().child('profile_photos').child(fileName);

      // Upload the file
      final UploadTask uploadTask;
      if (kIsWeb) {
        // For web, use putData
        final bytes = await imageFile.readAsBytes();
        uploadTask = ref.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        // For mobile, use putFile
        uploadTask = ref.putFile(File(imageFile.path));
      }

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      if (kDebugMode) {
        debugPrint('✅ Profile photo uploaded successfully: $downloadUrl');
      }

      notifyListeners();
      return downloadUrl;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error uploading profile photo: $e');
      }
      return null;
    }
  }

  // Delete profile photo from Firebase Storage
  Future<bool> deleteProfilePhoto(String photoUrl) async {
    try {
      // Extract file path from URL
      final ref = _storage.refFromURL(photoUrl);
      await ref.delete();

      if (kDebugMode) {
        debugPrint('✅ Profile photo deleted successfully');
      }

      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error deleting profile photo: $e');
      }
      return false;
    }
  }

  // Pick image from gallery
  Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error picking image: $e');
      }
      return null;
    }
  }

  // Take photo with camera
  Future<XFile?> takePhotoWithCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error taking photo: $e');
      }
      return null;
    }
  }

  // Upload post image to Firebase Storage
  Future<String?> uploadPostImage(String userId, XFile imageFile) async {
    try {
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = 'post_${userId}_$timestamp${path.extension(imageFile.name)}';
      final Reference ref = _storage.ref().child('post_images').child(fileName);

      final UploadTask uploadTask;
      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        uploadTask = ref.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        uploadTask = ref.putFile(File(imageFile.path));
      }

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      if (kDebugMode) {
        debugPrint('✅ Post image uploaded successfully: $downloadUrl');
      }

      notifyListeners();
      return downloadUrl;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error uploading post image: $e');
      }
      return null;
    }
  }

  // Upload notification image to Firebase Storage (for admin)
  Future<String?> uploadNotificationImage(XFile imageFile) async {
    try {
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = 'notification_$timestamp${path.extension(imageFile.name)}';
      final Reference ref = _storage.ref().child('notification_images').child(fileName);

      final UploadTask uploadTask;
      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        uploadTask = ref.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        uploadTask = ref.putFile(File(imageFile.path));
      }

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      if (kDebugMode) {
        debugPrint('✅ Notification image uploaded successfully: $downloadUrl');
      }

      notifyListeners();
      return downloadUrl;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error uploading notification image: $e');
      }
      return null;
    }
  }
}
