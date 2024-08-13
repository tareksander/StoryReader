import 'dart:typed_data';

import 'package:story_reader/db.dart';

enum CW {
  sexual,
  language,
  gore,
  mature,
}

extension CWLocaleString on CW {
  String name() {
    switch (this) {
      case CW.sexual:
        return "Sexual content";
      case CW.language:
        return "Strong language";
      case CW.gore:
        return "Gore";
      case CW.mature:
        return "Mature content";
    }
  }
}


final class SeriesData {
  Site site;
  String name;
  String description;
  String id;
  Set<CW> contentWarnings;

  int chapters;
  double score;
  int views;
  int favourites;
  int follows;
  int ratings;
  
  Uint8List? thumbnail;

  SeriesData(
      {required this.site,
      this.name = "",
      this.description = "",
      required this.id,
      this.contentWarnings = const <CW>{},
      this.chapters = 0,
      this.score = 0.0,
      this.views = 0,
      this.favourites = 0,
      this.follows = 0,
      this.ratings = 0,
      this.thumbnail});

  @override
  String toString() {
    return 'SeriesData{site: $site, name: $name, id: $id, contentWarnings: $contentWarnings, chapters: $chapters, score: $score, views: $views, favourites: $favourites, follows: $follows, ratings: $ratings}';
  }
}

final class ChapterData {
  String id;
  String name;
  String? content;

  ChapterData(this.id, this.name, [this.content]);

  @override
  String toString() {
    return 'ChapterData{id: $id, name: $name}';
  }
}
