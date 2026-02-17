import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/language_service.dart';

class ProfilePhotoScreen extends StatefulWidget {
  final String userId;
  final String currentPhotoUrl;
  
  const ProfilePhotoScreen({
    super.key,
    required this.userId,
    this.currentPhotoUrl = '',
  });

  @override
  State<ProfilePhotoScreen> createState() => _ProfilePhotoScreenState();
}

class _ProfilePhotoScreenState extends State<ProfilePhotoScreen> {
  XFile? _imageFile;
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _imageFile = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    final lang = Provider.of<LanguageService>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.translate('profile_photo')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadPhoto() async {
    if (_imageFile == null) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Upload to Firebase Storage or your backend
      // For now, just simulate upload
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, _imageFile!.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('profile_photo')),
        backgroundColor: const Color(0xFF0038A8),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Photo Preview
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[200],
                    border: Border.all(
                      color: const Color(0xFF0038A8),
                      width: 3,
                    ),
                  ),
                  child: ClipOval(
                    child: _imageFile != null
                        ? (kIsWeb
                            ? Image.network(
                                _imageFile!.path,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                File(_imageFile!.path),
                                fit: BoxFit.cover,
                              ))
                        : widget.currentPhotoUrl.isNotEmpty
                            ? Image.network(
                                widget.currentPhotoUrl,
                                fit: BoxFit.cover,
                              )
                            : Icon(
                                Icons.person,
                                size: 100,
                                color: Colors.grey[400],
                              ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Pick Image Button
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _showImageSourceDialog,
                  icon: const Icon(Icons.photo_camera),
                  label: Text(_imageFile == null ? 'Select Photo' : 'Change Photo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B4EFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Upload Button
                if (_imageFile != null)
                  ElevatedButton(
                    onPressed: _isLoading ? null : _uploadPhoto,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0038A8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            lang.translate('save'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
