import 'package:ai_manju/domain/manju.dart';

class ScriptGenerator {
  static const sampleStory =
      '夜雨里，林晚推开老街茶馆的门。掌柜抬头说道：「这么晚还出门？」林晚把一封信放在柜上：「有人让我把这个交给你。」掌柜拆开信，脸色变了，低声道：「这是十年前的旧案。」门外忽然响起脚步。黑衣人站在雨里，冷声道：「信交出来。」林晚挡在柜前：「想拿，先问过我。」';

  static const _maxPanels = 24;
  static const _stopNames = {
    '然后',
    '突然',
    '这时',
    '门外',
    '屋里',
    '夜里',
    '雨里',
    '一个',
    '什么',
    '这个',
    '那个',
    '有人',
    '脸色',
    '夜雨',
  };

  ManjuEpisode generate({required String story, required ManjuStyle style}) {
    final raw = story.trim();
    final sentences = _splitSentences(_expandDescription(raw, style));
    final characters = _collectNames(sentences);
    final cast = characters.isEmpty ? const ['主角'] : characters;
    final panels = <ManjuPanel>[];
    var location = style.defaultPlace;

    for (final sentence in sentences) {
      if (panels.length >= _maxPanels) break;
      location = _detectLocation(sentence, location, style);
      final parsed = _parseLine(sentence, cast);
      final shot = _pickShot(sentence, parsed.line, panels.length);
      final speaker = parsed.speaker;
      panels.add(
        ManjuPanel(
          index: panels.length + 1,
          shot: shot,
          location: location,
          visual: '${style.label}，$location，$shot，${speaker == '旁白' ? '人物入画' : '$speaker出镜'}',
          speaker: speaker,
          line: parsed.line,
          narration: parsed.narration,
        ),
      );
    }

    if (panels.isEmpty) {
      panels.add(
        ManjuPanel(
          index: 1,
          shot: '中景',
          location: style.defaultPlace,
          visual: '${style.label}，${style.defaultPlace}，中景，人物入画',
          speaker: '旁白',
          line: '',
          narration: story.trim(),
        ),
      );
    }

    final title = cast.first == '主角' ? '${style.label}漫剧' : '${cast.first}的故事';
    final now = DateTime.now().millisecondsSinceEpoch;
    return ManjuEpisode(
      id: '$now',
      createdAt: now,
      title: title,
      style: style,
      characters: cast,
      panels: panels,
      source: raw,
    );
  }

  /// 没有台词时，把一句描述扩成带对白的故事。已有「」或“说道”则原样使用。
  String _expandDescription(String text, ManjuStyle style) {
    if (RegExp('[「“"].+[」”"]').hasMatch(text) || text.contains('说道') || text.contains('问道')) {
      return text;
    }
    final names = _pickNames(text);
    final lead = names.isEmpty ? '主角' : names.first;
    var partner = names.length > 1 ? names[1] : _partnerOf(style);
    if (partner == lead) partner = _partnerOf(style);
    final place = _detectLocation(text, style.defaultPlace, style);
    final bits = text.split(RegExp(r'[，。！？；、\n]+')).map((item) => item.trim()).where((item) => item.length >= 2).toList();
    final plot = bits.isEmpty ? text : bits.first;
    final reply = bits.length > 1 ? bits[1] : '这件事，我必须亲自来';
    final ending = bits.length > 2 ? bits.last : '今天就要有个结果';
    return '$place里，$lead走了进来。$plot。'
        '$partner看着$lead，说道：「你来做什么？」'
        '$lead说道：「$reply。」'
        '$partner说道：「这事没那么简单。」'
        '$lead上前一步，说道：「$ending。」'
        '$partner说道：「那好，就按你说的。」';
  }

  List<String> _pickNames(String text) {
    final names = <String>[];
    final verb = RegExp(r'([\u4e00-\u9fa5]{2,3})(?=把|给|向|对|去|来|推|走|看|站|挡|送)');
    for (final match in verb.allMatches(text)) {
      final raw = match.group(1)!;
      const keep3 = {'黑衣人', '小姑娘', '老掌柜'};
      _addName(names, raw.length == 3 && !keep3.contains(raw) ? raw.substring(1) : raw);
    }
    for (final role in ['黑衣人', '掌柜', '老板', '老师', '同学']) {
      if (text.contains(role)) _addName(names, role);
    }
    return names;
  }

  String _partnerOf(ManjuStyle style) {
    return switch (style) {
      ManjuStyle.ancient => '掌柜',
      ManjuStyle.city => '同事',
      ManjuStyle.suspense => '黑衣人',
      ManjuStyle.sweet => '对方',
    };
  }

  /// 按句号切句，引号里的标点不切断台词。
  List<String> _splitSentences(String text) {
    final sentences = <String>[];
    final buf = StringBuffer();
    var inQuote = false;
    for (final rune in text.runes) {
      final ch = String.fromCharCode(rune);
      if ('「“"'.contains(ch)) inQuote = true;
      if ('」”"'.contains(ch)) {
        buf.write(ch);
        inQuote = false;
        continue;
      }
      buf.write(ch);
      if (!inQuote && '。！？；\n'.contains(ch)) {
        final sentence = buf.toString().trim();
        if (sentence.isNotEmpty) sentences.add(sentence);
        buf.clear();
      }
    }
    final rest = buf.toString().trim();
    if (rest.isNotEmpty) sentences.add(rest);
    return sentences;
  }

  List<String> _collectNames(List<String> sentences) {
    final names = <String>[];
    final verb = RegExp(r'([\u4e00-\u9fa5]{2,3})(?:抬头|起身|转身)?(?:说道|问道|喊道|笑道|冷声道|低声道)');
    final lead = RegExp(r'^([\u4e00-\u9fa5]{2,3})(?=站|走|推|看|把|挡|抬|拆|坐|来)');
    for (final sentence in sentences) {
      for (final match in verb.allMatches(sentence)) {
        _addName(names, match.group(1));
      }
      final leadMatch = lead.firstMatch(sentence);
      _addName(names, leadMatch?.group(1));
    }
    return names.take(6).toList();
  }

  void _addName(List<String> names, String? raw) {
    if (raw == null || raw.length < 2 || _stopNames.contains(raw) || names.contains(raw)) return;
    names.add(raw);
  }

  _Parsed _parseLine(String sentence, List<String> cast) {
    final quoted = RegExp('[「“"]([^」”"]+)[」”"]').firstMatch(sentence);
    final line = quoted?.group(1)?.trim() ?? '';
    var narration = sentence;
    if (quoted != null) {
      narration = sentence.replaceRange(quoted.start, quoted.end, '').trim();
      narration = narration.replaceAll(RegExp(r'(抬头|起身|转身)?(?:说道|问道|喊道|笑道|冷声道|低声道)'), '');
      narration = narration.replaceAll(RegExp(r'^[，。、：:\s]+|[，。、：:\s]+$'), '');
    }
    var speaker = '旁白';
    if (line.isNotEmpty) {
      final verb = RegExp(r'([\u4e00-\u9fa5]{2,3})(?:抬头|起身|转身)?(?:说道|问道|喊道|笑道|冷声道|低声道)');
      final named = verb.firstMatch(sentence)?.group(1);
      if (named != null && !_stopNames.contains(named)) {
        speaker = named;
      } else {
        for (final name in cast) {
          if (sentence.contains(name)) {
            speaker = name;
            break;
          }
        }
        if (speaker == '旁白') speaker = cast.first;
      }
      if (narration == speaker) narration = '';
    }
    return _Parsed(speaker: speaker, line: line, narration: narration);
  }

  String _pickShot(String sentence, String line, int index) {
    if (line.isNotEmpty && line.length <= 12) return '特写';
    if (RegExp('推开|走进|远远|街头|夜色|门外').hasMatch(sentence)) return '远景';
    return index.isEven ? '中景' : '近景';
  }

  String _detectLocation(String sentence, String current, ManjuStyle style) {
    const places = {
      '茶馆': '茶馆',
      '客栈': '客栈',
      '公司': '办公室',
      '学校': '校园',
      '宫': '宫殿',
      '山': '山间',
      '街': '街道',
      '雨': '雨夜',
      '门': '门口',
      '房': '室内',
      '巷': '暗巷',
      '楼': '楼内',
      '车': '车内',
      '海': '海边',
      '桥': '桥上',
    };
    String? found;
    var pos = 1 << 30;
    for (final entry in places.entries) {
      final index = sentence.indexOf(entry.key);
      if (index >= 0 && index < pos) {
        pos = index;
        found = entry.value;
      }
    }
    return found ?? current;
  }
}

class _Parsed {
  const _Parsed({required this.speaker, required this.line, required this.narration});

  final String speaker;
  final String line;
  final String narration;
}
