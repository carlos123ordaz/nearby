import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/models/profile_model.dart';

class RadarWidget extends StatefulWidget {
  const RadarWidget({
    super.key,
    required this.nearbyUsers,
    required this.isActive,
    this.onUserTap,
  });

  final List<ProfileModel> nearbyUsers;
  final bool isActive;
  final void Function(ProfileModel)? onUserTap;

  @override
  State<RadarWidget> createState() => _RadarWidgetState();
}

class _RadarWidgetState extends State<RadarWidget> with TickerProviderStateMixin {
  late AnimationController _sweepCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _orbitCtrl;

  @override
  void initState() {
    super.initState();
    _sweepCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _orbitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _sweepCtrl.dispose();
    _pulseCtrl.dispose();
    _orbitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Concentric rings
          _buildRing(radius: 130, opacity: 0.08),
          _buildRing(radius: 100, opacity: 0.12),
          _buildRing(radius: 70, opacity: 0.18),
          _buildRing(radius: 40, opacity: 0.25),

          // Radar sweep
          if (widget.isActive)
            AnimatedBuilder(
              animation: _sweepCtrl,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(260, 260),
                  painter: _RadarSweepPainter(
                    angle: _sweepCtrl.value * 2 * math.pi,
                    color: AppColors.accent,
                  ),
                );
              },
            ),

          // Pulse rings
          if (widget.isActive)
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(260, 260),
                  painter: _PulseRingPainter(
                    progress: _pulseCtrl.value,
                    color: AppColors.accent,
                  ),
                );
              },
            ),

          // Orbiting user avatars
          ...widget.nearbyUsers.take(6).toList().asMap().entries.map((entry) {
            final index = entry.key;
            final user = entry.value;
            final orbitRadius = 60.0 + (index % 3) * 30.0;
            final angleOffset = (index / 6) * 2 * math.pi;

            return AnimatedBuilder(
              animation: _orbitCtrl,
              builder: (context, child) {
                final angle = _orbitCtrl.value * 2 * math.pi + angleOffset;
                final x = math.cos(angle) * orbitRadius;
                final y = math.sin(angle) * orbitRadius;
                return Transform.translate(
                  offset: Offset(x, y),
                  child: GestureDetector(
                    onTap: () => widget.onUserTap?.call(user),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.accent, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withOpacity(0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: AppAvatar(
                        name: user.displayName,
                        imageUrl: user.avatarUrl,
                        size: AvatarSize.sm,
                      ),
                    ),
                  ),
                );
              },
            );
          }),

          // Center dot (self)
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: widget.isActive ? AppColors.accent : AppColors.darkTextFaint,
              shape: BoxShape.circle,
              boxShadow: widget.isActive
                  ? [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.6),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
          ),

          // Crosshair lines
          CustomPaint(
            size: const Size(260, 260),
            painter: _CrosshairPainter(color: AppColors.accent.withOpacity(0.1)),
          ),
        ],
      ),
    );
  }

  Widget _buildRing({required double radius, required double opacity}) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.accent.withOpacity(opacity),
          width: 1,
        ),
      ),
    );
  }
}

class _RadarSweepPainter extends CustomPainter {
  const _RadarSweepPainter({required this.angle, required this.color});
  final double angle;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: angle - 0.8,
        endAngle: angle,
        colors: [Colors.transparent, color.withOpacity(0.3)],
        tileMode: TileMode.clamp,
        transform: GradientRotation(angle - 0.8),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, sweepPaint);

    // Sweep line
    final linePaint = Paint()
      ..color = color.withOpacity(0.7)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      center,
      Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      ),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RadarSweepPainter oldDelegate) => true;
}

class _PulseRingPainter extends CustomPainter {
  const _PulseRingPainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / 2;

    final paint = Paint()
      ..color = color.withOpacity((1 - progress) * 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawCircle(center, progress * maxRadius, paint);
  }

  @override
  bool shouldRepaint(covariant _PulseRingPainter oldDelegate) => true;
}

class _CrosshairPainter extends CustomPainter {
  const _CrosshairPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CrosshairPainter oldDelegate) => false;
}
