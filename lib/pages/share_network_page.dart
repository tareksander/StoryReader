import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import '../main.dart';

class ShareNetworkPage extends StatefulWidget {
  const ShareNetworkPage({super.key});

  @override
  State<ShareNetworkPage> createState() => _ShareNetworkPageState();
}

class _ShareNetworkPageState extends State<ShareNetworkPage> {
  late String password;
  late int port;
  HttpServer? server;

  @override
  void initState() {
    super.initState();
    _genPassword();
    // TODO get an unused port somehow? Maybe bind a HttpServer manually and use serveRequests instead
    // or use port 0, though that leads to ugly port numbers
    port = 10000 + Random.secure().nextInt(200);
    bool used = false;
    shelf_io.serve((r) async {
      if (!used) {
        used = true;
        var clientDBVersion = r.headers["X-Schema"];
        var clientPassword = r.headers["X-Password"];
        if (clientPassword != password) {
          router.pop();
          return Response(403, body: "Invalid password");
        }
        if (clientDBVersion == null || int.tryParse(clientDBVersion) != appDB.schemaVersion) {
          router.pop();
          return Response(406, body: "Schema mismatch");
        }
        var resp = <String, dynamic>{
          "series": (await appDB.select(appDB.seriesTable).get()).map((s) => s.toJson()).toList(),
          "chapters": (await appDB.select(appDB.chapters).get()).map((c) => c.toJson()).toList(),
          "chapterImages": (await appDB.select(appDB.chapterImages).get()).map((i) => i.toJson()).toList(),
        };
        if (mounted) {
          router.pop();
        }
        return Response(200, body: json.encode(resp));
      }
      return Response(403, body: "Connection already used");
    }, InternetAddress.anyIPv4, port, poweredByHeader: null, ).then((s) {
      if (!mounted) {
        s.close();
      }
    }).onError((e, _) {
      router.pop();
    });
    
  }

  void _genPassword() {
    Random r = Random.secure();
    String pwd = "";
    String chars = "abcdefghijklmnopqrstuvwxyz";
    // Remove uppercase chars, I and l are not really distinguishable
    //chars += chars.toUpperCase();
    chars += "0123456789";
    const pwdLen = 6;
    for (int i = 0; i < pwdLen; i++) {
      pwd += chars[r.nextInt(chars.length)];
    }
    password = pwd;
  }

  @override
  void dispose() {
    super.dispose();
    server?.close();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              children: [
                Text(
                    "A one-time-password will be generated to authenticate the library transfer, but the transfer itself is not encrypted. Only do this in trusted networks.",
                    softWrap: true),
                Text("Port: $port"),
                Text("Password: $password"),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
