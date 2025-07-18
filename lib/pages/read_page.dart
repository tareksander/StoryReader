import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/rendering/sliver.dart';
import 'package:flutter/src/rendering/sliver_grid.dart';
import 'package:html/parser.dart';
import 'package:html/dom.dart' as dom;
import 'package:story_reader/db.dart';
import 'package:story_reader/main.dart';
import 'package:story_reader/prefs.dart';
import 'package:story_reader/rich_text_tree.dart';
import 'package:story_reader/series_data.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'dart:ui' as ui;

import '../flexible_table.dart';

class ReadPage extends StatefulWidget {
  final Chapter chapter;

  const ReadPage(this.chapter, {super.key});

  @override
  State<ReadPage> createState() => _ReadPageState();
}

class _ReadPageState extends State<ReadPage> {
  Future? inProgress;
  late ScrollController sc;
  bool erasePosition = false;

  int? lastOffset;

  @override
  void initState() {
    super.initState();
    sc = ScrollController(initialScrollOffset: widget.chapter.scrollPosition?.toDouble() ?? 0.0);
    sc.addListener(() => lastOffset = sc.offset.round());
    appDB.setLastRead(widget.chapter.site, widget.chapter.id, widget.chapter.number);
  }

  @override
  void dispose() {
    super.dispose();
    if (erasePosition || lastOffset == null) {
      appDB.setScrollPosition(widget.chapter.site, widget.chapter.id, widget.chapter.number, null);
    } else {
      appDB.setScrollPosition(widget.chapter.site, widget.chapter.id, widget.chapter.number, lastOffset!.toInt());
    }
    sc.dispose();
  }

  void _goNext() {
    inProgress ??= (() async {
      var chapters = await appDB.chaptersForFuture(SeriesData(site: widget.chapter.site, id: widget.chapter.id));
      int i = chapters.indexWhere((e) => e.number == widget.chapter.number);
      if (i != -1 && i < chapters.length - 1) {
        //erasePosition = true;
        router.replace("/read", extra: chapters[i + 1].toJson());
      }
      inProgress = null;
    })();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: Key(widget.chapter.number.toString()),
      body: SafeArea(
        child: FutureBuilder(
          future: richTextDocumentToSlivers(appDB.chapterContents(widget.chapter)!, context, widget.chapter),
          builder: (context, d) {
            if (d.hasError) {
              router.pop();
            }
            if (! d.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return CustomScrollView(
              restorationId: "ReadScroll",
              controller: sc,
              slivers: [
                SliverAppBar(
                  pinned: true,
                  title: Row(
                    children: [
                      ElevatedButton(
                          onPressed: () {
                            inProgress ??= (() async {
                              var chapters = await appDB
                                  .chaptersForFuture(SeriesData(site: widget.chapter.site, id: widget.chapter.id));
                              int i = chapters.indexWhere((e) => e.number == widget.chapter.number);
                              if (i > 0) {
                                router.replace("/read", extra: chapters[i - 1].toJson());
                              }
                              inProgress = null;
                            })();
                          },
                          child: Text("Previous")),
                      Flexible(
                        fit: FlexFit.tight,
                        child: Center(
                            child: Text("${widget.chapter.number + 1} - ${widget.chapter.name}",
                                softWrap: true, style: const TextStyle(fontSize: 26))),
                      ),
                      ElevatedButton(onPressed: () => _goNext(), child: Text("Next")),
                    ],
                  ),
                ),
                d.data!,
                SliverList.list(children: [
                  ElevatedButton(onPressed: () => _goNext(), child: Text("Next")),
                ]),
              ],
            );
          }
        ),
      ),
    );
  }
}

Future<SliverList> richTextDocumentToSlivers(RichTextDocument d, BuildContext context, Chapter chapter) async {
  TextStyle style = TextStyle(color: Theme.of(context).colorScheme.onSurface)
      .copyWith(fontSize: Preferences.readingFontSize.value.toDouble());
  var children = <Widget>[];
  for (var c in d.document) {
    children.add(Text.rich(await richTextElementToSpan(c, context, style, chapter)));
  }
  for (var c in d.footnotes) {
    children.add(Text.rich(await richTextElementToSpan(c, context, style, chapter)));
  }
  double width = Preferences.maxTextWidth.value.toDouble();
  return SliverList.list(
      children: children
          .map((c) => Center(
                  child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: ConstrainedBox(constraints: BoxConstraints(minWidth: width, maxWidth: width), child: c),
              )))
          .toList());
}

Future<InlineSpan> richTextElementToSpan(RichTextElement e, BuildContext context, TextStyle style, Chapter chapter,
    [bool paragraphBreaks = true]) async {
  var borderColor = Theme
      .of(context)
      .dividerColor;
  switch (e) {
    case RichTextText():
      return TextSpan(text: e.content, style: style);
    case RichTextSpan():
      return TextSpan(
          children: await Future.wait(e.children.map((c) async => await  richTextElementToSpan(c, context, style, chapter, paragraphBreaks)).toList()));
    case RichTextParagraph():
      if (paragraphBreaks) {
        return WidgetSpan(
            child: Padding(
          padding: EdgeInsets.symmetric(vertical: style.fontSize! / 2.0),
          child: Text.rich(TextSpan(
              children: await Future.wait(e.children.map((c) async => await richTextElementToSpan(c, context, style,
                  chapter, paragraphBreaks)).toList()))),
        ));
      }
      return TextSpan(
          children: await Future.wait(e.children.map((c) async => await  richTextElementToSpan(c, context, style,
              chapter, paragraphBreaks)).toList()));
    case RichTextBreak():
      if (paragraphBreaks) {
        return TextSpan(text: "\n", style: style);
      }
    case RichTextCodeBlock():
      var s = style.copyWith(fontFamily: "RobotoMono");
      return WidgetSpan(
          child: Card(
              child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text.rich(
          TextSpan(
              children: await Future.wait(e.children.map((c) async => await  richTextElementToSpan(c, context, s,
                  chapter, paragraphBreaks)).toList())
          )
      ))));
    case RichTextCursive():
      var s = style.copyWith(fontStyle: FontStyle.italic);
      return TextSpan(children: await Future.wait(e.children.map((c) async => await  richTextElementToSpan(c, context, s,
          chapter, paragraphBreaks)).toList()));
    case RichTextBold():
      var s = style.copyWith(fontWeight: FontWeight.bold);
      return TextSpan(children: await Future.wait(e.children.map((c) async => await  richTextElementToSpan(c, context, s,
          chapter, paragraphBreaks)).toList()));
    case RichTextTable():
      return WidgetSpan(
          child: FlexibleTable(
              children: await Future.wait(e.cells
                  .map((c) async => FlexibleTableCell(
                        row: c.row,
                        col: c.col,
                        rowSpan: c.rowSpan,
                        colSpan: c.colSpan,
                        child: Text.rich(await richTextElementToSpan(c.child, context, style, chapter, false)),
                      ))
                  .toList())));
    case RichTextLink():
      var s = style.copyWith(color: Colors.blue);
      return TextSpan(
          mouseCursor: SystemMouseCursors.click,
          recognizer: SerialTapGestureRecognizer()..onSerialTapUp = (d) => launchUrlString(e.url, mode: LaunchMode.externalApplication),
          children: await Future.wait(e.children.map((c) async => await richTextElementToSpan(c, context, s, chapter, paragraphBreaks)).toList()));
    case RichTextImage():
      var size = null;
      var i = await appDB.chapterImage(e.image);
      if (i != null) {
        size = await _imageSize(i);
      }
      return WidgetSpan(child: StreamBuilder(stream: appDB.chapterImageWatch(e.image).asyncMap((v) async {
        if (v == null) {
          return null;
        }
        return (v, await _imageSize(v));
      }), builder: (c, v) {
        if (v.connectionState == ConnectionState.waiting) {
          if (size != null) {
            return LayoutBuilder(
                builder: (context, constraints) {
                  double maxWidth;
                  if (constraints.hasBoundedWidth) {
                    maxWidth = constraints.maxWidth;
                  } else {
                    maxWidth = Preferences.maxTextWidth.value.toDouble() - 16;
                  }
                  double scale = 1;
                  if (size.width > maxWidth) {
                    scale = maxWidth / size.width;
                  }
                  return SizedBox(width: size.width * scale, height: size.height * scale);
                }
            );;
          } else {
            return Center(child: CircularProgressIndicator());
          }
        }
        var download = Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: Container(
              decoration: ShapeDecoration(shape: Border.all(color: borderColor)),
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text("Image not found"),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(onPressed: () async {
                    await appDB.queueImage(e.image);
                  }, child: Text("Download")),
                ),
              ],),
            ),
          ),
        );
        if (! v.hasData) {
          return download;
        }
        var i = v.data;
        if (i != null) {
          return LayoutBuilder(
                  builder: (context, constraints) {
                    double maxWidth;
                    if (constraints.hasBoundedWidth) {
                      maxWidth = constraints.maxWidth;
                    } else {
                      maxWidth = Preferences.maxTextWidth.value.toDouble() - 16;
                    }
                    double scale = 1;
                    if (i.$2.width > maxWidth) {
                      scale = maxWidth / i.$2.width;
                    }
                    return Image.memory(i.$1, fit: BoxFit.scaleDown, width: i.$2.width * scale, height: i.$2.height * scale);
                  }
              );
        }
        return download;
      }));
    case RichTextAnnouncement():
      return WidgetSpan(
          child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Card(
            child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(e.title, style: style.copyWith(fontSize: style.fontSize! + 2.0)),
              ),
              Text.rich(TextSpan(
              children: await Future.wait(e.children.map((c) async => await  richTextElementToSpan(c, context, style,
                  chapter, paragraphBreaks)).toList())))
            ],
          ),
        )),
      ));
    case RichTextAuthorNote():
      return WidgetSpan(
          child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Card(
            child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("Author Note", style: style.copyWith(fontSize: style.fontSize! + 2.0)),
              ),
              Text.rich(TextSpan(
              children: await Future.wait(e.children.map((c) async => await  richTextElementToSpan(c, context, style,
                  chapter, paragraphBreaks)).toList())))
            ],
          ),
        )),
      ));
    case RichTextDivider():
      return const WidgetSpan(child: Divider());
    case RichTextFootnoteReference():
      var s = style.copyWith(fontSize: min(4, style.fontSize! - 4));
      return TextSpan(text: e.footnote.toString(), style: s);
  }
  return TextSpan(text: "", style: style);
}


Future<Size> _imageSize(Uint8List i) async {
  ui.ImmutableBuffer imb = await ui.ImmutableBuffer.fromUint8List(i);
  try {
    ui.ImageDescriptor im = await ui.ImageDescriptor.encoded(imb);
    double width = im.width.toDouble(),
        height = im.height.toDouble();
    im.dispose();
    return Size(width, height);
  } finally {
    imb.dispose();
  }
}

void _inlineElementToSpan(dom.Element e, BuildContext context, TextStyle style, List<InlineSpan> spans,
    [bool paragraphBreaks = true]) {
  String newlines = "";
  bool hadText = false;
  delayedNewlines() {
    if (!paragraphBreaks && newlines.isNotEmpty) {
      if (hadText) {
        spans.add(TextSpan(text: newlines, style: style));
      }
      newlines = "";
    }
  }

  for (var n in e.nodes) {
    if (n is dom.Text) {
      delayedNewlines();
      hadText = true;
      spans.add(TextSpan(text: n.text.replaceAll("\n", ""), style: style));
    }
    if (n is dom.Element) {
      //print(e.localName);
      //print(e.outerHtml);
      switch (n.localName) {
        case "br":
          if (!paragraphBreaks) {
            newlines += "\n";
          } else {
            spans.add(TextSpan(text: "\n", style: style));
          }
          break;
        case "strong":
          delayedNewlines();
          hadText = true;
          var st2 = style.copyWith(fontWeight: FontWeight.bold);
          List<InlineSpan> sp2 = [];
          _inlineElementToSpan(n, context, st2, sp2, paragraphBreaks);
          spans.add(TextSpan(children: sp2));
          break;
        case "em":
        case "i":
          delayedNewlines();
          hadText = true;
          var st2 = style.copyWith(fontStyle: FontStyle.italic);
          List<InlineSpan> sp2 = [];
          _inlineElementToSpan(n, context, st2, sp2, paragraphBreaks);
          spans.add(TextSpan(children: sp2));
          break;
        case "a":
          delayedNewlines();
          hadText = true;
          var st2 = style.copyWith(color: Colors.blue);
          List<InlineSpan> sp2 = [];
          _inlineElementToSpan(n, context, st2, sp2, paragraphBreaks);
          spans.add(WidgetSpan(
              child: GestureDetector(
                  onTap: () => launchUrl(Uri.parse(n.attributes["href"]!), mode: LaunchMode.externalApplication),
                  child: RichText(text: TextSpan(children: sp2)))));
          break;
        case "img":
          if (Preferences.useImages.value) {
            spans.add(WidgetSpan(child: Image.network(n.attributes["src"]!)));
          }
          break;
        case "p":
        case "div":
          delayedNewlines();
          hadText = true;
          if (!paragraphBreaks) {
            _inlineElementToSpan(n, context, style, spans, paragraphBreaks);
          } else {
            List<InlineSpan> s2 = [];
            _inlineElementToSpan(n, context, style, s2, paragraphBreaks);
            spans.add(WidgetSpan(
                child: Padding(
              padding: EdgeInsets.symmetric(vertical: style.fontSize! / 2.0),
              child: RichText(text: TextSpan(children: s2, style: style)),
            )));
          }
          break;
        case "hr":
          spans.add(WidgetSpan(child: Divider()));
          break;
        case "span":
        default:
          _inlineElementToSpan(n, context, style, spans, paragraphBreaks);
          break;
      }
    }
  }
}

SliverList chapterContentToSlivers(String content, BuildContext context) {
  //print(content);
  TextStyle style = TextStyle(color: Theme.of(context).colorScheme.onSurface)
      .copyWith(fontSize: Preferences.readingFontSize.value.toDouble());
  var frag = parseFragment(content);
  List<Widget> ws = [];
  for (var e in frag.children) {
    if (e.localName == "pre") {
      var s = style.copyWith(fontFamily: "RobotoMono");
      ws.add(Padding(
        padding: EdgeInsets.symmetric(vertical: style.fontSize! / 2),
        child: Card(
            child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: _inlineElementToWidget(e, context, s),
        )),
      ));
    }
    if (e.localName == "table") {
      var rows = e.getElementsByTagName("tr");
      List<FlexibleTableCell> cells = [];
      for (var (y, r) in rows.indexed) {
        for (var (x, c) in r.children.indexed) {
          cells.add(FlexibleTableCell(
              col: x,
              row: y,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: _inlineElementToWidget(c, context, style, false),
              )));
        }
      }
      ws.add(Card(
          child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FlexibleTable(children: cells),
      )));
    }
    if (e.classes.contains("wi_news")) {
      String title = e.children[0].nodes.last.text!;
      var body = e.children[1];
      ws.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Card(
            child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(title, softWrap: true, style: style.copyWith(fontSize: style.fontSize! + 2.0)),
              ),
              _inlineElementToWidget(body, context, style),
            ],
          ),
        )),
      ));
      continue;
    }
    if (e.classes.contains("wi_authornotes")) {
      var body = e.getElementsByClassName("wi_authornotes_body")[0];
      ws.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Card(
            child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text("Author Note", softWrap: true, style: style.copyWith(fontSize: style.fontSize! + 2.0)),
              ),
              _inlineElementToWidget(body, context, style),
            ],
          ),
        )),
      ));
      continue;
    }
    if (e.localName == "hr") {
      ws.add(Divider());
    }
    if (e.localName == "p" || e.localName == "div") {
      ws.add(Padding(
        padding: EdgeInsets.symmetric(vertical: style.fontSize! / 2),
        child: _inlineElementToWidget(e, context, style),
      ));
    }
  }
  return SliverList.list(
      children: ws
          .map((e) => Center(
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ConstrainedBox(
                      constraints: BoxConstraints(
                          minWidth: Preferences.maxTextWidth.value.toDouble(),
                          maxWidth: Preferences.maxTextWidth.value.toDouble()),
                      child: e))))
          .toList());
}

Widget _inlineElementToWidget(dom.Element p, BuildContext context, TextStyle style, [bool paragraphBreaks = true]) {
  List<InlineSpan> spans = [];
  _inlineElementToSpan(p, context, style, spans, paragraphBreaks);
  return RichText(text: TextSpan(children: spans, style: style));
}
