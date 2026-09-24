import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as im;
import 'package:path_provider/path_provider.dart';

import 'package:ai_manju/domain/manju.dart';

class GifExport {
  /// 把每一镜的竖屏截图合成 GIF，时长跟台词长度走。
  static Future<String> save(ManjuEpisode episode, List<Uint8List> pngs) async {
    final durations = [
      for (final panel in episode.panels) _durationMs(panel),
    ];
    final bytes = await compute(_encodeGif, (pngs, durations));
    final dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}${Platform.pathSeparator}AI漫剧');
    await folder.create(recursive: true);
    final safe = episode.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '');
    final file = File('${folder.path}${Platform.pathSeparator}$safe${DateTime.now().millisecondsSinceEpoch}.gif');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  static int _durationMs(ManjuPanel panel) {
    final seconds = (panel.spoken.length / 4).clamp(2.0, 6.0);
    return (seconds * 1000).round();
  }
}

Uint8List _encodeGif((List<Uint8List>, List<int>) payload) {
  final (pngs, durations) = payload;
  final encoder = im.GifEncoder(samplingFactor: 20);
  im.Image? canvas;
  var added = 0;
  for (var i = 0; i < pngs.length; i++) {
    final decoded = im.decodePng(pngs[i]);
    if (decoded == null) continue;
    final frame = canvas == null ? decoded : im.copyResize(decoded, width: canvas.width, height: canvas.height);
    canvas ??= frame;
    encoder.addFrame(frame, duration: durations[i] ~/ 10);
    added++;
  }
  final bytes = encoder.finish();
  if (added == 0 || bytes == null) {
    throw StateError('没有可导出的画面');
  }
  return bytes;
}
