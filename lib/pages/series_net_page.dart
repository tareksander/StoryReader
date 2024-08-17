import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:story_reader/db.dart';
import 'package:story_reader/download_manager.dart';
import 'package:story_reader/main.dart';
import 'package:story_reader/prefs.dart';
import 'dart:ui' as ui;

import '../series_data.dart';

class SeriesNetPage extends StatefulWidget {
  final Site site;
  final String id;
  final String name;

  const SeriesNetPage({super.key, required this.site, required this.id, required this.name});

  @override
  State<SeriesNetPage> createState() => _SeriesNetPageState();
}

class _SeriesNetPageState extends State<SeriesNetPage> {
  late Future<SeriesData> req;

  List<ChapterData>? chapters;
  
  Future<void> _setThumbnail(Uint8List? thumbnail) async {
    if (Preferences.useImages.value && thumbnail != null) {
      var b = await ui.ImmutableBuffer.fromUint8List(thumbnail);
      var i = await ui.ImageDescriptor.encoded(b);
      var w = i.width;
      var h = i.height;
      i.dispose();
      b.dispose();
      appDB.setThumbnail(widget.site, widget.id, thumbnail, w, h);
    }
  }
  
  @override
  void initState() {
    super.initState();
    switch (widget.site) {
      case Site.scribbleHub:
        req = shC.series(widget.id, widget.name).then((r) async {
          var b = r.body!;
          var thumbnail = b.thumbnail;
          await _setThumbnail(thumbnail);
          return b;
        });
        
        shC
            .chapters(widget.id)
            .then((r) => r.body!)
            .then((cs) => setState(() {
                  chapters = cs.reversed.toList();
                }))
            .onError((d, t) => router.pop());
      case Site.royalRoad:
        req = rrC.series(widget.id, widget.name).then((r) async {
          var b = r.body!;
          var s = b.$1;
          var cl = b.$2;
          var thumbnail = s.thumbnail;
          await _setThumbnail(thumbnail);
          setState(() {
            chapters = cl;
          });
          return s;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder(
            future: req,
            builder: (c, d) {
              if (d.hasError) {
                router.pop();
                return const Center(child: CircularProgressIndicator());
              }
              if (d.hasData) {
                var s = d.data!;
                return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: CustomScrollView(restorationId: "SeriesNetScroll",
                      slivers: [
                        SliverAppBar(
                          pinned: true,
                          title: Row(
                            children: [
                              Flexible(
                                flex: 1,
                                child: Text(
                                  s.name,
                                  style: const TextStyle(fontSize: 30),
                                  softWrap: true,
                                ),
                              )
                            ],
                          ),
                        ),
                        SliverList.list(children: [
                          Row(
                            children: [
                              if (Preferences.useImages.value && s.thumbnail != null)
                                Flexible(
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: ConstrainedBox(
                                        constraints: const BoxConstraints(minWidth: 250, maxWidth: 250),
                                        child: Center(child: Image.memory(s.thumbnail!, fit: BoxFit.scaleDown))),
                                  ),
                                ),
                              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text("Site: ${s.site.toString()}"),
                                Text(
                                  "Views: ${s.views}",
                                  textAlign: TextAlign.start,
                                ),
                                Text("Likes: ${s.favourites}"),
                                Text("Followers: ${s.follows}"),
                                Text("Rating: ${s.score.toStringAsFixed(2)}"),
                                Text("Number of ratings: ${s.ratings}"),
                                Text("Chapters: ${s.chapters}"),
                                (() {
                                  if (s.contentWarnings.isEmpty) {
                                    return const SizedBox.shrink();
                                  }
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Content warnings:"),
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: s.contentWarnings.map((w) => Text(w.name())).toList()),
                                      )
                                    ],
                                  );
                                })(),
                              ]),
                            ],
                          ),
                          Divider(),
                          SelectableText(s.description),
                          Divider(),
                        ]),
                        ...(() {
                          var l = <SliverList>[];
                          if (chapters == null) {
                            l.add(SliverList.list(children: const [Center(child: CircularProgressIndicator())]));
                          } else {
                            l.add(SliverList.list(children: [
                              Row(
                                children: [
                                  const Flexible(
                                    fit: FlexFit.tight,
                                    child: Text(
                                      "Chapters:",
                                      style: TextStyle(fontSize: 20),
                                      softWrap: true,
                                    ),
                                  ),
                                  ElevatedButton(
                                      onPressed: () {
                                        appDB.addSeriesIfNeeded(
                                            widget.site, widget.id, s.name, s.description, s.thumbnail);
                                        List<int> indexes = [];
                                        List<String> ids = [];
                                        List<String> names = [];
                                        for (var (i, c) in chapters!.indexed) {
                                          indexes.add(i);
                                          ids.add(c.id);
                                          names.add(c.name);
                                        }
                                        appDB.queueChapters(widget.site, widget.id, names, indexes, ids);
                                        startDownloadManager();
                                      },
                                      child: Text("Download all")),
                                ],
                              ),
                              Divider(),
                            ]));
                            l.add(SliverList.separated(
                              itemBuilder: (_, i) {
                                var c = chapters![i];
                                return Row(
                                  children: [
                                    Flexible(fit: FlexFit.tight, child: Text(c.name, softWrap: true)),
                                    StreamBuilder(
                                        stream: appDB.chapterStatus(widget.site, widget.id, i),
                                        builder: (_, d) {
                                          if (d.hasData) {
                                            var status = d.data!;
                                            switch (status) {
                                              case ChapterStatus.downloaded:
                                                return ElevatedButton(
                                                    onPressed: () {
                                                      appDB.deleteChapter(widget.site, widget.id, i);
                                                    },
                                                    child: Text("Delete"));
                                              case ChapterStatus.queued:
                                                return ElevatedButton(
                                                    onPressed: () {
                                                      appDB.dequeueChapter(widget.site, widget.id, i);
                                                    },
                                                    child: Text("Unqueue"));
                                              case ChapterStatus.online:
                                                return ElevatedButton(
                                                    onPressed: () {
                                                      appDB.addSeriesIfNeeded(
                                                          widget.site, widget.id, s.name, s.description, s.thumbnail);
                                                      appDB.queueChapter(widget.site, c.name, widget.id, i, c.id);
                                                      startDownloadManager();
                                                    },
                                                    child: Text("Download"));
                                            }
                                          }
                                          return SizedBox.shrink();
                                        })
                                  ],
                                );
                              },
                              separatorBuilder: (c, i) => const Divider(),
                              itemCount: chapters!.length,
                            ));
                          }
                          return l;
                        })(),
                      ],
                    ));
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            }),
      ),
    );
  }
}

