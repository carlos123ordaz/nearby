import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

enum AvatarSize { sm, md, lg, xl }

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = AvatarSize.md,
    this.showOnline = false,
    this.isOnline = false,
    this.onTap,
  });

  final String? imageUrl;
  final String name;
  final AvatarSize size;
  final bool showOnline;
  final bool isOnline;
  final VoidCallback? onTap;

  double get _diameter => switch (size) {
        AvatarSize.sm => 32,
        AvatarSize.md => 44,
        AvatarSize.lg => 60,
        AvatarSize.xl => 88,
      };

  double get _fontSize => switch (size) {
        AvatarSize.sm => 12,
        AvatarSize.md => 16,
        AvatarSize.lg => 22,
        AvatarSize.xl => 32,
      };

  double get _indicatorSize => switch (size) {
        AvatarSize.sm => 8,
        AvatarSize.md => 10,
        AvatarSize.lg => 13,
        AvatarSize.xl => 16,
      };

  List<Color> _gradientColors() {
    final idx = name.isEmpty ? 0 : name.codeUnitAt(0) % AppColors.avatarGradients.length;
    return AppColors.avatarGradients[idx];
  }

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].isEmpty ? '?' : parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          _buildAvatar(),
          if (showOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: _indicatorSize,
                height: _indicatorSize,
                decoration: BoxDecoration(
                  color: isOnline ? AppColors.success : AppColors.darkTextFaint,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: _diameter,
          height: _diameter,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildGradientAvatar(),
          errorWidget: (context, url, error) => _buildGradientAvatar(),
        ),
      );
    }
    return _buildGradientAvatar();
  }

  Widget _buildGradientAvatar() {
    final colors = _gradientColors();
    return Container(
      width: _diameter,
      height: _diameter,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _initials,
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: _fontSize,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
