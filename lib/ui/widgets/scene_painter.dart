import 'package:flutter/material.dart';

import 'package:ai_manju/domain/manju.dart';
import 'package:ai_manju/ui/widgets/person_painter.dart';

class ScenePainter extends CustomPainter {
  ScenePainter({
    required this.panel,
    required this.style,
    required this.characters,
    this.showNames = true,
  });

  final ManjuPanel panel;
  final ManjuStyle style;
  final List<String> characters;

  /// 缩略图不画人名，避免小图上文字糊在一起。
  final bool showNames;

  @override
  void paint(Canvas canvas, Size size) {
    final sky = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(
      sky,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(style.skyTop), Color(style.skyBottom)],
        ).createShader(sky),
    );

    final groundY = size.height * 0.72;
    canvas.drawRect(
      Rect.fromLTWH(0, groundY, size.width, size.height - groundY),
      Paint()..color = const Color(0xFF0C0C0F).withValues(alpha: 0.55),
    );

    _drawScenery(canvas, size, groundY);
    if (panel.location.contains('雨') || panel.visual.contains('雨')) {
      _drawRain(canvas, size);
    } else {
      canvas.drawCircle(
        Offset(size.width * 0.78, size.height * 0.16),
        18,
        Paint()..color = const Color(0xFFFFF3D0).withValues(alpha: 0.85),
      );
    }
    _drawCast(canvas, size, groundY);
  }

  void _drawScenery(Canvas canvas, Size size, double groundY) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.28);
    switch (style) {
      case ManjuStyle.ancient:
        for (var i = 0; i < 3; i++) {
          final x = size.width * (0.08 + i * 0.3);
          final w = size.width * 0.24;
          final h = 46.0 + i * 10;
          final roof = Path()
            ..moveTo(x, groundY)
            ..lineTo(x + w, groundY)
            ..lineTo(x + w, groundY - h)
            ..lineTo(x + w / 2, groundY - h - 26)
            ..lineTo(x, groundY - h)
            ..close();
          canvas.drawPath(roof, paint);
        }
      case ManjuStyle.city:
        for (var i = 0; i < 4; i++) {
          final w = size.width * 0.16;
          final h = 70.0 + (i % 3) * 36;
          final x = size.width * (0.06 + i * 0.24);
          canvas.drawRect(Rect.fromLTWH(x, groundY - h, w, h), paint);
        }
      case ManjuStyle.suspense:
        canvas.drawCircle(Offset(size.width * 0.3, groundY - 20), 50, paint);
        canvas.drawCircle(Offset(size.width * 0.62, groundY - 10), 70, paint);
      case ManjuStyle.sweet:
        canvas.drawCircle(
          Offset(size.width * 0.22, size.height * 0.22),
          28,
          Paint()..color = Color(style.accent).withValues(alpha: 0.35),
        );
        canvas.drawCircle(
          Offset(size.width * 0.7, size.height * 0.3),
          18,
          Paint()..color = Colors.white.withValues(alpha: 0.18),
        );
    }
  }

  void _drawRain(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1.2;
    for (var i = 0; i < 36; i++) {
      final x = ((i * 47 + panel.index * 13) % size.width.toInt()).toDouble();
      final y = ((i * 29) % (size.height * 0.7).toInt()).toDouble();
      canvas.drawLine(Offset(x, y), Offset(x - 6, y + 16), paint);
    }
  }

  /// 景别只改人物大小。特写只留正在说话的人，说话人尽量站中间。
  void _drawCast(Canvas canvas, Size size, double groundY) {
    final cast = characters.where((name) => name != '旁白').toList();
    if (cast.isEmpty) return;
    final speakerIndex = cast.indexOf(panel.speaker);
    final visible = <int>[];
    if (speakerIndex >= 0) visible.add(speakerIndex);
    for (var i = 0; i < cast.length && visible.length < 3; i++) {
      if (!visible.contains(i)) visible.add(i);
    }
    final closeup = panel.shot == '特写' && speakerIndex >= 0;
    final indexes = closeup ? [speakerIndex] : visible;
    if (!closeup && speakerIndex >= 0 && indexes.length > 1) {
      indexes.remove(speakerIndex);
      indexes.insert(indexes.length ~/ 2, speakerIndex);
    }
    final shotScale = switch (panel.shot) {
      '特写' => 1.55,
      '近景' => 1.15,
      '远景' => 0.62,
      _ => 1.0,
    };
    final slots = switch (indexes.length) {
      1 => const [0.5],
      2 => const [0.34, 0.66],
      _ => const [0.22, 0.5, 0.78],
    };
    for (var n = 0; n < indexes.length; n++) {
      final i = indexes[n];
      final highlighted = speakerIndex < 0 ? n == 0 : i == speakerIndex;
      paintPerson(
        canvas,
        Offset(size.width * slots[n], groundY + 8),
        highlighted ? shotScale : shotScale * 0.72,
        i,
        name: showNames ? cast[i] : null,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ScenePainter oldDelegate) {
    final previous = oldDelegate.panel;
    return previous.index != panel.index ||
        previous.shot != panel.shot ||
        previous.speaker != panel.speaker ||
        previous.location != panel.location ||
        oldDelegate.style != style ||
        oldDelegate.showNames != showNames;
  }
}
