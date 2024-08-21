import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:story_reader/db.dart';
import 'package:story_reader/main.dart';
import 'package:story_reader/prefs.dart';
import 'package:story_reader/series_data.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  bool sortAlphabetically = true;
  
  @override
  void initState() {
    super.initState();
    sortAlphabetically = Preferences.sortAlphabetically.value;
  }
  
  @override
  Widget build(BuildContext context) {
    Size ws = MediaQuery.sizeOf(context);
    double iw = (ws.width < 500) ? ws.width / 4 : 250;
    return Scaffold(
      appBar: AppBar(
        actions: [
          Icon(Icons.abc),
          Checkbox(value: sortAlphabetically, onChanged: (v) {
            setState(() {
              sortAlphabetically = true;
              Preferences.sortAlphabetically.value = true;
            });
          }),
          Icon(Icons.calendar_month),
          Checkbox(value: ! sortAlphabetically, onChanged: (v) {
            setState(() {
              sortAlphabetically = false;
              Preferences.sortAlphabetically.value = false;
            });
          }),
        ],
      ),
      body: StreamBuilder(
          stream: appDB.downloadedSeries(),
          builder: (c, d) {
            if (!d.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (! sortAlphabetically) {
              d.data!.sortBy((e) => e.lastReadDate ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true));
              d.data!.reverseRange(0, d.data!.length);
            }
            return Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: ListView.separated(
                  restorationId: "libraryScroll",
                  itemBuilder: (c, i) {
                    var s = d.data![i];
                    return Row(
                      children: [
                        if (Preferences.useImages.value && s.thumbnail != null)
                          Builder(
                            builder: (context) {
                              var factor = max(s.thumbnailWidth! / iw, 1.0);
                              return GestureDetector(
                                onTap: () => router.push("/series", extra: s.toJson()),
                                child: ConstrainedBox(
                                    constraints: BoxConstraints(minWidth: iw, maxWidth: iw),
                                    child: Center(child: Image.memory(s.thumbnail!, fit: BoxFit.scaleDown, width: iw, height: s.thumbnailHeight! / factor,))),
                              );
                            }
                          ),
                        Flexible(
                            child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: ElevatedButton(
                              onPressed: () => router.push("/series", extra: s.toJson()),
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Text(s.name, softWrap: true),
                              )),
                        )),
                        if (s.lastRead != null)
                          Flexible(
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: ElevatedButton(
                                  onPressed: () async => router.push("/read",
                                      extra: (await appDB.chaptersForFuture(SeriesData(site: s.site, id: s.id)))
                                          .firstWhere((c) => c.number == s.lastRead)
                                          .toJson()),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Text("Continue"),
                                  )),
                            ),
                          ),
                      ],
                    );
                  },
                  itemCount: d.data!.length,
                  separatorBuilder: (c, i) => const Divider(),
                ),
              ),
            );
          }),
    );
  }
}
