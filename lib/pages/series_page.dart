import 'package:flutter/material.dart';
import 'package:story_reader/db.dart';
import 'package:story_reader/main.dart';
import 'package:story_reader/series_data.dart';

class SeriesPage extends StatefulWidget {
  final Series series;

  const SeriesPage(this.series, {super.key});

  @override
  State<SeriesPage> createState() => _SeriesPageState();
}

class _SeriesPageState extends State<SeriesPage> {
  Future? inProgress;

  @override
  void initState() {
    super.initState();
    appDB.updateLastReadDate(widget.series.site, widget.series.id);
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.sizeOf(context);
    const int breakpoint = 500;
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder(
            stream: appDB.chaptersFor(SeriesData(site: widget.series.site, id: widget.series.id)),
            builder: (c, d) {
              if (!d.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              var chapters = d.data!;
              return CustomScrollView(
                restorationId: "SeriesScroll",
                slivers: [
                  // TODO change layout on smaller screens
                  SliverAppBar(
                    pinned: true,
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                            flex: 3,
                            child: Text(widget.series.name, softWrap: true, style: const TextStyle(fontSize: 20))),
                        if (size.width >= breakpoint) _deleteButton(c),
                        if (widget.series.lastRead != null && size.width >= breakpoint) _continueButton(chapters),
                        if (size.width >= breakpoint) _netButton(),
                      ],
                    ),
                    actions: [
                      if (size.width < breakpoint)
                        if (inProgress == null)
                          PopupMenuButton(
                            itemBuilder: (c) {
                              return [
                                const PopupMenuItem(
                                  child: Text("Delete"),
                                  value: 0,
                                ),
                                const PopupMenuItem(
                                  child: Text("Online Version"),
                                  value: 1,
                                ),
                                if (widget.series.lastRead != null)
                                  const PopupMenuItem(
                                    child: Text("Continue"),
                                    value: 2,
                                  )
                              ];
                            },
                            onSelected: (v) {
                              if (v == 0) {
                                _showDeleteDialog(context);
                              }
                              if (v == 1) {
                                _doNet();
                              }
                              if (v == 2 && widget.series.lastRead != null) {
                                _doContinue(chapters);
                              }
                            },
                          )
                        else
                          const CircularProgressIndicator()
                    ],
                  ),
                  SliverList.separated(
                    itemBuilder: (c, i) {
                      var c = chapters[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          children: [
                            Flexible(
                              fit: FlexFit.tight,
                              flex: 3,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 32.0),
                                child: Text("${c.number + 1} - ${c.name}", softWrap: true),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 32.0),
                              child: ElevatedButton(
                                  onPressed: () => router.push("/read", extra: c.toJson()), child: const Text("Read")),
                            ),
                            ElevatedButton(
                                onPressed: () => appDB.deleteChapter(widget.series.site, widget.series.id, c.number),
                                child: const Text("Delete")),
                          ],
                        ),
                      );
                    },
                    separatorBuilder: (c, i) => const Divider(),
                    itemCount: chapters.length,
                  ),
                ],
              );
            }),
      ),
    );
  }

  Flexible _netButton() {
    return Flexible(
        flex: 1,
        child: ElevatedButton(
            onPressed: () => _doNet(),
            child: (inProgress == null)
                ? const Text("Online Version", softWrap: true)
                : const CircularProgressIndicator()));
  }

  void _doNet() {
    setState(() {
      inProgress ??= (() async {
        var s = (await shC.series(widget.series.id, widget.series.name)).body!;
        var extra = <String, dynamic>{
          "id": s.id,
          "site": s.site.index,
          "name": s.name,
        };
        router.push("/seriesNet", extra: extra);
        setState(() {
          inProgress = null;
        });
      })();
    });
  }

  Flexible _continueButton(List<Chapter> chapters) {
    return Flexible(
        child: ElevatedButton(
      onPressed: () => _doContinue(chapters),
      child: const Text("Continue"),
    ));
  }

  Future<Object?> _doContinue(List<Chapter> chapters) =>
      router.push("/read", extra: chapters.firstWhere((c) => c.number == widget.series.lastRead).toJson());

  Flexible _deleteButton(BuildContext c) {
    return Flexible(
        flex: 1,
        child: ElevatedButton(onPressed: () => _showDeleteDialog(c), child: const Text("Delete", softWrap: true)));
  }

  Future<dynamic> _showDeleteDialog(BuildContext c) async {
    var size = (await appDB.seriesSize(widget.series.site, widget.series.id)).toDouble() / 1000000.0;
    return showDialog(
        builder: (c) => FractionallySizedBox(
            heightFactor: 0.5,
            widthFactor: 0.5,
            child: Card(
                child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(bottom: 32.0),
                      child: Text("Really delete this series? It currently uses ${size.toStringAsFixed(2)}MB of storage."),
                    ),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                      ElevatedButton(onPressed: () => router.pop(), child: const Text("No")),
                      ElevatedButton(
                          onPressed: () {
                            appDB.deleteSeries(widget.series);
                            appDB.vacuum();
                            router.pop();
                            router.pop();
                          },
                          child: const Text("Yes")),
                    ]),
                  ],
                ),
              ),
            ))),
        context: c);
  }
}
