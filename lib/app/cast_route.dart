import 'package:flutter/material.dart';

import 'package:ai_manju/domain/manju.dart';
import 'package:ai_manju/ui/cast/cast_page.dart';

Route<void> openCast(ManjuEpisode episode) {
  return MaterialPageRoute<void>(builder: (_) => CastPage(episode: episode));
}
