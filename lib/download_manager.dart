

import 'dart:async';
import 'dart:isolate';

import 'package:drift/isolate.dart';
import 'package:flutter/cupertino.dart';
import 'package:story_reader/db.dart';
import 'package:story_reader/main.dart';
import 'package:story_reader/series_data.dart';
import 'package:http/http.dart' as http;


void startDownloadManager() {
  if (_downloadManager == null) {
    _chapterDownloadManager();
  }
}

void stopDownloadManager() {
  var d = _downloadManager;
  if (d != null) {
    d.kill();
  }
}

final StreamController<bool> downloadManagerActiveStream = (() {
  var c = StreamController<bool>.broadcast();
  c.onListen = () => c.add(_downloadManagerActive.value);
  return c;
})();
final ValueNotifier<bool> _downloadManagerActive = (() {
  var v = ValueNotifier(false);
  v.addListener(() => downloadManagerActiveStream.add(v.value));
  return v;
})();
Isolate? _downloadManager;



void _chapterDownloadManager() async {
  var client = http.Client();
  var connection = await appDB.serializableConnection();
  var exit = ReceivePort();
  exit.listen((_) {
    _downloadManager = null;
    _downloadManagerActive.value = false;
  });
  _downloadManagerActive.value = true;
  var i = await Isolate.spawn((_) async {
    var db = AppDB(await connection.connect());
    while (true) {
      var l = await db.queuedChapters();
      var sl = await db.series();
      var il = await db.queuedImages();
      try {
        for (var im in il) {
          await db.setImageData(im.id, (await client.get(Uri.parse(im.url))).bodyBytes);
        }
        for (var c in l) {
          var s = sl.firstWhere((s) => s.site == c.site && s.id == c.id);
          ChapterData data;
          switch (c.site) {
            case Site.scribbleHub:
              data = (await shC.chapterContents(SeriesData(site: c.site, id: c.id, name: s.name), c.chapterID)).body!;
            case Site.royalRoad:
              data = (await rrC.chapterContents(SeriesData(site: c.site, id: c.id, name: s.name), c.chapterID, c.name)).body!;
          }
          await db.saveChapter(c.site, c.id, c.number, c.chapterID, data.content!, data.name);
          await Future.delayed(Duration.zero);
        }
      } catch (e) {
        await Future.delayed(const Duration(seconds: 5));
      }
      await Future.delayed(const Duration(seconds: 1));
    }
  }, [], errorsAreFatal: true, debugName: "Download Isolate", onExit: exit.sendPort);
  _downloadManager = i;
}






