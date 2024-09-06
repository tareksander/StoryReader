import 'package:json_annotation/json_annotation.dart';
import 'package:html/dom.dart' as dom;

part 'rich_text_tree.g.dart';

const JRTE = JsonSerializable(converters: [_RichTextElementConverter()]);

sealed class RichTextElement {
  Map<String, dynamic> toJson();
  
  void visit(void Function(RichTextElement) f);
}


@JRTE
final class RichTextText extends RichTextElement {
  static const String tag = "s";
  
  @JsonKey(name: "c")
  String content;
  
  @override
  Map<String, dynamic> toJson() {
    return _$RichTextTextToJson(this)..["\$"] = tag;
  }
  
  RichTextText(this.content);

  @override
  void visit(void Function(RichTextElement p1) f) {
    f(this);
  }
  
}

@JRTE
final class RichTextSpan extends RichTextElement {
  static const String tag = "o";
  
  @JsonKey(name: "c")
  List<RichTextElement> children;
  
  @override
  Map<String, dynamic> toJson() {
    return _$RichTextSpanToJson(this)..["\$"] = tag;
  }

  RichTextSpan(this.children);

  @override
  void visit(void Function(RichTextElement p1) f) {
    f(this);
    for (var c in children) {
      f(c);
    }
  }
}

@JRTE
final class RichTextParagraph extends RichTextElement {
  static const String tag = "p";
  
  @JsonKey(name: "c")
  List<RichTextElement> children;
  
  @override
  Map<String, dynamic> toJson() {
    return _$RichTextParagraphToJson(this)..["\$"] = tag;
  }

  RichTextParagraph(this.children);

  @override
  void visit(void Function(RichTextElement p1) f) {
    f(this);
    for (var c in children) {
      f(c);
    }
  }
}


@JsonSerializable()
final class RichTextBreak extends RichTextElement {
  static const String tag = "r";
  
  @override
  Map<String, dynamic> toJson() {
    return {"\$": tag};
  }

  @override
  void visit(void Function(RichTextElement p1) f) {
    f(this);
  }
  
}

@JRTE
final class RichTextCodeBlock extends RichTextElement {
  static const String tag = "c";
  
  @JsonKey(name: "c")
  List<RichTextElement> children;
  
  @override
  Map<String, dynamic> toJson() {
    return _$RichTextCodeBlockToJson(this)..["\$"] = tag;
  }

  RichTextCodeBlock(this.children);

  @override
  void visit(void Function(RichTextElement p1) f) {
    f(this);
    for (var c in children) {
      f(c);
    }
  }
}


@JRTE
final class RichTextCursive extends RichTextElement {
  static const String tag = "e";
  
  @JsonKey(name: "c")
  List<RichTextElement> children;
  
  @override
  Map<String, dynamic> toJson() {
    return _$RichTextCursiveToJson(this)..["\$"] = tag;
  }

  RichTextCursive(this.children);

  @override
  void visit(void Function(RichTextElement p1) f) {
    f(this);
    for (var c in children) {
      f(c);
    }
  }
}

@JRTE
final class RichTextBold extends RichTextElement {
  static const String tag = "b";
  
  @JsonKey(name: "c")
  List<RichTextElement> children;
  
  @override
  Map<String, dynamic> toJson() {
    return _$RichTextBoldToJson(this)..["\$"] = tag;
  }

  RichTextBold(this.children);

  @override
  void visit(void Function(RichTextElement p1) f) {
    f(this);
    for (var c in children) {
      f(c);
    }
  }
}

@JRTE
final class RichTextTable extends RichTextElement {
  static const String tag = "t";

  @JsonKey(name: "c")
  List<RichTextTableCell> cells;
  
  @override
  Map<String, dynamic> toJson() {
    return _$RichTextTableToJson(this)..["\$"] = tag;
  }

  RichTextTable(this.cells);

  @override
  void visit(void Function(RichTextElement p1) f) {
    f(this);
  }
}

@JRTE
final class RichTextLink extends RichTextElement {
  static const String tag = "l";
  
  @JsonKey(name: "c")
  List<RichTextElement> children;
  
  @JsonKey(name: "u")
  String url;
  
  @override
  Map<String, dynamic> toJson() {
    return _$RichTextLinkToJson(this)..["\$"] = tag;
  }

  RichTextLink(this.children, this.url);

  @override
  void visit(void Function(RichTextElement p1) f) {
    f(this);
    for (var c in children) {
      f(c);
    }
  }
}

@JsonSerializable()
final class RichTextImage extends RichTextElement {
  static const String tag = "i";
  
  @JsonKey(name: "i")
  int image;
  
  @override
  Map<String, dynamic> toJson() {
    return _$RichTextImageToJson(this)..["\$"] = tag;
  }

  RichTextImage(this.image);

  @override
  void visit(void Function(RichTextElement p1) f) {
    f(this);
  }
}

@JRTE
final class RichTextAnnouncement extends RichTextElement {
  static const String tag = "a";
  
  @JsonKey(name: "t")
  String title;
  
  @JsonKey(name: "c")
  List<RichTextElement> children;
  
  @override
  Map<String, dynamic> toJson() {
    return _$RichTextAnnouncementToJson(this)..["\$"] = tag;
  }

  RichTextAnnouncement(this.title, this.children);

  @override
  void visit(void Function(RichTextElement p1) f) {
    f(this);
    for ( var c in children) {
      f(c);
    }
  }
}

@JRTE
final class RichTextAuthorNote extends RichTextElement {
  static const String tag = "n";
  
  @JsonKey(name: "c")
  List<RichTextElement> children;
  
  @override
  Map<String, dynamic> toJson() {
    return _$RichTextAuthorNoteToJson(this)..["\$"] = tag;
  }

  RichTextAuthorNote(this.children);

  @override
  void visit(void Function(RichTextElement p1) f) {
    f(this);
    for (var c in children) {
      f(c);
    }
  }
}


@JsonSerializable()
final class RichTextDivider extends RichTextElement {
  static const String tag = "d";
  
  @override
  Map<String, dynamic> toJson() {
    return {"\$": tag};
  }

  @override
  void visit(void Function(RichTextElement p1) f) {
    f(this);
  }
}


@JsonSerializable()
final class RichTextFootnoteReference extends RichTextElement {
  static const String tag = "f";
  
  @JsonKey(name: "f")
  int footnote;
  
  @override
  Map<String, dynamic> toJson() {
    return _$RichTextFootnoteReferenceToJson(this)..["\$"] = tag;
  }
  

  RichTextFootnoteReference(this.footnote);

  @override
  void visit(void Function(RichTextElement p1) f) {
    f(this);
  }
}

@JRTE
final class RichTextDocument {
  @JsonKey(name: "f")
  late final List<RichTextElement> footnotes;
  @JsonKey(name: "d")
  late final List<RichTextElement> document;
  
  /// Stores the source Uris for images encountered when converting from HTML
  @JsonKey(includeToJson: false, includeFromJson: false, defaultValue: [])
  late final List<Uri> imageSources;

  RichTextDocument(this.footnotes, this.document);
  
  RichTextDocument.html(dom.NodeList nodes) {
    footnotes = [];
    imageSources = [];
    document = nodes.map((e) => toRTE(e).$1).toList();
  }

  (List<RichTextElement>, bool) nodesToRTE(dom.NodeList nl, [bool paragraphBreaks = true]) {
    var c = nl.map((c) => toRTE(c, paragraphBreaks)).toList();
    return (c.map((e) => e.$1).toList(), c.map((e) => e.$2).any((e) => e));
  }
  
  (RichTextElement, bool) toRTE(dom.Node n, [bool paragraphBreaks = true]) {
    if (n is dom.Element) {
      Lazy<(List<RichTextElement>, bool)> c = Lazy(() => nodesToRTE(n.nodes, paragraphBreaks));
      switch (n.localName) {
        case "pre":
          return (RichTextCodeBlock(c.v.$1), c.v.$2);
        case "hr":
          return (RichTextDivider(), false);
        case "br":
          if (paragraphBreaks) {
            return (RichTextText("\n"), false);
          } else {
            return (RichTextText(""), false);
          }
        case "strong":
          return (RichTextBold(c.v.$1), c.v.$2);
        case "i":
        case "em":
          return (RichTextCursive(c.v.$1), c.v.$2);
        case "a":
          Uri? href = null;
          String? hrefs = n.attributes["href"];
          if (hrefs != null) {
            href = Uri.tryParse(hrefs);
          }
          if (href != null) {
            return (RichTextLink(c.v.$1, href.toString()), c.v.$2);
          } else {
            return (RichTextSpan(c.v.$1), c.v.$2);
          }
        case "span":
          return (RichTextSpan(c.v.$1), c.v.$2);
        case "img":
          imageSources.add(Uri.parse(n.attributes["src"]!));
          return (RichTextImage(imageSources.length-1), false);
        case "table":
          var cells = <RichTextTableCell>[];
          var rows = n.getElementsByTagName("tr");
          for (var (y, r) in rows.indexed) {
            for (var (x, c) in r.children.indexed) {
              int rs = 1, cs = 1;
              var rss = c.attributes["rowspan"];
              var css = c.attributes["colspan"];
              if (rss != null) {
                rs = int.tryParse(rss) ?? 1;
              }
              if (css != null) {
                cs = int.tryParse(css) ?? 1;
              }
              cells.add(RichTextTableCell(row: y, col: x, rowSpan: rs, colSpan: cs, child: toRTE(c, false).$1));
            }
          }
          return (RichTextTable(cells), false);
        case "p":
        case "div":
          try {
            if (n.classes.contains("wi_news")) {
              String title = n.children[0].nodes.last.text ?? "";
              var body = n.children[1];
              var c = nodesToRTE(body.nodes, paragraphBreaks);
              return (RichTextAnnouncement(title, c.$1), c.$2);
            }
            if (n.classes.contains("wi_authornotes")) {
              var body = n.getElementsByClassName("wi_authornotes_body")[0];
              var c = nodesToRTE(body.nodes, paragraphBreaks);
              return (RichTextAuthorNote(c.$1), c.$2);
            }
          } catch (e) {
            return (RichTextText(""), false);
          }
          return (RichTextParagraph(c.v.$1), c.v.$2);
        default:
          return (RichTextText(n.text), n.text.trim().isNotEmpty);
      }
    }
    var text = n.text ?? "";
    if (! paragraphBreaks) {
      text = text.trim();
    }
    return (RichTextText(text.replaceAll("\n", "")), text.trim().isNotEmpty);
  }
  
  /// Replaces the image numbers with the corresponding place in the replacement list.
  /// Used to convert to global IDs for the db.
  void rewriteImageIndices(List<int> replace) {
    replacer(RichTextElement e) {
      if (e is RichTextImage) {
        e.image = replace[e.image];
      }
    }
    for (var f in footnotes) {
      f.visit(replacer);
    }
    for (var c in document) {
      c.visit(replacer);
    }
  }
  
  Map<String, dynamic> toJson() {
    return _$RichTextDocumentToJson(this);
  }
  
  factory RichTextDocument.fromJson(Map<String, dynamic> json) => _$RichTextDocumentFromJson(json);
}




final class _RichTextElementConverter extends JsonConverter<RichTextElement, Map<String, dynamic>> {
  const _RichTextElementConverter();

  @override
  RichTextElement fromJson(Map<String, dynamic> json) {
    switch (json["\$"] as String) {
      case RichTextSpan.tag:
        return _$RichTextSpanFromJson(json);
      case RichTextParagraph.tag:
        return _$RichTextParagraphFromJson(json);
      case RichTextBreak.tag:
        return _$RichTextBreakFromJson(json);
      case RichTextCodeBlock.tag:
        return _$RichTextCodeBlockFromJson(json);
      case RichTextCursive.tag:
        return _$RichTextCursiveFromJson(json);
      case RichTextBold.tag:
        return _$RichTextBoldFromJson(json);
      case RichTextTable.tag:
        return _$RichTextTableFromJson(json);
      case RichTextLink.tag:
        return _$RichTextLinkFromJson(json);
      case RichTextImage.tag:
        return _$RichTextImageFromJson(json);
      case RichTextAnnouncement.tag:
        return _$RichTextAnnouncementFromJson(json);
      case RichTextAuthorNote.tag:
        return _$RichTextAuthorNoteFromJson(json);
      case RichTextDivider.tag:
        return _$RichTextDividerFromJson(json);
      case RichTextFootnoteReference.tag:
        return _$RichTextFootnoteReferenceFromJson(json);
      case RichTextText.tag:
        return _$RichTextTextFromJson(json);
      default:
        throw ArgumentError("Invalid RichText tag: ${json["\$"] as String}");
    }
  }

  @override
  Map<String, dynamic> toJson(RichTextElement object) {
    return object.toJson();
  }
  
}


@JRTE
final class RichTextTableCell {
  @JsonKey(name: "r")
  int row;
  @JsonKey(name: "c")
  int col;
  @JsonKey(name: "rs")
  int rowSpan;
  @JsonKey(name: "cs")
  int colSpan;
  @JsonKey(name: "ch")
  RichTextElement child;

  RichTextTableCell({required this.row, required this.col, required this.rowSpan, required this.colSpan, required this.child});
  
  Map<String, dynamic> toJson() => _$RichTextTableCellToJson(this);
  
  static RichTextTableCell fromJson(Map<String, dynamic> json) => _$RichTextTableCellFromJson(json);
}

final class Lazy<T> {
  late final T _v;
  final T Function() _init;
  bool _done = false;
  
  Lazy(this._init);
  
  get v {
    if (! _done) {
      _v = _init();
      _done = true;
    }
    return _v;
  }
  
}
