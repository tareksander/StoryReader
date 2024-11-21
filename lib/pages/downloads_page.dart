import 'dart:async';

import 'package:flutter/material.dart';
import 'package:story_reader/download_manager.dart';
import 'package:story_reader/main.dart';

import '../db.dart';

class DownloadsPage extends StatefulWidget {
  const DownloadsPage({super.key});

  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage> {
  late StreamSubscription seriesS;
  late StreamSubscription queuedS;
  late StreamSubscription imagesS;

  List<Series>? series;
  List<Chapter>? queued;
  List<ChapterImage>? images;

  @override
  void initState() {
    super.initState();
    seriesS = appDB.downloadedSeries().listen((sl) => setState(() {
          series = sl;
        }));
    queuedS = appDB.queuedChaptersStream().listen((ql) => setState(() {
          queued = ql;
        }));
    imagesS = appDB.queuedImagesStream().listen((qi) => setState(() {
      images = qi;
    }));
  }

  @override
  void dispose() {
    super.dispose();
    seriesS.cancel();
    queuedS.cancel();
    imagesS.cancel();
  }

  @override
  Widget build(BuildContext context) {
    if (series == null || queued == null || images == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: CustomScrollView(restorationId: "downloadScroll",slivers: [
        SliverList.list(
          children: [
            Row(
              children: [
                ElevatedButton(onPressed: () => appDB.dequeueAll(), child: Text("Dequeue all")),
                StreamBuilder(
                    stream: downloadManagerActiveStream.stream,
                    builder: (c, d) {
                      if (d.data == true) {
                        return ElevatedButton(
                          onPressed: () => stopDownloadManager(),
                          child: Text("Stop"),
                        );
                      } else {
                        return ElevatedButton(
                          onPressed: () => startDownloadManager(),
                          child: Text("Start"),
                        );
                      }
                    })
              ],
            ),
            Divider()
          ],
        ),
        SliverList.separated(itemBuilder: (c, i) {
          if (i < images!.length) {
            var im = images![i];
            return Row(children: [
              Flexible(flex: 1, fit: FlexFit.tight, child: Text("Image: ${im.url}", softWrap: true)),
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: ElevatedButton(onPressed: () => appDB.dequeueImage(im.id), child: Text("Dequeue")),
              )
            ]);
          } else {
            i -= images!.length;
          }
          var c = queued![i];
          var s = series!.firstWhere((s) => s.id == c.id && s.site == c.site);
          return Row(children: [
            Flexible(flex: 1, fit: FlexFit.tight, child: Text("${s.name} - ${c.number + 1}", softWrap: true)),
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ElevatedButton(onPressed: () => appDB.dequeueChapter(c.site, c.id, c.number), child: Text("Dequeue")),
            )
          ],);
        }, separatorBuilder: (c, i) => const Divider(), itemCount: images!.length + queued!.length)
      ]),
    );
  }
}


