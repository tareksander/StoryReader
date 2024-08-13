import 'package:flutter/material.dart';
import 'package:html/parser.dart';
import 'package:html/dom.dart' as dom;
import 'package:story_reader/db.dart';
import 'package:story_reader/main.dart';
import 'package:story_reader/prefs.dart';
import 'package:story_reader/series_data.dart';

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
        child: CustomScrollView(restorationId: "ReadScroll",
          controller: sc,
          slivers: [
            SliverAppBar(pinned: true, title: 
              Row(
                children: [
                  ElevatedButton(
                      onPressed: () {
                        inProgress ??= (() async {
                          var chapters =
                              await appDB.chaptersForFuture(SeriesData(site: widget.chapter.site, id: widget.chapter.id));
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
            chapterContentToSlivers(widget.chapter.content!, context),
            SliverList.list(children: [
              ElevatedButton(onPressed: () => _goNext(), child: Text("Next")),
            ]),
          ],
        ),
      ),
    );
  }
}

void _inlineElementToSpan(dom.Element e, BuildContext context, TextStyle style, List<InlineSpan> spans) {
  for (var n in e.nodes) {
    if (n is dom.Text) {
      spans.add(TextSpan(text: n.text, style: style));
    }
    if (n is dom.Element) {
      //print(e.localName);
      //print(e.outerHtml);
      switch (n.localName) {
        case "br":
          spans.add(TextSpan(text: "\n", style: style));
          break;
        case "em":
        case "i":
          var st2 = style.copyWith(fontStyle: FontStyle.italic);
          List<InlineSpan> sp2 = [];
          _inlineElementToSpan(n, context, st2, sp2);
          spans.add(TextSpan(children: sp2));
          break;
        case "a":
          var st2 = style.copyWith(color: Colors.blue);
          List<InlineSpan> sp2 = [];
          _inlineElementToSpan(n, context, st2, sp2);
          spans.add(WidgetSpan(
              child: GestureDetector(
                  onTap: () {
                    // TODO open link in browser, url_opener package from flutter.dev
                  },
                  child: RichText(text: TextSpan(children: sp2)))));
          break;
        case "img":
          // TODO cache images: cached_network_image?
          if (Preferences.useImages.value) {
            spans.add(WidgetSpan(child: Image.network(n.attributes["src"]!)));
          }
          break;
        case "p":
        case "div":
          List<InlineSpan> s2 = [];
          _inlineElementToSpan(n, context, style, s2);
          spans.add(WidgetSpan(
              child: Padding(
            padding: EdgeInsets.symmetric(vertical: style.fontSize! / 2.0),
            child: RichText(text: TextSpan(children: s2, style: style)),
          )));
          break;
        case "span":
        default:
          _inlineElementToSpan(n, context, style, spans);
          break;
      }
    }
  }
}

SliverList chapterContentToSlivers(String content, BuildContext context) {
  //print(content);
  TextStyle style = const TextStyle().copyWith(fontSize: Preferences.readingFontSize.value.toDouble());
  var frag = parseFragment(content);
  List<Widget> ws = [];
  for (var e in frag.children) {
    if (e.localName == "p") {
      ws.add(Padding(
        padding: EdgeInsets.symmetric(vertical: style.fontSize! / 2),
        child: _inlineElementToWidget(e, context, style),
      ));
    }
    if (e.localName == "pre") {
      var s = style.copyWith(fontFamily: "RobotoMono");
      ws.add(Padding(
        padding: EdgeInsets.symmetric(vertical: style.fontSize! / 2),
        child: Card(child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: _inlineElementToWidget(e, context, s),
        )),
      ));
    }
    if (e.localName == "table") {
      // TODO table parsing
      var rows = e.getElementsByTagName("tr");
      // then td in tr, and in td there can be block elements, inline elements or text directly
      // Problem: There is no Flutter layout algorith similar to the CSS grid.
      ws.add(CustomScrollView(shrinkWrap: true, slivers: [
        SliverList.list(children: [Center(child: Text("Test"))])
      ],));
      
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
    }
    if (e.localName == "hr") {
      ws.add(Divider());
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

Widget _inlineElementToWidget(dom.Element p, BuildContext context, TextStyle style) {
  List<InlineSpan> spans = [];
  _inlineElementToSpan(p, context, style, spans);
  return RichText(text: TextSpan(children: spans, style: style));
}

