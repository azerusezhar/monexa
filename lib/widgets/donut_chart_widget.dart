import 'package:flutter/material.dart';
import 'dart:math' as math;

class DonutChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> segments;
  final String centerText;
  final double strokeWidth;
  final List<Color> segmentColors;

  const DonutChartWidget({
    super.key,
    required this.segments,
    required this.centerText,
    this.strokeWidth = 24.0,
    this.segmentColors = const [
      Color(0xFF2ECC71), // Green (Income)
      Color(0xFFE74C3C), // Red (Expense)
      Color(0xFF7F3DFF), // Purple (Default)
    ],
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        size: const Size.square(double.infinity),
        painter: DonutChartPainter(
          segments: segments,
          strokeWidth: strokeWidth,
          segmentColors: segmentColors,
        ),
      ),
    );
  }
}

class DonutChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> segments;
  final double strokeWidth;
  final List<Color> segmentColors;

  DonutChartPainter({
    required this.segments,
    required this.strokeWidth,
    required this.segmentColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final totalValue = segments.fold<double>(
      0,
      (sum, segment) => sum + (segment['amount'] as num).toDouble(),
    );

    if (totalValue <= 0) {
      // If no data, draw an empty circle
      final paint =
          Paint()
            ..color = Colors.grey.withOpacity(0.2)
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth;

      canvas.drawCircle(center, radius, paint);
      return;
    }

    double startAngle = -math.pi / 2; // Start from the top

    for (int i = 0; i < segments.length; i++) {
      final segmentValue = (segments[i]['amount'] as num).toDouble();
      final sweepAngle = 2 * math.pi * (segmentValue / totalValue);

      // Check if segment has a custom color defined
      Color segmentColor;
      if (segments[i].containsKey('color')) {
        segmentColor = segments[i]['color'] as Color;
      } else {
        segmentColor =
            i < segmentColors.length ? segmentColors[i] : segmentColors.last;
      }

      final paint =
          Paint()
            ..color = segmentColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(DonutChartPainter oldDelegate) {
    return segments != oldDelegate.segments ||
        strokeWidth != oldDelegate.strokeWidth ||
        segmentColors != oldDelegate.segmentColors;
  }
}
