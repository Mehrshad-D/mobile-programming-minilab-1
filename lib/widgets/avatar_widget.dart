import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/constants.dart';

typedef AvatarPickedCallback = void Function(File image);

/// Reusable avatar widget with tap-to-upload functionality
class AvatarWidget extends StatelessWidget {
  final String? avatarUrl;
  final String initials;
  final bool isEditable;
  final AvatarPickedCallback? onImagePicked;
  final double radius;
  final Color? backgroundColor;

  const AvatarWidget({
    super.key,
    required this.initials,
    this.avatarUrl,
    this.isEditable = false,
    this.onImagePicked,
    this.radius = 40,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        _buildAvatar(),
        if (isEditable) _buildEditIcon(context),
      ],
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? AppColors.primary.withValues(alpha: 0.12),
      child: avatarUrl != null
          ? ClipOval(child: _buildAvatarImage(avatarUrl!))
          : _buildInitials(),
    );
  }

  /// Renders either a remote URL or a locally-picked file. The mock upload
  /// stores the picked image's local path (it can't serve a real URL), so we
  /// must use [Image.file] for non-http values.
  Widget _buildAvatarImage(String source) {
    final size = radius * 2;
    final isRemote = source.startsWith('http');
    if (isRemote) {
      return Image.network(
        source,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildInitials(),
      );
    }
    return Image.file(
      File(source),
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildInitials(),
    );
  }

  Widget _buildInitials() {
    return Text(
      initials,
      style: TextStyle(
        fontSize: radius * 0.8,
        color: AppColors.primary,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildEditIcon(BuildContext context) {
    return GestureDetector(
      onTap: () => _showImagePickerOptions(context),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: const Icon(
          Icons.camera_alt,
          size: 16,
          color: Colors.white,
        ),
      ),
    );
  }

  void _showImagePickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text(
              'تغییر عکس پروفایل',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('انتخاب از گالری'),
              onTap: () => _pickImage(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('گرفتن عکس با دوربین'),
              onTap: () => _pickImage(context, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    Navigator.pop(context);
    
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    
    if (pickedFile != null && onImagePicked != null) {
      onImagePicked!(File(pickedFile.path));
    }
  }
}