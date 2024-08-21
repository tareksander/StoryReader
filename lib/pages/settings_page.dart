import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:story_reader/prefs.dart';

import '../main.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  TextEditingController sizeC = TextEditingController(text: Preferences.readingFontSize.value.toString());
  TextEditingController widthC = TextEditingController(text: Preferences.maxTextWidth.value.toString());
  
  
  @override
  void initState() {
    super.initState();
    sizeC.addListener(() {
      var size = int.tryParse(sizeC.text, radix: 10);
      if (size != null && size >= 6 && size <= 50) {
        Preferences.readingFontSize.value = size;
      }
    });
    widthC.addListener(() {
      var width = int.tryParse(widthC.text, radix: 10);
      if (width != null && width >= 100 && width <= 5000) {
        Preferences.readingFontSize.value = width;
      }
    });
    
  }
  
  @override
  void dispose() {
    super.dispose();
    sizeC.dispose();
    widthC.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(restorationId: "SettingsScroll",
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(children: [
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 32.0),
                    child: Text("Reading font size: ", softWrap: true),
                  ),
                ), ConstrainedBox(constraints: BoxConstraints(maxWidth: 100), child: TextField(controller: sizeC))
              ],),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(children: [
                Padding(
                  padding: const EdgeInsets.only(right: 32.0),
                  child: Text("Use images: "),
                ), Switch(value: Preferences.useImages.value, onChanged: (v) {
                  setState(() {
                    Preferences.useImages.value = v;
                  });
                })
              ],),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(children: [
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 32.0),
                    child: Text("Maximum text width (in pixels): ", softWrap: true),
                  ),
                ), ConstrainedBox(constraints: BoxConstraints(maxWidth: 150), child: TextField(controller: widthC))
              ],),
            ),
            FutureBuilder(future: Future.wait([appDB.dbSize(), appDB.imageSize()]), builder: (c, d) {
              if (d.hasError) {
                return const SizedBox.shrink();
              }
              if (! d.hasData) {
                return const CircularProgressIndicator();
              }
              double dbSize = d.data![0].toDouble() / 1000000.0;
              double imageSize = d.data![1].toDouble() / 1000000.0;
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Row(children: [
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text("Current library size: ${dbSize.toStringAsFixed(2)}MB", softWrap: true),
                        ),
                      )
                    ],),
                    Row(children: [
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text("Current image storage: ${imageSize.toStringAsFixed(2)}MB", softWrap: true),
                        ),
                      )
                    ],),
                  ],
                ),
              );
            }),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(children: [
                ElevatedButton(onPressed: () => _showDeleteImages(context), child: Text("Delete images"))
              ],),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(children: [
                ElevatedButton(onPressed: () => _showDeleteLibrary(context), child: Text("Delete library"))
              ],),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(children: [
                ElevatedButton(onPressed: () => appDB.vacuum(), child: Text("Compact library"))
              ],),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(children: [
                ElevatedButton(onPressed: () => router.push("/shareNet"), child: Text("Share library"))
              ],),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(children: [
                ElevatedButton(onPressed: () => router.push("/loadNet"), child: Text("Load library"))
              ],),
            ),
            Padding(padding: const EdgeInsets.all(8.0), child: Row(
              children: [
                ElevatedButton(onPressed: () => router.push("/licenses"), child: Text("Licenses"),),
              ],
            ),)
          ],
        ),
      ),
    );
  }

  Future<dynamic> _showDeleteImages(BuildContext c) {
    return showDialog(
        builder: (c) =>
            FractionallySizedBox(
                heightFactor: 0.5,
                widthFactor: 0.5,
                child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: IntrinsicHeight(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(bottom: 32.0),
                              child: Text("Really delete all images?"),
                            ),
                            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                              ElevatedButton(onPressed: () => router.pop(), child: const Text("No")),
                              ElevatedButton(
                                  onPressed: () async {
                                    await appDB.deleteImages();
                                    await appDB.vacuum();
                                    setState(() {});
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

  Future<dynamic> _showDeleteLibrary(BuildContext c) {
    return showDialog(
        builder: (c) =>
            FractionallySizedBox(
                heightFactor: 0.5,
                widthFactor: 0.5,
                child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: IntrinsicHeight(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(bottom: 32.0),
                              child: Text("Really delete all series?"),
                            ),
                            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                              ElevatedButton(onPressed: () => router.pop(), child: const Text("No")),
                              ElevatedButton(
                                  onPressed: () async {
                                    await appDB.deleteDB();
                                    await appDB.vacuum();
                                    setState(() {});
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
