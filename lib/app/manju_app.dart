import 'package:flutter/material.dart';

import 'package:ai_manju/app/manju_theme.dart';
import 'package:ai_manju/ui/create/create_page.dart';

class ManjuApp extends StatelessWidget {
  const ManjuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI漫剧',
      debugShowCheckedModeBanner: false,
      theme: buildManjuTheme(),
      home: const CreatePage(),
    );
  }
}
