import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';

/// Widget for generating and displaying employee avatars
class AvatarGeneratorWidget extends StatelessWidget {
  final String? avatarUrl;
  final String firstName;
  final String lastName;
  final String employeeId;
  final double size;
  final VoidCallback? onAvatarTap;
  final bool showUploadOption;

  const AvatarGeneratorWidget({
    super.key,
    this.avatarUrl,
    required this.firstName,
    required this.lastName,
    required this.employeeId,
    this.size = 50.0,
    this.onAvatarTap,
    this.showUploadOption = false,
  });

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return _buildNetworkAvatar();
    } else {
      return _buildInitialsAvatar();
    }
  }

  Widget _buildNetworkAvatar() {
    return GestureDetector(
      onTap: onAvatarTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: NetworkImage(avatarUrl!),
            fit: BoxFit.cover,
            onError: (exception, stackTrace) {
              // Fallback to initials if network image fails
            },
          ),
        ),
        child: showUploadOption
            ? Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.5),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildInitialsAvatar() {
    final initials = _generateInitials();
    final backgroundColor = _generateColorFromId();

    return GestureDetector(
      onTap: onAvatarTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor,
        ),
        child: Center(
          child: Text(
            initials,
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.4,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  String _generateInitials() {
    final firstInitial = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final lastInitial = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$firstInitial$lastInitial';
  }

  Color _generateColorFromId() {
    // Generate a consistent color based on employeeId hash
    final hash = sha256.convert(utf8.encode(employeeId)).bytes;
    final hue = (hash[0] + hash[1] + hash[2]) % 360;

    return HSLColor.fromAHSL(1.0, hue.toDouble(), 0.6, 0.5).toColor();
  }

  /// Static method to generate avatar data for offline use
  static Map<String, dynamic> generateAvatarData({
    required String firstName,
    required String lastName,
    required String employeeId,
  }) {
    final initials = _staticGenerateInitials(firstName, lastName);
    final color = _staticGenerateColorFromId(employeeId);

    return {
      'initials': initials,
      'backgroundColor': color.value,
      'size': 50.0,
    };
  }

  static String _staticGenerateInitials(String firstName, String lastName) {
    final firstInitial = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final lastInitial = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$firstInitial$lastInitial';
  }

  static Color _staticGenerateColorFromId(String employeeId) {
    final hash = sha256.convert(utf8.encode(employeeId)).bytes;
    final hue = (hash[0] + hash[1] + hash[2]) % 360;
    return HSLColor.fromAHSL(1.0, hue.toDouble(), 0.6, 0.5).toColor();
  }

  /// Predefined color palette for avatars (alternative to hash-based colors)
  static const List<Color> _avatarColors = [
    Color(0xFF1E3A8A), // Blue
    Color(0xFF059669), // Green
    Color(0xFFDC2626), // Red
    Color(0xFFD97706), // Orange
    Color(0xFF7C3AED), // Purple
    Color(0xFF0891B2), // Cyan
    Color(0xFFBE123C), // Rose
    Color(0xFF0D9488), // Teal
    Color(0xFF7C2D12), // Brown
    Color(0xFF4F46E5), // Indigo
  ];

  /// Generate color using predefined palette
  static Color generateColorFromPalette(String employeeId) {
    final hash = sha256.convert(utf8.encode(employeeId)).bytes;
    final index = hash[0] % _avatarColors.length;
    return _avatarColors[index];
  }
}

/// Avatar upload dialog widget
class AvatarUploadDialog extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String employeeId;
  final Function(String? avatarUrl)? onAvatarSelected;

  const AvatarUploadDialog({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.employeeId,
    this.onAvatarSelected,
  });

  @override
  State<AvatarUploadDialog> createState() => _AvatarUploadDialogState();
}

class _AvatarUploadDialogState extends State<AvatarUploadDialog> {
  String? _selectedAvatarUrl;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Avatar'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Current avatar preview
          AvatarGeneratorWidget(
            firstName: widget.firstName,
            lastName: widget.lastName,
            employeeId: widget.employeeId,
            size: 80,
            avatarUrl: _selectedAvatarUrl,
          ),
          const SizedBox(height: 16),
          // Avatar options
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAvatarOption(
                label: 'Use Initials',
                onTap: () => _selectAvatar(null),
              ),
              _buildAvatarOption(
                label: 'Upload Photo',
                icon: Icons.photo_camera,
                onTap: _uploadFromCamera,
              ),
              _buildAvatarOption(
                label: 'Choose from Gallery',
                icon: Icons.photo_library,
                onTap: _uploadFromGallery,
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onAvatarSelected?.call(_selectedAvatarUrl);
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildAvatarOption({
    required String label,
    IconData? icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon ?? Icons.person,
              color: Theme.of(context).primaryColor,
              size: 30,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _selectAvatar(String? avatarUrl) {
    setState(() {
      _selectedAvatarUrl = avatarUrl;
    });
  }

  void _uploadFromCamera() {
    // TODO: Implement camera upload
    // For now, show a placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Camera upload not implemented yet')),
    );
  }

  void _uploadFromGallery() {
    // TODO: Implement gallery upload
    // For now, show a placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gallery upload not implemented yet')),
    );
  }
}