import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:story_reader/series_data.dart';

part 'db.g.dart';

enum Site {
  scribbleHub,
  royalRoad;
  
  /// A string representation of a Site.
  @override
  String toString() => switch (this) {
    Site.scribbleHub => "ScribbleHub",
    Site.royalRoad => "RoyalRoad",
  };
}



@DataClassName("Series")
class SeriesTable extends Table {
  IntColumn get site => intEnum<Site>()();

  TextColumn get id => text()();

  TextColumn get name => text()();

  TextColumn get description => text()();

  BlobColumn get thumbnail => blob().nullable()();

  IntColumn get lastRead => integer().nullable()();
  DateTimeColumn get lastReadDate => dateTime().nullable()();
  
  IntColumn get thumbnailWidth => integer().nullable()();
  IntColumn get thumbnailHeight => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id, site};

  @override
  String? get tableName => "series";
}

class Chapters extends Table {
  IntColumn get site => intEnum<Site>().references(SeriesTable, #site)();
  TextColumn get id => text().references(SeriesTable, #id)();
  IntColumn get number => integer()();

  TextColumn get chapterID => text()();
  TextColumn get name => text()();
  BlobColumn get content => blob().nullable()();
  IntColumn get scrollPosition => integer().nullable()();
  BoolColumn get queued => boolean()();

  @override
  Set<Column<Object>>? get primaryKey => {site, id, number};
}


Future<File> _dbFile() async {
  final folder = await getApplicationSupportDirectory();
  return File(path.join(folder.path, "db.sqlite"));
}

LazyDatabase _open() {
  return LazyDatabase(() async {
    final file = await _dbFile();
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }
    
    final cacheBase = (await getTemporaryDirectory()).path;
    sqlite3.tempDirectory = cacheBase;
    
    return NativeDatabase.createInBackground(file);
  });
}

enum ChapterStatus {
  downloaded,
  queued,
  online,
}

final _gzip = GZipCodec(level: 9, raw: true, gzip: false);
const _utf8 = Utf8Codec();

@DriftDatabase(tables: [SeriesTable, Chapters])
class AppDB extends _$AppDB {
  AppDB([QueryExecutor? executor]) : super(executor ?? _open());
  
  String? chapterContents(Chapter c) {
    if (c.content != null) {
      return _utf8.decoder.convert(_gzip.decoder.convert(c.content!));
    }
    return null;
  }
  
  Future<List<Series>> series() async {
    return select(seriesTable).get();
  }
  
  Future<int> dbSize() async {
    return (await _dbFile()).length();
  }
  
  Future<int> imageSize() {
    return (select(seriesTable).map((s) => s.thumbnail)).get().then((l) => l.whereNotNull().map((i) => i.length).sum);
  }

  Future<int> seriesSize(Site site, String id) {
    return transaction(() async {
      var s = await (select(seriesTable)..where((s) => s.id.equals(id) & s.site.equals(site.index))).getSingle();
      var cs = await (select(chapters)
        ..where((s) => s.id.equals(id) & s.site.equals(site.index))).get();
      return (s.thumbnail?.length ?? 0) + s.name.length + s.description.length + cs.map((c) => (c.name.length ?? 0) + (c.content?.length ?? 0)).sum;
    });
  }
  
  Future<void> deleteImages() {
    return customUpdate("UPDATE series SET thumbnail = NULL", updates: {seriesTable}, updateKind: UpdateKind.update);
  }
  
  Future<void> vacuum() {
    return customStatement("VACUUM");
  }

  Future<void> deleteDB() {
    return transaction(() async {
      await delete(seriesTable).go();
      await delete(this.chapters).go();
    });
  }
  
  Future<void> replaceDB(List<Series> series, List<Chapter> chapters) {
    return transaction(() async {
      await delete(seriesTable).go();
      await delete(this.chapters).go();
      await batch((batch) async {
        batch.insertAll(seriesTable, series);
        batch.insertAll(this.chapters, chapters);
      });
    });
  }
  
  
  Stream<ChapterStatus> chapterStatus(Site site, String id, int number) {
    return (select(chapters)..where((c) => c.id.equals(id) & c.site.equals(site.index) & c.number.equals(number)))
        .watch()
        .map((cl) {
      if (cl.length != 1) {
        return ChapterStatus.online;
      }
      var c = cl.first;
      if (c.content != null) {
        return ChapterStatus.downloaded;
      }
      if (c.queued) {
        return ChapterStatus.queued;
      }
      return ChapterStatus.online;
    });
  }

  Future<void> addSeriesIfNeeded(Site site, String id, String name, String description, [Uint8List? thumbnail, int? thumbnailWidth, int? thimbnailHeight]) {
    var s = Series(site: site, id: id, name: name, description: description, thumbnail: thumbnail, thumbnailWidth: thumbnailWidth, thumbnailHeight: thimbnailHeight);
    return transaction(() async {
      var rc = await (select(seriesTable)
            ..whereSamePrimaryKey(s)
            ..limit(1))
          .get();
      if (rc.isEmpty) {
        await into(seriesTable).insert(s, mode: InsertMode.insert);
      }
    });
  }

  Future<void> deleteChapter(Site site, String id, int number) {
    var c = Chapter(site: site, id: id, number: number, chapterID: "", queued: false, name: '');
    return transaction(() async {
      var s = await (select(seriesTable)..where((s) => s.site.equals(site.index) & s.id.equals(id))).getSingleOrNull();
      if (s != null && s.lastRead == number) {
        await setLastRead(site, id, null);
      }
      await (delete(chapters)..whereSamePrimaryKey(c)).go();
    });
  }

  SimpleSelectStatement<$ChaptersTable, Chapter> _queuedChapters() {
    return (select(chapters)
      ..where((c) => c.queued.equals(true))
      ..orderBy([
        (c) => OrderingTerm(expression: c.site),
        (c) => OrderingTerm(expression: c.id),
        (c) => OrderingTerm(expression: c.number)
      ]));
  }
  
  

  Future<List<Chapter>> queuedChapters() {
    return _queuedChapters().get();
  }

  Stream<List<Chapter>> queuedChaptersStream() {
    return _queuedChapters().watch();
  }

  Future<void> setThumbnail(Site site, String id, Uint8List thumbnail, int width, int height) {
    return customUpdate(
      "UPDATE series SET thumbnail = ?, thumbnail_width = ?, thumbnail_height = ? WHERE site = ? AND id = ?",
      variables: [
        Variable.withBlob(thumbnail),
        Variable.withInt(width),
        Variable.withInt(height),
        Variable.withInt(site.index),
        Variable.withString(id),
      ],
      updates: {seriesTable},
      updateKind: UpdateKind.update,
    );
  }

  Future<void> setLastRead(Site site, String id, int? last) {
    return customUpdate(
      "UPDATE series SET last_read = ? WHERE site = ? AND id = ?",
      variables: [
        Variable(last),
        Variable.withInt(site.index),
        Variable.withString(id),
      ],
      updates: {seriesTable},
      updateKind: UpdateKind.update,
    );
  }
  
  Future<void> updateLastReadDate(Site site, String id) {
    return customUpdate(
      "UPDATE series SET last_read_date = ? WHERE site = ? AND id = ?",
      variables: [
        Variable.withDateTime(DateTime.timestamp()),
        Variable.withInt(site.index),
        Variable.withString(id),
      ],
      updates: {seriesTable},
      updateKind: UpdateKind.update,
    );
  }

  Future<void> setScrollPosition(Site site, String id, int number, int? position) {
    return customUpdate(
      "UPDATE chapters SET scroll_position = ? WHERE site = ? AND id = ? AND number = ?",
      variables: [
        Variable(position),
        Variable.withInt(site.index),
        Variable.withString(id),
        Variable.withInt(number),
      ],
      updates: {chapters},
      updateKind: UpdateKind.update,
    );
  }

  Future<void> saveChapter(Site site, String id, int number, String chapterID, String contents, String name) {
    var c =
        Chapter(site: site, id: id, number: number, queued: false, content: Uint8List.fromList(_gzip.encoder.convert(_utf8.encoder.convert(contents))), chapterID: chapterID, name: name);
    return transaction(() async {
      var res = await (select(chapters)..whereSamePrimaryKey(c)).get();
      if (res.isNotEmpty && res[0].queued) {
        await into(chapters).insertOnConflictUpdate(c);
      }
    });
  }

  Future<void> queueChapter(Site site, String name, String id, int number, String chapterID) {
    var c = Chapter(site: site, name: name, id: id, number: number, queued: true, chapterID: chapterID);
    return transaction(() async {
      var rc = await (select(chapters)
            ..whereSamePrimaryKey(c)
            ..limit(1))
          .get();
      if (rc.isEmpty) {
        await into(chapters).insert(c, mode: InsertMode.insert);
      } else {
        if (rc.first.content == null) {
          await (update(chapters)..whereSamePrimaryKey(c)).write(c);
        }
      }
    });
  }

  Future<void> queueChapters(Site site, String id, List<String> names, List<int> numbers, List<String> chapterIDs, [bool queue = true]) {
    return transaction(() async {
      var rc = await (select(chapters)
            ..where((c) => c.site.equals(site.index) & c.id.equals(id) & c.number.isIn(numbers)))
          .get();
      for (var (i, n) in numbers.indexed) {
        var a = rc.indexWhere((c) => c.number == n);
        if (a == -1) {
          rc.add(Chapter(site: site, name: names[i], id: id, number: n, chapterID: chapterIDs[i], queued: queue));
        } else {
          if (!queue || rc[a].content == null) {
            rc[a] = rc[a].copyWith(queued: queue);
          }
        }
      }
      await batch((batch) {
        batch.insertAll(chapters, rc, mode: InsertMode.insertOrReplace);
      });
    });
  }

  Future<void> dequeueChapter(Site site, String id, int number) {
    var c = Chapter(site: site, id: id, number: number, queued: false, chapterID: "", name: '');
    return transaction(() async {
      var rc = await (select(chapters)
            ..whereSamePrimaryKey(c)
            ..limit(1))
          .get();
      if (rc.isNotEmpty) {
        if (rc.first.content == null) {
          await (update(chapters)..whereSamePrimaryKey(c)).write(c);
        }
      }
    });
  }

  Future<void> dequeueAll() {
    return customUpdate("UPDATE chapters SET queued = false", updateKind: UpdateKind.update, updates: {chapters});
  }

  SimpleSelectStatement<$SeriesTableTable, Series> _downloadedSeries() {
    return select(seriesTable)
      ..where((s) => existsQuery(select(chapters)
        ..where(
            (c) => c.id.equalsExp(s.id) & c.site.equalsExp(s.site) & (c.content.isNotNull() | c.queued.equals(true)))))
      ..orderBy([(s) => OrderingTerm(expression: s.name)]);
  }

  Future<void> deleteSeries(Series s) {
    return transaction(() async {
      await (delete(seriesTable)..whereSamePrimaryKey(s)).go();
      await (delete(chapters)..where((c) => c.site.equals(s.site.index) & c.id.equals(s.id))).go();
    });
  }

  Stream<List<Series>> downloadedSeries() {
    return _downloadedSeries().watch().distinct((a, b) {
      if (a.length != b.length) {
        return false;
      }
      for (int i = 0; i < a.length; i++) {
        if (a[i].site != b[i].site || a[i].id != b[i].id) {
          return false;
        }
      }
      return true;
    });
  }

  Future<List<Series>> downloadedSeriesFuture() {
    return _downloadedSeries().get();
  }

  Stream<List<Chapter>> chaptersFor(SeriesData s) {
    return _chaptersFor(s).watch();
  }

  Future<List<Chapter>> chaptersForFuture(SeriesData s) {
    return _chaptersFor(s).get();
  }

  SimpleSelectStatement<$ChaptersTable, Chapter> _chaptersFor(SeriesData s) {
    return select(chapters)
      ..where((c) => c.id.equals(s.id) & c.site.equals(s.site.index) & c.content.isNotNull())
      ..orderBy([(c) => OrderingTerm.asc(c.number)]);
  }

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(onUpgrade: (Migrator m, int from, int to) async {
      await transaction(() async {
        if (from < 2) {
          await m.addColumn(seriesTable, seriesTable.lastReadDate);
        }
        if (from < 3) {
          await m.addColumn(seriesTable, seriesTable.thumbnailWidth);
          await m.addColumn(seriesTable, seriesTable.thumbnailHeight);
        }
        if (from < 4) {
          await m.alterTable(TableMigration(chapters, columnTransformer: {chapters.content: chapters.content.cast<Uint8List>()}));
          var cs = (await select(chapters).get()).map((c) {
            if (c.content != null) {
              var content = utf8.decode(c.content!);
              return c.copyWith(content: Value(Uint8List.fromList(_gzip.encode(_utf8.encode(content)))));
            }
            return c;
          }).toList();
          await batch((b) {
            b.replaceAll(chapters, cs);
          });
        }
      });
      if (from < 4) {
        await vacuum();
      }
    });
  }
}
