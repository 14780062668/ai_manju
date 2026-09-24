import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'package:ai_manju/domain/manju.dart';

class EpisodeStore {
  static const _keep = 40;

  static Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}${Platform.pathSeparator}manju_library.json');
  }

  static Future<List<ManjuEpisode>> load() async {
    try {
      final file = await _file();
      if (!file.existsSync()) return [];
      final list = jsonDecode(await file.readAsString()) as List;
      return [
        for (final item in list) ManjuEpisode.fromJson(Map<String, Object?>.from(item as Map)),
      ];
    } catch (_) {
      return [];
    }
  }

  /// 新作品放最前，只留最近 40 部。
  static Future<void> save(ManjuEpisode episode) async {
    final all = await load();
    all.removeWhere((item) => item.id == episode.id);
    all.insert(0, episode);
    await _write(all.take(_keep).toList());
  }

  static Future<void> remove(String id) async {
    final all = await load();
    all.removeWhere((item) => item.id == id);
    await _write(all);
  }

  static Future<void> _write(List<ManjuEpisode> episodes) async {
    final file = await _file();
    await file.writeAsString(jsonEncode([for (final episode in episodes) episode.toJson()]));
  }
}
