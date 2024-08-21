import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:story_reader/db.dart';
import 'package:story_reader/main.dart';

class LoadNetworkPage extends StatefulWidget {
  const LoadNetworkPage({super.key});

  @override
  State<LoadNetworkPage> createState() => _LoadNetworkPageState();
}

class _LoadNetworkPageState extends State<LoadNetworkPage> {
  TextEditingController ipC = TextEditingController();
  TextEditingController portC = TextEditingController();
  TextEditingController pwdC = TextEditingController();

  Future? loading;

  @override
  void dispose() {
    super.dispose();
    ipC.dispose();
    portC.dispose();
    pwdC.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: ipC,
                  decoration: InputDecoration(label: Text("IP")),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: portC,
                  decoration: InputDecoration(label: Text("Port")),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: pwdC,
                  obscureText: true,
                  decoration: InputDecoration(label: Text("Password")),
                ),
              ),
              if (loading == null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                      onPressed: () {
                        if (loading == null) {
                          setState(() {
                            loading = (() async {
                              try {
                                //print("sending");
                                var resp = await http
                                    .get(Uri(scheme: "http", host: ipC.text, port: int.parse(portC.text)), headers: {
                                  "X-Schema": appDB.schemaVersion.toString(),
                                  "X-Password": pwdC.text,
                                });
                                //print(resp.statusCode);
                                if (resp.statusCode == 200) {
                                  var data = json.decode(resp.body);
                                  await appDB.replaceDB(
                                      (data["series"] as List<dynamic>)
                                          .map((s) => Series.fromJson(s as Map<String, dynamic>))
                                          .toList(),
                                      (data["chapters"] as List<dynamic>)
                                          .map((c) => Chapter.fromJson(c as Map<String, dynamic>))
                                          .toList(),
                                      (data["chapterImages"] as List<dynamic>)
                                  .map((i) => ChapterImage.fromJson(i as Map<String, dynamic>)).toList());
                                  //print("replaced");
                                }
                              } catch (_) {}
                              router.pop();
                            })();
                          });
                        }
                      },
                      child: Text("Load")),
                )
              else
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
