import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'package:ai_manju/domain/manju.dart';

class EpisodeStore {
  static const _keep = 40;
  static List<ManjuEpisode>? _cache;

  static Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}${Platform.pathSeparator}manju_library.json');
  }

  static Future<List<ManjuEpisode>> load() async {
    final cached = _cache;
    if (cached != null) return List<ManjuEpisode>.of(cached);
    try {
      final file = await _file();
      if (!file.existsSync()) {
        _cache = [];
        return [];
      }
      final list = jsonDecode(await file.readAsString()) as List;
      _cache = [
        for (final item in list) ManjuEpisode.fromJson(Map<String, Object?>.from(item as Map)),
      ];
      return List<ManjuEpisode>.of(_cache!);
    } catch (_) {
      return [];
    }
  }

  /// 新作品放最前，只留最近 40 部。
  static Future<void> save(ManjuEpisode episode) async {
    final all = await load();
    all.removeWhere((item) => item.id == episode.id);
    all.insert(0, episode);
    final kept = all.take(_keep).toList();
    _cache = kept;
    await _write(kept);
  }

  static Future<void> remove(String id) async {
    final all = await load();
    all.removeWhere((item) => item.id == id);
    _cache = all;
    await _write(all);
  }

  static Future<void> _write(List<ManjuEpisode> episodes) async {
    final file = await _file();
    await file.writeAsString(jsonEncode([for (final episode in episodes) episode.toJson()]));
  }
}
