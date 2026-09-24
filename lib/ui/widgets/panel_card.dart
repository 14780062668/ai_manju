import 'package:flutter/material.dart';

import 'package:ai_manju/domain/manju.dart';
import 'package:ai_manju/ui/widgets/scene_painter.dart';

class PanelCard extends StatelessWidget {
  const PanelCard({super.key, required this.panel, required this.episode});

  final ManjuPanel panel;
  final ManjuEpisode episode;

  @override
  Widget build(BuildContext context) {
    final accent = Color(episode.style.accent);
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF17171C),
          border: Border.all(color: accent.withValues(alpha: 0.45)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: ScenePainter(
                panel: panel,
                style: episode.style,
                characters: episode.characters,
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x66000000), Color(0x00000000), Color(0xE6000000)],
                  stops: [0, 0.42, 1],
                ),
              ),
            ),
            Positioned(
              left: 14,
              top: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '第${panel.index}镜 · ${panel.shot} · ${panel.location}',
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (panel.narration.isNotEmpty)
                    Text(
                      panel.narration,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, height: 1.35, color: Colors.white70),
                    ),
                  if (panel.line.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              panel.speaker,
                              style: TextStyle(fontSize: 12, color: accent, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              panel.line,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 18, height: 1.35, color: Color(0xFF1A1A1A)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
