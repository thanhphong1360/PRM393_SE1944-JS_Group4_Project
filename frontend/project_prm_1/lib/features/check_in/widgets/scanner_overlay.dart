import 'package:flutter/material.dart';

class ScannerOverlay extends StatefulWidget {
  final Rect scanWindow;
  final double borderRadius;
  final Color borderColor;
  final double borderWidth;
  final double cornerLength;

  const ScannerOverlay({
    super.key,
    required this.scanWindow,
    this.borderRadius = 16,
    this.borderColor = const Color(0xFF2563EB),
    this.borderWidth = 4,
    this.cornerLength = 32,
  });

  @override
  State<ScannerOverlay> createState() => _ScannerOverlayState();
}

class _ScannerOverlayState extends State<ScannerOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _ScannerOverlayPainter(
            scanWindow: widget.scanWindow,
            progress: _animation.value,
            borderRadius: widget.borderRadius,
            borderColor: widget.borderColor,
            borderWidth: widget.borderWidth,
            cornerLength: widget.cornerLength,
          ),
        );
      },
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  final Rect scanWindow;
  final double progress;
  final double borderRadius;
  final Color borderColor;
  final double borderWidth;
  final double cornerLength;

  _ScannerOverlayPainter({
    required this.scanWindow,
    required this.progress,
    required this.borderRadius,
    required this.borderColor,
    required this.borderWidth,
    required this.cornerLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;

    final fullRect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      scanWindow,
      Radius.circular(borderRadius),
    );

    // Draw dark background with transparent cutout
    final backgroundPath = Path()
      ..addRect(fullRect)
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(backgroundPath, backgroundPaint);

    // Draw thin boundary line around the cutout
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(rrect, borderPaint);

    // Draw corner brackets
    final cornerPaint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final left = scanWindow.left;
    final top = scanWindow.top;
    final right = scanWindow.right;
    final bottom = scanWindow.bottom;
    final r = borderRadius;
    final cl = cornerLength;

    // Top-Left Corner
    final tlPath = Path()
      ..moveTo(left, top + cl)
      ..lineTo(left, top + r)
      ..arcToPoint(
        Offset(left + r, top),
        radius: Radius.circular(r),
      )
      ..lineTo(left + cl, top);
    canvas.drawPath(tlPath, cornerPaint);

    // Top-Right Corner
    final trPath = Path()
      ..moveTo(right - cl, top)
      ..lineTo(right - r, top)
      ..arcToPoint(
        Offset(right, top + r),
        radius: Radius.circular(r),
      )
      ..lineTo(right, top + cl);
    canvas.drawPath(trPath, cornerPaint);

    // Bottom-Left Corner
    final blPath = Path()
      ..moveTo(left, bottom - cl)
      ..lineTo(left, bottom - r)
      ..arcToPoint(
        Offset(left + r, bottom),
        radius: Radius.circular(r),
      )
      ..lineTo(left + cl, bottom);
    canvas.drawPath(blPath, cornerPaint);

    // Bottom-Right Corner
    final brPath = Path()
      ..moveTo(right - cl, bottom)
      ..lineTo(right - r, bottom)
      ..arcToPoint(
        Offset(right, bottom - r),
        radius: Radius.circular(r),
      )
      ..lineTo(right, bottom - cl);
    canvas.drawPath(brPath, cornerPaint);

    // Animated scanning laser line
    final laserY = top + (bottom - top) * progress;
    final laserPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          borderColor.withValues(alpha: 0.0),
          borderColor,
          borderColor.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(
        Rect.fromLTWH(left + 8, laserY, scanWindow.width - 16, 3),
      )
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(left + 16, laserY),
      Offset(right - 16, laserY),
      laserPaint,
    );

    // Subtle glow beneath laser
    final glowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          borderColor.withValues(alpha: 0.2),
          borderColor.withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromLTWH(left + 8, laserY - 18, scanWindow.width - 16, 20),
      );

    canvas.drawRect(
      Rect.fromLTWH(left + 16, laserY - 18, scanWindow.width - 32, 18),
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.scanWindow != scanWindow;
  }
}
