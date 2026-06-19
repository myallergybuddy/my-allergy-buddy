import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Configuration class for icon generation
class IconConfig {
  static const int defaultSize = 1024;
  
  // Enhanced colors with better contrast
  static const Color primaryColor = Color(0xFF2E8B8A); // Darker teal for better contrast
  static const Color secondaryColor = Color(0xFF1E7A79); // Even darker for depth
  static const Color accentColor = Color(0xFFE53E3E); // Brighter red for visibility
  static const Color backgroundColor = Colors.white;
  static const Color shadowColor = Color(0x40000000); // Subtle shadow
  
  // Barcode scanner frame dimensions - made larger and more prominent
  static const double frameSize = 500; // Increased from 400
  static const double frameStrokeWidth = 12; // Increased from 8
  static const double frameCornerRadius = 25; // Increased from 20
  static const double cornerBracketSize = 30; // Increased from 20
  
  // Medical cross dimensions - made larger and more prominent
  static const double crossCircleRadius = 60; // Increased from 40
  static const double crossVerticalWidth = 36; // Increased from 24
  static const double crossVerticalHeight = 60; // Increased from 40
  static const double crossHorizontalWidth = 66; // Increased from 44
  static const double crossHorizontalHeight = 30; // Increased from 20
  
  // Shield dimensions - made larger
  static const double shieldWidth = 180; // Increased from 136
  static const double shieldHeight = 280; // Increased from 220
  
  // Checkmark dimensions - made thicker
  static const double checkmarkStrokeWidth = 10; // Increased from 6
  
  // Barcode lines - made thicker and more prominent
  static const double barcodeLineMinWidth = 4; // Minimum width for barcode lines
  static const double barcodeLineMaxWidth = 16; // Maximum width for barcode lines
  static const double barcodeHeight = 220; // Increased from 184
  
  // Scanning line - made more prominent
  static const double scanningLineHeight = 6; // Increased from 4
}

/// Exception thrown when icon generation fails
class IconGenerationException implements Exception {
  final String message;
  final dynamic originalError;
  
  IconGenerationException(this.message, [this.originalError]);
  
  @override
  String toString() => 'IconGenerationException: $message${originalError != null ? ' (Original: $originalError)' : ''}';
}

/// A widget that displays the app icon
class IconGenerator extends StatelessWidget {
  final double size;
  
  const IconGenerator({
    super.key,
    this.size = 1024.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: IconPainter(),
      ),
    );
  }

  /// Generates and saves the app icon as a PNG file
  /// 
  /// [size] - The size of the icon to generate (default: 1024)
  /// [outputPath] - Optional custom path to save the icon
  /// 
  /// Returns the path where the icon was saved
  /// 
  /// Throws [IconGenerationException] if generation fails
  static Future<String> generateIcon({
    int size = IconConfig.defaultSize,
    String? outputPath,
  }) async {
    try {
      // Validate size
      if (size <= 0 || size > 4096) {
        throw IconGenerationException('Invalid icon size: $size. Must be between 1 and 4096.');
      }

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final center = Offset(size / 2.0, size / 2.0);
      final radius = size / 2.0;
      
      // Draw the icon
      _drawIcon(canvas, size.toDouble(), center, radius);
      
      // Convert to image
      final picture = recorder.endRecording();
      final image = await picture.toImage(size, size);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) {
        throw IconGenerationException('Failed to convert icon to PNG format');
      }
      
      final bytes = byteData.buffer.asUint8List();
      
      // Determine output path
      final String finalPath;
      if (outputPath != null) {
        finalPath = outputPath;
      } else {
        final directory = await getApplicationDocumentsDirectory();
        finalPath = '${directory.path}/app_icon_${size}x$size.png';
      }
      
      // Save to file
      final file = File(finalPath);
      await file.writeAsBytes(bytes);
      
      debugPrint('Icon saved successfully to: $finalPath');
      return finalPath;
      
    } catch (e) {
      if (e is IconGenerationException) {
        rethrow;
      }
      throw IconGenerationException('Failed to generate icon', e);
    }
  }

  /// Draws the complete icon on the canvas
  static void _drawIcon(Canvas canvas, double size, Offset center, double radius) {
    // Draw background circles
    _drawBackgroundCircles(canvas, center, radius);
    
    // Draw barcode scanner frame
    _drawBarcodeFrame(canvas, center, size);
    
    // Draw barcode lines
    _drawBarcodeLines(canvas, center, size);
    
    // Draw scanning line
    _drawScanningLine(canvas, center, size);
    
    // Draw medical cross
    _drawMedicalCross(canvas, center);
    
    // Draw safety shield
    _drawSafetyShield(canvas, center);
    
    // Draw checkmark
    _drawCheckmark(canvas, center);
  }

  /// Draws the background circles with enhanced depth
  static void _drawBackgroundCircles(Canvas canvas, Offset center, double radius) {
    final paint = Paint();
    
    // Add subtle shadow for depth
    paint.color = IconConfig.shadowColor;
    canvas.drawCircle(center, radius + 4, paint);
    
    // Outer circle (primary color) - made slightly smaller for better proportion
    paint.color = IconConfig.primaryColor;
    canvas.drawCircle(center, radius, paint);
    
    // Middle circle (secondary color) - adjusted for better visual hierarchy
    paint.color = IconConfig.secondaryColor;
    canvas.drawCircle(center, radius * 0.85, paint);
    
    // Inner circle (white background) - made larger for more content space
    paint.color = IconConfig.backgroundColor;
    canvas.drawCircle(center, radius * 0.72, paint);
  }

  /// Draws the barcode scanner frame with enhanced visibility
  static void _drawBarcodeFrame(Canvas canvas, Offset center, double size) {
    final paint = Paint()
      ..color = IconConfig.primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = IconConfig.frameStrokeWidth
      ..strokeCap = StrokeCap.round; // Rounded stroke ends
    
    final frameRect = Rect.fromCenter(
      center: center,
      width: IconConfig.frameSize,
      height: IconConfig.frameSize,
    );
    
    // Draw rounded rectangle frame with enhanced visibility
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        frameRect,
        const Radius.circular(IconConfig.frameCornerRadius),
      ),
      paint,
    );
    
    // Draw corner brackets with enhanced design
    paint.style = PaintingStyle.fill;
    final cornerSize = IconConfig.cornerBracketSize;
    final frameLeft = frameRect.left;
    final frameTop = frameRect.top;
    final frameRight = frameRect.right;
    final frameBottom = frameRect.bottom;
    
    // Enhanced corner brackets with rounded corners
    final cornerRadius = Radius.circular(cornerSize * 0.2);
    
    // Top-left corner
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(frameLeft, frameTop, cornerSize, cornerSize),
        cornerRadius,
      ),
      paint,
    );
    
    // Top-right corner
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(frameRight - cornerSize, frameTop, cornerSize, cornerSize),
        cornerRadius,
      ),
      paint,
    );
    
    // Bottom-left corner
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(frameLeft, frameBottom - cornerSize, cornerSize, cornerSize),
        cornerRadius,
      ),
      paint,
    );
    
    // Bottom-right corner
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(frameRight - cornerSize, frameBottom - cornerSize, cornerSize, cornerSize),
        cornerRadius,
      ),
      paint,
    );
  }

  /// Draws the barcode lines with enhanced visibility
  static void _drawBarcodeLines(Canvas canvas, Offset center, double size) {
    final paint = Paint()
      ..color = IconConfig.primaryColor
      ..style = PaintingStyle.fill;
    
    // Enhanced barcode line data with better proportions
    final barcodeLines = [
      [320, 6], [330, 12], [344, 4], [352, 8], [364, 5], [372, 14],
      [388, 4], [396, 10], [408, 6], [418, 12], [432, 4], [440, 8],
      [452, 5], [460, 12], [474, 4], [482, 7], [492, 5], [500, 10],
      [512, 4], [520, 12], [534, 6], [544, 8], [556, 4], [564, 12],
      [578, 5], [586, 10], [598, 4], [606, 7], [616, 12], [630, 5],
      [638, 8], [650, 4], [658, 12], [672, 6], [680, 10], [692, 4],
      [700, 8], [712, 5], [720, 12], [734, 4], [742, 10], [754, 6],
      [764, 8], [776, 4], [784, 12]
    ];
    
    final barcodeY = center.dy + 10; // Adjusted position
    final barcodeHeight = IconConfig.barcodeHeight;
    
    for (final line in barcodeLines) {
      final width = line[1].toDouble().clamp(
        IconConfig.barcodeLineMinWidth,
        IconConfig.barcodeLineMaxWidth,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            line[0].toDouble(),
            barcodeY,
            width,
            barcodeHeight,
          ),
          Radius.circular(width * 0.3), // Rounded barcode lines
        ),
        paint,
      );
    }
  }

  /// Draws the scanning line with enhanced visibility
  static void _drawScanningLine(Canvas canvas, Offset center, double size) {
    final paint = Paint()
      ..color = IconConfig.accentColor
      ..style = PaintingStyle.fill;
    
    // Enhanced scanning line with gradient effect
    final scanningRect = Rect.fromCenter(
      center: center,
      width: IconConfig.frameSize,
      height: IconConfig.scanningLineHeight,
    );
    
    // Draw main scanning line
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        scanningRect,
        Radius.circular(IconConfig.scanningLineHeight / 2),
      ),
      paint,
    );
    
    // Add glow effect
    paint.color = IconConfig.accentColor.withValues(alpha: 0.3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        scanningRect.inflate(4),
        Radius.circular((IconConfig.scanningLineHeight + 8) / 2),
      ),
      paint,
    );
  }

  /// Draws the medical cross with enhanced visibility
  static void _drawMedicalCross(Canvas canvas, Offset center) {
    final crossCenter = Offset(center.dx, center.dy - 200); // Adjusted position
    
    // Draw cross background circle with shadow
    final paint = Paint()
      ..color = IconConfig.shadowColor;
    canvas.drawCircle(crossCenter, IconConfig.crossCircleRadius + 3, paint);
    
    paint.color = IconConfig.accentColor;
    canvas.drawCircle(crossCenter, IconConfig.crossCircleRadius, paint);
    
    // Draw white cross with enhanced proportions
    paint.color = IconConfig.backgroundColor;
    
    // Vertical line with rounded corners
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: crossCenter,
          width: IconConfig.crossVerticalWidth,
          height: IconConfig.crossVerticalHeight,
        ),
        Radius.circular(IconConfig.crossVerticalWidth / 2),
      ),
      paint,
    );
    
    // Horizontal line with rounded corners
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: crossCenter,
          width: IconConfig.crossHorizontalWidth,
          height: IconConfig.crossHorizontalHeight,
        ),
        Radius.circular(IconConfig.crossHorizontalHeight / 2),
      ),
      paint,
    );
  }

  /// Draws the safety shield with enhanced design
  static void _drawSafetyShield(Canvas canvas, Offset center) {
    final shieldCenter = Offset(center.dx, center.dy - 280); // Adjusted position
    
    // Draw outer shield with shadow
    final paint = Paint()
      ..color = IconConfig.shadowColor;
    final shadowPath = Path();
    shadowPath.moveTo(shieldCenter.dx, shieldCenter.dy - 140);
    shadowPath.lineTo(shieldCenter.dx + 90, shieldCenter.dy - 110);
    shadowPath.lineTo(shieldCenter.dx + 90, shieldCenter.dy - 20);
    shadowPath.quadraticBezierTo(
      shieldCenter.dx + 90,
      shieldCenter.dy + 40,
      shieldCenter.dx,
      shieldCenter.dy + 120,
    );
    shadowPath.quadraticBezierTo(
      shieldCenter.dx - 90,
      shieldCenter.dy + 40,
      shieldCenter.dx - 90,
      shieldCenter.dy - 20,
    );
    shadowPath.lineTo(shieldCenter.dx - 90, shieldCenter.dy - 110);
    shadowPath.close();
    canvas.drawPath(shadowPath, paint);
    
    // Draw outer shield
    paint.color = IconConfig.primaryColor;
    final shieldPath = Path();
    shieldPath.moveTo(shieldCenter.dx, shieldCenter.dy - 140);
    shieldPath.lineTo(shieldCenter.dx + 90, shieldCenter.dy - 110);
    shieldPath.lineTo(shieldCenter.dx + 90, shieldCenter.dy - 20);
    shieldPath.quadraticBezierTo(
      shieldCenter.dx + 90,
      shieldCenter.dy + 40,
      shieldCenter.dx,
      shieldCenter.dy + 120,
    );
    shieldPath.quadraticBezierTo(
      shieldCenter.dx - 90,
      shieldCenter.dy + 40,
      shieldCenter.dx - 90,
      shieldCenter.dy - 20,
    );
    shieldPath.lineTo(shieldCenter.dx - 90, shieldCenter.dy - 110);
    shieldPath.close();
    canvas.drawPath(shieldPath, paint);
    
    // Draw inner shield
    paint.color = IconConfig.backgroundColor;
    final innerShieldPath = Path();
    innerShieldPath.moveTo(shieldCenter.dx, shieldCenter.dy - 130);
    innerShieldPath.lineTo(shieldCenter.dx + 80, shieldCenter.dy - 105);
    innerShieldPath.lineTo(shieldCenter.dx + 80, shieldCenter.dy - 20);
    innerShieldPath.quadraticBezierTo(
      shieldCenter.dx + 80,
      shieldCenter.dy + 35,
      shieldCenter.dx,
      shieldCenter.dy + 110,
    );
    innerShieldPath.quadraticBezierTo(
      shieldCenter.dx - 80,
      shieldCenter.dy + 35,
      shieldCenter.dx - 80,
      shieldCenter.dy - 20,
    );
    innerShieldPath.lineTo(shieldCenter.dx - 80, shieldCenter.dy - 105);
    innerShieldPath.close();
    canvas.drawPath(innerShieldPath, paint);
  }

  /// Draws the checkmark with enhanced visibility
  static void _drawCheckmark(Canvas canvas, Offset center) {
    final checkCenter = Offset(center.dx, center.dy - 180); // Adjusted position
    
    final paint = Paint()
      ..color = IconConfig.primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = IconConfig.checkmarkStrokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    
    // Enhanced checkmark path
    final checkPath = Path();
    checkPath.moveTo(checkCenter.dx - 30, checkCenter.dy + 10);
    checkPath.lineTo(checkCenter.dx - 5, checkCenter.dy + 35);
    checkPath.lineTo(checkCenter.dx + 35, checkCenter.dy - 5);
    canvas.drawPath(checkPath, paint);
    
    // Add glow effect
    paint.color = IconConfig.primaryColor.withValues(alpha: 0.3);
    paint.strokeWidth = IconConfig.checkmarkStrokeWidth + 4;
    canvas.drawPath(checkPath, paint);
  }
}

/// Custom painter for rendering the app icon
class IconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    IconGenerator._drawIcon(canvas, size.width, center, radius);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 