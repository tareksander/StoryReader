


import 'dart:io';

import 'package:story_reader/rr.dart';

void main() async {
  var rr = RRAPI.create();
  var s = (await rr.simpleSearch("God of")).body![0];
  var c = (await rr.series(s.id, s.name)).body!.$2[1];
  var content = (await rr.chapterContents(s, c.id, c.name)).body!.content!;
  print(content);
}

