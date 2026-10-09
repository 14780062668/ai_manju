import 'package:flutter/material.dart';

import 'package:ai_manju/domain/manju.dart';
import 'package:ai_manju/ui/widgets/character_portrait.dart';

class CastPage extends StatelessWidget {
  const CastPage({super.key, required this.episode});

  final ManjuEpisode episode;

  @override
  Widget build(BuildContext context) {
    final accent = Color(episode.style.accent);
    final cast = episode.characters.where((name) => name != '旁白').toList();
    return Scaffold(
      appBar: AppBar(title: Text('${episode.title} · 角色')),
      body: SafeArea(
        child: cast.isEmpty
            ? const Center(child: Text('这一部还没有认出角色', style: TextStyle(color: Colors.white38)))
            : GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.62,
                ),
                itemCount: cast.length,
                itemBuilder: (context, index) {
                  final name = cast[index];
                  final lines = episode.panels.where((p) => p.speaker == name && p.line.isNotEmpty).length;
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFF17171C),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accent.withValues(alpha: 0.35)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Expanded(child: CharacterPortrait(name: name, index: index, style: episode.style)),
                          const SizedBox(height: 4),
                          Text('$lines 句台词', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
