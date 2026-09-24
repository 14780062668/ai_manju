import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as im;
import 'package:path_provider/path_provider.dart';

import 'package:ai_manju/domain/manju.dart';

class GifExport {
  /// 把每一镜的竖屏截图合成 GIF，时长跟台词长度走。
  static Future<String> save(
    ManjuEpisode episode,
    List<Uint8List> frames, {
    required int width,
    required int height,
  }) async {
    final durations = [
      for (final panel in episode.panels) _durationMs(panel),
    ];
    final bytes = await compute(_encodeGif, (frames, width, height, durations));
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

Uint8List _encodeGif((List<Uint8List>, int, int, List<int>) payload) {
  final (frames, width, height, durations) = payload;
  if (frames.isEmpty) throw StateError('没有可导出的画面');
  // 八叉树量化比神经网络快，占位画面颜色少，够用。
  final encoder = im.GifEncoder(quantizerType: im.QuantizerType.octree);
  for (var i = 0; i < frames.length; i++) {
    final image = im.Image.fromBytes(
      width: width,
      height: height,
      bytes: frames[i].buffer,
      bytesOffset: frames[i].offsetInBytes,
      numChannels: 4,
    );
    encoder.addFrame(image, duration: durations[i] ~/ 10);
  }
  final bytes = encoder.finish();
  if (bytes == null) throw StateError('没有可导出的画面');
  return bytes;
}
