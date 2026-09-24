enum ManjuStyle {
  ancient('古风', '古街', 0xFF2A1810, 0xFF6A3A22, 0xFFE8C17A),
  city('都市', '城市街头', 0xFF121820, 0xFF243044, 0xFF7EB6FF),
  suspense('悬疑', '暗巷', 0xFF16121C, 0xFF2A2030, 0xFFC45C6A),
  sweet('甜宠', '午后街角', 0xFF2A1824, 0xFF4A3040, 0xFFF2A3C7);

  const ManjuStyle(this.label, this.defaultPlace, this.skyTop, this.skyBottom, this.accent);

  final String label;
  final String defaultPlace;
  final int skyTop;
  final int skyBottom;
  final int accent;
}

class ManjuPanel {
  const ManjuPanel({
    required this.index,
    required this.shot,
    required this.location,
    required this.visual,
    required this.speaker,
    required this.line,
    required this.narration,
  });

  factory ManjuPanel.fromJson(Map<String, Object?> json) {
    return ManjuPanel(
      index: json['index'] as int,
      shot: json['shot'] as String,
      location: json['location'] as String,
      visual: json['visual'] as String,
      speaker: json['speaker'] as String,
      line: json['line'] as String,
      narration: json['narration'] as String,
    );
  }

  final int index;
  final String shot;
  final String location;
  final String visual;
  final String speaker;
  final String line;
  final String narration;

  Map<String, Object?> toJson() => {
        'index': index,
        'shot': shot,
        'location': location,
        'visual': visual,
        'speaker': speaker,
        'line': line,
        'narration': narration,
      };

  /// 旁白和台词都念出来。
  String get spoken {
    if (line.isEmpty) return narration;
    if (narration.isEmpty) return line;
    return '$narration。$speaker：$line';
  }
}

class ManjuEpisode {
  const ManjuEpisode({
    required this.id,
    required this.createdAt,
    required this.title,
    required this.style,
    required this.characters,
    required this.panels,
    this.source = '',
  });

  factory ManjuEpisode.fromJson(Map<String, Object?> json) {
    return ManjuEpisode(
      id: json['id'] as String,
      createdAt: json['createdAt'] as int,
      title: json['title'] as String,
      style: ManjuStyle.values.byName(json['style'] as String),
      characters: (json['characters'] as List).cast<String>(),
      panels: [
        for (final item in json['panels'] as List) ManjuPanel.fromJson(Map<String, Object?>.from(item as Map)),
      ],
      source: json['source'] as String? ?? '',
    );
  }

  final String id;
  final int createdAt;
  final String title;
  final ManjuStyle style;
  final List<String> characters;
  final List<ManjuPanel> panels;

  Map<String, Object?> toJson() => {
        'id': id,
        'createdAt': createdAt,
        'title': title,
        'style': style.name,
        'characters': characters,
        'panels': [for (final panel in panels) panel.toJson()],
        'source': source,
      };

  final String source;

  String get script {
    final buf = StringBuffer('$title\n');
    for (final panel in panels) {
      buf.writeln('${panel.index}. [${panel.shot}] ${panel.location}');
      if (panel.narration.isNotEmpty) buf.writeln(panel.narration);
      if (panel.line.isNotEmpty) buf.writeln('${panel.speaker}：${panel.line}');
      buf.writeln();
    }
    return buf.toString().trimRight();
  }
}
