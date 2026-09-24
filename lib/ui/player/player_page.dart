import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'package:ai_manju/app/cast_route.dart';
import 'package:ai_manju/data/gif_export.dart';
import 'package:ai_manju/domain/manju.dart';
import 'package:ai_manju/ui/widgets/panel_card.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key, required this.episode});

  final ManjuEpisode episode;

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  final _page = PageController();
  final _tts = FlutterTts();
  final _captureKey = GlobalKey();
  var _index = 0;
  var _playing = false;
  var _runId = 0;
  var _autoTurning = false;
  var _exporting = false;
  var _captureIndex = 0;
  var _rate = 0.45;
  var _seenSwipe = false;

  @override
  void initState() {
    super.initState();
    _tts.setLanguage('zh-CN');
    _tts.setSpeechRate(0.45);
    _tts.awaitSpeakCompletion(true);
  }

  @override
  void dispose() {
    _playing = false;
    _runId++;
    _tts.stop();
    _page.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      setState(() => _playing = false);
      _runId++;
      await _tts.stop();
      return;
    }
    final panels = widget.episode.panels;
    if (_index >= panels.length - 1) {
      setState(() => _index = 0);
      _autoTurning = true;
      await _page.animateToPage(0, duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
      _autoTurning = false;
    }
    if (!mounted) return;
    setState(() => _playing = true);
    _loop(++_runId);
  }

  Future<void> _setRate(double rate) async {
    setState(() => _rate = rate);
    await _tts.setSpeechRate(rate);
  }

  /// 从当前镜往后念台词，念完再切下一镜。手动滑动会打断这一轮。
  Future<void> _loop(int runId) async {
    final panels = widget.episode.panels;
    while (mounted && _playing && runId == _runId) {
      final panel = panels[_index];
      await _tts.stop();
      if (!_playing || runId != _runId) return;
      if (panel.spoken.trim().isNotEmpty) {
        try {
          await _tts.speak(panel.spoken);
        } catch (_) {
          await Future<void>.delayed(Duration(milliseconds: panel.spoken.length * 180));
        }
      }
      if (!mounted || !_playing || runId != _runId) return;
      if (_index >= panels.length - 1) {
        setState(() => _playing = false);
        return;
      }
      _autoTurning = true;
      await _page.nextPage(duration: const Duration(milliseconds: 360), curve: Curves.easeOut);
      _autoTurning = false;
    }
  }

  void _restartIfPlaying() {
    if (!_playing) return;
    _tts.stop();
    _loop(++_runId);
  }

  /// 离屏截每一镜，再合成竖屏 GIF。
  Future<void> _exportGif() async {
    if (_exporting) return;
    setState(() {
      _playing = false;
      _exporting = true;
      _captureIndex = 0;
    });
    _runId++;
    await _tts.stop();
    if (!mounted) return;

    final progress = ValueNotifier('正在截取画面');
    OverlayEntry? entry;
    var inserted = false;
    var dialogOnStack = false;
    try {
      entry = OverlayEntry(
        builder: (context) {
          return Positioned(
            left: 0,
            top: 0,
            child: IgnorePointer(
              child: RepaintBoundary(
                key: _captureKey,
                child: SizedBox(
                  width: 360,
                  height: 640,
                  child: PanelCard(
                    panel: widget.episode.panels[_captureIndex],
                    episode: widget.episode,
                  ),
                ),
              ),
            ),
          );
        },
      );
      Overlay.of(context).insert(entry);
      inserted = true;
      if (!mounted) return;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return ValueListenableBuilder<String>(
            valueListenable: progress,
            builder: (context, text, _) {
              return Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 12),
                        Text(text),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
      dialogOnStack = true;
      final frames = <Uint8List>[];
      var width = 0;
      var height = 0;
      for (var i = 0; i < widget.episode.panels.length; i++) {
        progress.value = '正在截取 ${i + 1}/${widget.episode.panels.length}';
        setState(() => _captureIndex = i);
        entry.markNeedsBuild();
        final shot = await _captureFrame();
        width = shot.width;
        height = shot.height;
        frames.add(shot.rgba);
      }
      progress.value = '正在合成';
      final path = await GifExport.save(widget.episode, frames, width: width, height: height);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已导出 $path')));
      if (Platform.isWindows) {
        await Process.run('explorer.exe', ['/select,$path']);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('导出失败')));
    } finally {
      if (inserted) entry?.remove();
      if (dialogOnStack && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (mounted) setState(() => _exporting = false);
      Future<void>.delayed(const Duration(milliseconds: 400), progress.dispose);
    }
  }

  Future<({int width, int height, Uint8List rgba})> _captureFrame() async {
    for (var i = 0; i < 6; i++) {
      await WidgetsBinding.instance.endOfFrame;
      final boundary = _captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null || !boundary.hasSize || boundary.size.isEmpty) continue;
      try {
        final image = await boundary.toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        final width = image.width;
        final height = image.height;
        image.dispose();
        if (data == null) continue;
        return (width: width, height: height, rgba: data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
      } catch (_) {}
    }
    throw StateError('画面截取失败');
  }

  Future<void> _copyScript() async {
    await Clipboard.setData(ClipboardData(text: widget.episode.script));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('分镜脚本已复制')));
  }

  @override
  Widget build(BuildContext context) {
    final episode = widget.episode;
    final accent = Color(episode.style.accent);
    return Scaffold(
      appBar: AppBar(
        title: Text(episode.title),
        actions: [
          TextButton(
            onPressed: () {
              final text = widget.episode.source.isEmpty ? widget.episode.script : widget.episode.source;
              Navigator.of(context).pop(text);
            },
            child: const Text('改故事'),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).push(openCast(episode)),
            icon: const Icon(Icons.people_outline),
            tooltip: '角色',
          ),
          IconButton(
            onPressed: _exporting ? null : _exportGif,
            icon: const Icon(Icons.download_outlined),
            tooltip: '导出',
          ),
          IconButton(onPressed: _copyScript, icon: const Icon(Icons.copy), tooltip: '复制脚本'),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Row(
              children: [
                Text(episode.style.label, style: TextStyle(color: accent)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    episode.characters.join('、'),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white54),
                  ),
                ),
                Text(
                  _seenSwipe || episode.panels.length < 2 ? '${_index + 1}/${episode.panels.length}' : '上滑下一镜',
                  style: const TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
          LinearProgressIndicator(
            value: episode.panels.isEmpty ? 0 : (_index + 1) / episode.panels.length,
            minHeight: 2,
            color: accent,
            backgroundColor: Colors.white12,
          ),
          Expanded(
            child: PageView.builder(
              controller: _page,
              scrollDirection: Axis.vertical,
              itemCount: episode.panels.length,
              onPageChanged: (index) {
                setState(() {
                  _index = index;
                  if (index > 0) _seenSwipe = true;
                });
                if (!_autoTurning) _restartIfPlaying();
              },
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: AspectRatio(
                        aspectRatio: 9 / 16,
                        child: GestureDetector(
                          onTap: _exporting ? null : _toggle,
                          child: PanelCard(panel: episode.panels[index], episode: episode),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _index == 0
                      ? null
                      : () => _page.previousPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOut),
                  icon: const Icon(Icons.skip_previous),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _exporting ? null : _toggle,
                  style: FilledButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.black),
                  icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
                  label: Text(_playing ? '暂停' : (_index >= episode.panels.length - 1 ? '重播' : '播放')),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<double>(
                  tooltip: '语速',
                  initialValue: _rate,
                  onSelected: _setRate,
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 0.35, child: Text('慢')),
                    PopupMenuItem(value: 0.45, child: Text('正常')),
                    PopupMenuItem(value: 0.6, child: Text('快')),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.speed, size: 20),
                        const SizedBox(width: 4),
                        Text(_rate == 0.35 ? '慢' : _rate == 0.6 ? '快' : '正常', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _index >= episode.panels.length - 1
                      ? null
                      : () => _page.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOut),
                  icon: const Icon(Icons.skip_next),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
