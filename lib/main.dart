import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/localizations.dart';
import 'package:story_reader/db.dart';
import 'package:story_reader/download_manager.dart';
import 'package:story_reader/pages/load_network_page.dart';
import 'package:story_reader/pages/read_page.dart';
import 'package:story_reader/pages/series_net_page.dart';
import 'package:story_reader/pages/series_page.dart';
import 'package:story_reader/pages/share_network_page.dart';
import 'package:story_reader/rr.dart';
import 'package:story_reader/series_data.dart';
import 'package:story_reader/sh.dart';
import 'pages/main_page.dart';
import 'pages/pref_loading.dart';

final router = GoRouter(routes: [
  GoRoute(path: "/", pageBuilder: (c, s) => const MaterialPage(child: PrefLoading())),
  GoRoute(path: "/main", pageBuilder: (c, s) => const MaterialPage(child: RootRestorationScope(restorationId: "mainPage", child: MainPage()))),
  GoRoute(path: "/seriesNet", pageBuilder: (c, s) {
    var e = s.extra as Map<String, dynamic>;
    return MaterialPage(child: RootRestorationScope(restorationId: "seriesNet", child: SeriesNetPage(site: Site.values[e["site"]], id: e["id"], name: e["name"])));
  }),
  GoRoute(path: "/series", pageBuilder: (c, s) {
    var e = Series.fromJson(s.extra as Map<String, dynamic>);
    return MaterialPage(child: RootRestorationScope(restorationId: "series", child: SeriesPage(e)));
  }),
  GoRoute(path: "/read", pageBuilder: (c, s) {
    var e = Chapter.fromJson(s.extra as Map<String, dynamic>);
    return MaterialPage(child: RootRestorationScope(restorationId: "read", child: ReadPage(e, key: Key(e.number.toString()))));
  }),
  GoRoute(path: "/shareNet", pageBuilder: (c, s) => MaterialPage(child: RootRestorationScope(restorationId: "shareNet", child: ShareNetworkPage()))),
  GoRoute(path: "/loadNet", pageBuilder: (c, s) => MaterialPage(child: RootRestorationScope(restorationId: "loadNet", child: LoadNetworkPage()))),
  GoRoute(path: "/licenses", pageBuilder: (c, s) => MaterialPage(child: LicensePage()))
], restorationScopeId: "router");

late AppDB appDB;

final shC = SHAPI.create();
final rrC = RRAPI.create();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(["Roboto", "RobotoMono"], await rootBundle.loadString("fonts/LICENSE.txt"));
  });
  appDB = AppDB();
  // For this schema version, to migrations on the main thread, since they won't work in the drift isolate.
  // TODO remove this for 1.0 and require a reinstall from 0.9.0, not 0.9.1
  if (appDB.schemaVersion >= 3) {
    await (() async {
      for (var s in await appDB.series()) {
        if (s.thumbnail != null && (s.thumbnailWidth == null || s.thumbnailHeight == null)) {
          //print("migrated ${s.name}");
          var b = await ImmutableBuffer.fromUint8List(s.thumbnail!);
          var i = await ImageDescriptor.encoded(b);
          var w = i.width;
          var h = i.height;
          b.dispose();
          i.dispose();
          await appDB.setThumbnail(s.site, s.id, s.thumbnail!, w, h);
        }
      }
    })();
  }
  startDownloadManager();
  runApp(const RootRestorationScope(restorationId: "root", child: ProviderScope(child: MainApp())));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: "StoryReader",
      routerConfig: router,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate],
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark)),
      restorationScopeId: "app",
      debugShowCheckedModeBanner: false,
    );
  }
}
