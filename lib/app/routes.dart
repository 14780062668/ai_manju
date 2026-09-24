import 'package:flutter/material.dart';

import 'package:ai_manju/domain/manju.dart';
import 'package:ai_manju/ui/player/player_page.dart';

class ManjuRoutes {
  static Route<String?> player(ManjuEpisode episode) {
    return MaterialPageRoute<String?>(builder: (_) => PlayerPage(episode: episode));
  }
}
