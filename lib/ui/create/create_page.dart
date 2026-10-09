import 'package:flutter/material.dart';

import 'package:ai_manju/app/routes.dart';
import 'package:ai_manju/data/episode_store.dart';
import 'package:ai_manju/data/script_generator.dart';
import 'package:ai_manju/domain/manju.dart';
import 'package:ai_manju/ui/widgets/scene_painter.dart';

class CreatePage extends StatefulWidget {
  const CreatePage({super.key});

  @override
  State<CreatePage> createState() => _CreatePageState();
}

class _CreatePageState extends State<CreatePage> {
  final _controller = TextEditingController();
  final _length = ValueNotifier(0);
  final _generator = ScriptGenerator();
  static const _prompts = <(String, String)>[
    ('茶馆送信', '雨夜林晚到茶馆送信，黑衣人来抢'),
    ('校门口', '放学后林夏在校门口等陈舟'),
    ('会上拆穿', '周宁在会上当面拆穿同事'),
  ];

  var _style = ManjuStyle.ancient;
  var _saved = <ManjuEpisode>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _length.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _fill(String text) {
    _controller.text = text;
    _length.value = text.trim().length;
  }

  Future<void> _load() async {
    final items = await EpisodeStore.load();
    if (!mounted) return;
    setState(() => _saved = items);
  }

  Future<void> _open(ManjuEpisode episode) async {
    final edited = await Navigator.of(context).push(ManjuRoutes.player(episode));
    if (!mounted || edited == null || edited.isEmpty) return;
    setState(() => _controller.text = edited);
  }

  Future<void> _generate() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final story = _controller.text.trim();
    if (story.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('先写一句故事描述')));
      return;
    }
    final episode = _generator.generate(story: story, style: _style);
    try {
      await EpisodeStore.save(episode);
      if (mounted) {
        setState(() {
          _saved.removeWhere((item) => item.id == episode.id);
          _saved.insert(0, episode);
        });
      }
    } catch (_) {}
    if (!mounted) return;
    await _open(episode);
  }

  Future<void> _remove(ManjuEpisode episode) async {
    setState(() => _saved.removeWhere((item) => item.id == episode.id));
    await EpisodeStore.remove(episode.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已删除「${episode.title}」'),
        action: SnackBarAction(
          label: '撤销',
          onPressed: () async {
            await EpisodeStore.save(episode);
            if (!mounted) return;
            setState(() {
              _saved.removeWhere((item) => item.id == episode.id);
              _saved.insert(0, episode);
            });
          },
        ),
      ),
    );
  }

  String _when(int ms) {
    final time = DateTime.fromMillisecondsSinceEpoch(ms);
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '${time.month}/${time.day} $hour:$minute';
  }

  IconData _styleIcon(ManjuStyle style) {
    return switch (style) {
      ManjuStyle.ancient => Icons.temple_buddhist,
      ManjuStyle.city => Icons.location_city,
      ManjuStyle.suspense => Icons.nightlight_round,
      ManjuStyle.sweet => Icons.favorite,
    };
  }

  /// 作品卡片左侧的首镜缩略图。
  Widget _thumb(ManjuEpisode episode) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 44,
        height: 78,
        child: CustomPaint(
          painter: ScenePainter(
            panel: episode.panels.first,
            style: episode.style,
            characters: episode.characters,
            showNames: false,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = Color(_style.accent);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              children: [
                const Text('AI漫剧', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                const Text('写一句描述，自动生成可播放的竖屏漫剧', style: TextStyle(color: Colors.white54)),
                const SizedBox(height: 20),
                SizedBox(
                  height: 92,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: ManjuStyle.values.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final style = ManjuStyle.values[index];
                      final selected = style == _style;
                      return GestureDetector(
                        onTap: () => setState(() => _style = style),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 108,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(style.skyTop), Color(style.skyBottom)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected ? Color(style.accent) : Colors.white12,
                              width: selected ? 2 : 1,
                            ),
                            boxShadow: selected
                                ? [BoxShadow(color: Color(style.accent).withValues(alpha: 0.3), blurRadius: 12)]
                                : const [],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Icon(
                                _styleIcon(style),
                                size: 22,
                                color: selected ? Color(style.accent) : Colors.white70,
                              ),
                              Text(
                                style.label,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: selected ? Color(style.accent) : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  minLines: 5,
                  maxLines: 8,
                  onChanged: (value) => _length.value = value.trim().length,
                  decoration: InputDecoration(
                    hintText: '写一句故事，例如：雨夜林晚到茶馆送信',
                    hintStyle: const TextStyle(color: Colors.white30),
                    filled: true,
                    fillColor: const Color(0xFF17171C),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: accent.withValues(alpha: 0.6)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final prompt in _prompts)
                      ActionChip(
                        label: Text(prompt.$1),
                        onPressed: () => _fill(prompt.$2),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<int>(
                  valueListenable: _length,
                  builder: (context, count, _) {
                    final enough = count >= 4;
                    return Row(
                      children: [
                        TextButton(
                          onPressed: () => _fill(ScriptGenerator.sampleStory),
                          child: const Text('完整示例'),
                        ),
                        if (count > 0)
                          TextButton(
                            onPressed: () => _fill(''),
                            child: const Text('清空'),
                          ),
                        const Spacer(),
                        Text(
                          enough ? '$count 字' : '至少 4 个字',
                          style: TextStyle(color: enough ? Colors.white38 : accent, fontSize: 12),
                        ),
                      ],
                    );
                  },
                ),
                if (_saved.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  const Text('最近作品 · 左滑删除', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  for (final episode in _saved) ...[
                    Dismissible(
                      key: ValueKey(episode.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => _remove(episode),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(color: const Color(0xFF5C2A32), borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.delete_outline),
                      ),
                      child: Material(
                      color: const Color(0xFF17171C),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _open(episode),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              _thumb(episode),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      episode.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${episode.style.label} · ${episode.panels.length}镜 · ${_when(episode.createdAt)}',
                                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: Colors.white24),
                            ],
                          ),
                        ),
                      ),
                    ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ] else ...[
                  const SizedBox(height: 28),
                  const Text('生成的漫剧会留在这里', style: TextStyle(color: Colors.white38)),
                ],
              ],
            ),
                ),
                ValueListenableBuilder<int>(
                  valueListenable: _length,
                  builder: (context, count, _) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                      child: FilledButton(
                        onPressed: count >= 4 ? _generate : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.black,
                          disabledBackgroundColor: const Color(0xFF2A2A30),
                          disabledForegroundColor: Colors.white38,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: const Text('生成漫剧'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
