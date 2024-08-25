import 'package:json_annotation/json_annotation.dart';

part 'rich_text_tree.g.dart';

const JRTE = JsonSerializable(converters: [_RichTextElementConverter()]);

sealed class RichTextElement {
  Map<String, dynamic> toJson();
}


@JRTE
final class RichTextSpan extends RichTextElement {
  static const String tag = "s";
  
  @JsonKey(name: "c")
  String content;
  
  @override
  Map<String, dynamic> toJson() {
    return _$RichTextSpanToJson(this)..["\$"] = tag;
  }

  RichTextSpan(this.content);
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
}


@JsonSerializable()
final class RichTextBreak extends RichTextElement {
  static const String tag = "r";
  
  @override
  Map<String, dynamic> toJson() {
    return {"\$": tag};
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
}

@JRTE
final class RichTextLink extends RichTextElement {
  static const String tag = "l";
  
  @JsonKey(name: "c")
  List<RichTextElement> children;
  
  @override
  Map<String, dynamic> toJson() {
    return _$RichTextLinkToJson(this)..["\$"] = tag;
  }

  RichTextLink(this.children);
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
}

@JRTE
final class RichTextAnnouncement extends RichTextElement {
  static const String tag = "a";
  
  @JsonKey(name: "c")
  List<RichTextElement> children;
  
  @override
  Map<String, dynamic> toJson() {
    return _$RichTextAnnouncementToJson(this)..["\$"] = tag;
  }

  RichTextAnnouncement(this.children);
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
}


@JsonSerializable()
final class RichTextDivider extends RichTextElement {
  static const String tag = "d";
  
  @override
  Map<String, dynamic> toJson() {
    return {"\$": tag};
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
}

@JRTE
final class RichTextDocument {
  @JsonKey(name: "f")
  final List<RichTextElement> footnotes;
  @JsonKey(name: "d")
  final List<RichTextElement> document;

  RichTextDocument(this.footnotes, this.document);
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
  int row;
  int col;
  int rowSpan;
  int colSpan;
  RichTextElement child;

  RichTextTableCell({required this.row, required this.col, required this.rowSpan, required this.colSpan, required this.child});
  
  static RichTextTableCell fromJson(Map<String, dynamic> json) => _$RichTextTableCellFromJson(json);
}

