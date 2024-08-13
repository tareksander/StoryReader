

import 'dart:async';
import 'dart:isolate';

import 'package:drift/isolate.dart';
import 'package:flutter/cupertino.dart';
import 'package:story_reader/db.dart';
import 'package:story_reader/main.dart';
import 'package:story_reader/series_data.dart';



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
      try {
        for (var c in l) {
          ChapterData data;
          switch (c.site) {
            case Site.scribbleHub:
              data = (await shC.chapterContents(SeriesData(site: c.site, id: c.id), c.chapterID)).body!;
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






