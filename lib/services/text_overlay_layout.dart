// Shared text overlay layout math for screen and export paths.
import 'package:flutter/material.dart';

/// Immutable layout result for one text overlay.
class TextOverlayLayoutResult {
  const TextOverlayLayoutResult({
    required this.linePainters,
    required this.fontSize,
    required this.lineHeight,
    required this.left,
    required this.top,
    required this.boxWidth,
    required this.boxHeight,
    required this.textOffsetX,
    required this.textOffsetY,
  });

  final List<TextPainter> linePainters;
  final double fontSize;
  final double lineHeight;
  final double left;
  final double top;
  final double boxWidth;
  final double boxHeight;
  final double textOffsetX;
  final double textOffsetY;
}

/// Shared overlay layout engine.
class TextOverlayLayout {
  TextOverlayLayout._();

  static const double horizontalPadding = 6;
  static const double verticalPadding = 3;
  static const double minVisiblePx = 4;

  /// Computes text painter, box size, and clamped top-left coordinates.
  static TextOverlayLayoutResult compute({
    required String text,
    required int textColor,
    required double scale,
    required double normalizedX,
    required double normalizedY,
    required double frameWidth,
    required double frameHeight,
    double? referenceFrameWidth,
    Locale? locale,
  }) {
    final referenceWidth = (referenceFrameWidth == null || referenceFrameWidth <= 0)
        ? frameWidth
        : referenceFrameWidth;
    final frameScale = frameWidth / referenceWidth;
    final hPad = horizontalPadding * frameScale;
    final vPad = verticalPadding * frameScale;
    final minVisible = minVisiblePx * frameScale;

    final fontSize = (frameWidth * 0.04) * scale;
    final textStyle = TextStyle(
      color: Color(textColor),
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      fontFamily: 'Roboto',
    );
    final rows = text.split('\n');
    final lines = rows.isEmpty ? const [''] : rows;
    final linePainters = <TextPainter>[];
    double maxLineWidth = 0;
    double lineHeight = 0;
    for (final line in lines) {
      final painter = TextPainter(
        text: TextSpan(text: line.isEmpty ? ' ' : line, style: textStyle),
        textDirection: TextDirection.ltr,
        locale: locale,
        maxLines: 1,
      )..layout();
      linePainters.add(painter);
      if (painter.size.width > maxLineWidth) maxLineWidth = painter.size.width;
      if (painter.preferredLineHeight > lineHeight) {
        lineHeight = painter.preferredLineHeight;
      }
    }
    final contentHeight = lineHeight * linePainters.length;
    final boxWidth = maxLineWidth + (hPad * 2);
    final boxHeight = contentHeight + (vPad * 2);
    final textOffsetX = hPad;
    final textOffsetY = vPad;

    final xRaw = normalizedX * frameWidth;
    final yRaw = normalizedY * frameHeight;
    final minLeft = -(boxWidth - minVisible);
    final maxLeft = frameWidth - minVisible;
    final minTop = -(boxHeight - minVisible);
    final maxTop = frameHeight - minVisible;
    final left = xRaw.clamp(minLeft, maxLeft);
    final top = yRaw.clamp(minTop, maxTop);

    return TextOverlayLayoutResult(
      linePainters: linePainters,
      fontSize: fontSize,
      lineHeight: lineHeight,
      left: left,
      top: top,
      boxWidth: boxWidth,
      boxHeight: boxHeight,
      textOffsetX: textOffsetX,
      textOffsetY: textOffsetY,
    );
  }

}

/// Paints text overlay box exactly like export pipeline.
class TextOverlayBoxPainter extends CustomPainter {
  const TextOverlayBoxPainter({
    required this.layout,
    required this.bgColor,
  });

  final TextOverlayLayoutResult layout;
  final int? bgColor;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = bgColor == null ? null : (Paint()..color = Color(bgColor!));
    if (bg != null) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, layout.boxWidth, layout.boxHeight),
        bg,
      );
    }
    for (var i = 0; i < layout.linePainters.length; i++) {
      layout.linePainters[i].paint(
        canvas,
        Offset(layout.textOffsetX, layout.textOffsetY + (layout.lineHeight * i)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant TextOverlayBoxPainter oldDelegate) {
    return oldDelegate.layout != layout || oldDelegate.bgColor != bgColor;
  }
}
