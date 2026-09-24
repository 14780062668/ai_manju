import 'package:flutter/material.dart';

const castCloth = <Color>[
  Color(0xFFE8C17A),
  Color(0xFF8ECAE6),
  Color(0xFFC45C6A),
  Color(0xFFF2A3C7),
];

/// 按序号区分发型，保证同一角色在分镜和角色图里长得一样。
void paintPerson(Canvas canvas, Offset foot, double scale, int index, {String? name}) {
  final cloth = castCloth[index % castCloth.length];
  final head = Offset(foot.dx, foot.dy - 78 * scale);
  final hair = Paint()..color = const Color(0xFF2A2118);
  switch (index % 4) {
    case 0:
      canvas.drawArc(
        Rect.fromCircle(center: head, radius: 18 * scale),
        3.5,
        2.5,
        true,
        hair,
      );
    case 1:
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(head.dx, head.dy + 10 * scale),
            width: 30 * scale,
            height: 50 * scale,
          ),
          Radius.circular(14 * scale),
        ),
        hair,
      );
    case 2:
      canvas.drawCircle(Offset(head.dx + 12 * scale, head.dy - 4 * scale), 9 * scale, hair);
    default:
      canvas.drawCircle(Offset(head.dx, head.dy - 18 * scale), 8 * scale, hair);
  }
  canvas.drawCircle(head, 16 * scale, Paint()..color = const Color(0xFFF3D5B5));
  final eye = Paint()..color = const Color(0xFF2A2118);
  canvas.drawCircle(Offset(head.dx - 5 * scale, head.dy), 1.7 * scale, eye);
  canvas.drawCircle(Offset(head.dx + 5 * scale, head.dy), 1.7 * scale, eye);
  final body = Path()
    ..moveTo(foot.dx - 18 * scale, foot.dy)
    ..lineTo(foot.dx + 18 * scale, foot.dy)
    ..lineTo(foot.dx + 12 * scale, foot.dy - 58 * scale)
    ..lineTo(foot.dx - 12 * scale, foot.dy - 58 * scale)
    ..close();
  canvas.drawPath(body, Paint()..color = cloth);
  if (name == null || name.isEmpty) return;
  final label = TextPainter(
    text: TextSpan(
      text: name,
      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  label.paint(canvas, Offset(foot.dx - label.width / 2, head.dy - 34 * scale));
  label.dispose();
}
