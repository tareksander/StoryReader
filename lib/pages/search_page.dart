import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:story_reader/main.dart';
import 'package:story_reader/prefs.dart';

import '../series_data.dart';

String _searchTerm = "";
List<SeriesData>? _result;

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController text = TextEditingController();
  Future<List<SeriesData>>? req;

  @override
  void dispose() {
    super.dispose();
    _searchTerm = text.text;
    text.dispose();
  }

  @override
  void initState() {
    super.initState();
    text.text = _searchTerm;
    if (_result != null) {
      req = Future.value(_result);
    }
  }

  @override
  Widget build(BuildContext context) {
    Size ws = MediaQuery.sizeOf(context);
    double iw = (ws.width < 500) ? ws.width / 3 : 250;
    return SingleChildScrollView(restorationId: "SearchScroll",
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          children: [
            Flex(
              direction: Axis.horizontal,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(child: TextField(controller: text, onEditingComplete: () => doSearch())),
                Flexible(
                    flex: 0,
                    child: ElevatedButton(
                      onPressed: () => doSearch(),
                      child: Text("Search"),
                    ))
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4.0),
              child: Divider(),
            ),
            FutureBuilder(
                key: Key("futureSearch:${text.text}"),
                future: req,
                initialData: _result,
                builder: (c, d) {
                  if (d.connectionState == ConnectionState.none || d.hasError) {
                    return const SizedBox.shrink();
                  }
                  if (d.hasData) {
                    _result = d.data!;
                    return Column(
                        children: d.data!
                            .map((s) => Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      if (Preferences.useImages.value && s.thumbnail != null)
                                        ConstrainedBox(constraints: BoxConstraints(minWidth: iw, maxWidth: iw),
                                        child: Center(child: Image.memory(s.thumbnail!, fit: BoxFit.scaleDown))),
                                      Flexible(
                                        child: Padding(
                                          padding: const EdgeInsets.only(left: 8.0),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Flexible(
                                                child: TextButton(
                                                    onPressed: () {
                                                      var extra = <String, dynamic>{
                                                        "id": s.id,
                                                        "site": s.site.index,
                                                        "name": s.name,
                                                      };
                                                      router.push("/seriesNet", extra: extra);
                                                    },
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(8.0),
                                                      child: Text(s.name, softWrap: true,),
                                                    )),
                                              ),
                                              Flexible(child: Text("Site: ${s.site.toString()}", softWrap: true,))
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList());
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                })
          ],
        ),
      ),
    );
  }

  void doSearch() {
    if (text.text.length > 2) {
      setState(() {
        _result = null;
        req = Future.wait([shC.simpleSearch(text.text).then((r) => r.body!).onError((e, t) => []), rrC.simpleSearch(text.text).then((r) {
          var l = r.body!;
          return l.getRange(0, min(l.length, 10));
        }).onError((e, t) => [])]).then((l) => l.flattened.sortedBy((s) => s.name).toList());
      });
    }
  }
}
