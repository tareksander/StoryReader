import 'package:flutter/material.dart';
import 'package:story_reader/main.dart';
import 'package:story_reader/prefs.dart';
import 'package:url_launcher/url_launcher.dart';

const String _releaseURL = "https://github.com/tareksander/StoryReader/releases";

class UpdatePage extends StatelessWidget {
  const UpdatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("A new version is available"),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(onPressed: () {
              launchUrl(Uri.parse(_releaseURL), mode: LaunchMode.externalApplication);
            }, child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Download"),
            )),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(onPressed: () {
              router.go("/main");
            }, child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Continue"),
            )),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(onPressed: () async {
              Preferences.ignoreVersion.value = (await newerVersionAvailable)!;
              router.go("/main");
            }, child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Ignore this version"),
            )),
          ),
        ],),
      ),
    );
  }
}

