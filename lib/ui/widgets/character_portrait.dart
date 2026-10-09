import 'package:flutter/material.dart';

import 'package:ai_manju/domain/manju.dart';
import 'package:ai_manju/ui/widgets/person_painter.dart';

class CharacterPortrait extends StatelessWidget {
  const CharacterPortrait({super.key, required this.name, required this.index, required this.style});

  final String name;
  final int index;
  final ManjuStyle style;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CustomPaint(
              painter: _PortraitPainter(style: style, index: index),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

class _PortraitPainter extends CustomPainter {
  _PortraitPainter({required this.style, required this.index});

  final ManjuStyle style;
  final int index;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(style.skyTop), Color(style.skyBottom)],
        ).createShader(rect),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.78, size.width, size.height * 0.22),
      Paint()..color = const Color(0xFF0C0C0F).withValues(alpha: 0.45),
    );
    paintPerson(canvas, Offset(size.width / 2, size.height * 0.9), size.width / 150, index);
  }

  @override
  bool shouldRepaint(covariant _PortraitPainter oldDelegate) {
    return oldDelegate.index != index || oldDelegate.style != style;
  }
}
