import 'package:flutter/material.dart';
import 'package:story_reader/pages/downloads_page.dart';
import 'package:story_reader/pages/library_page.dart';
import 'package:story_reader/pages/search_page.dart';
import 'package:story_reader/pages/settings_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  TabController? tc;
  
  static const _tabIndexKey = "tabIndex";
  
  @override
  void initState() {
    super.initState();
  }
  
  @override
  void dispose() {
    super.dispose();
    tc?.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (tc == null) {
      tc = TabController(length: 4, initialIndex: RestorationScope.maybeOf(context)?.read(_tabIndexKey) ?? 1, vsync: this);
      tc!.addListener(() {
        if (mounted) {
          RestorationScope.maybeOf(context)?.write(_tabIndexKey, tc!.index);
        }
      });
    }
    return SafeArea(
      child: Scaffold(
          appBar: TabBar(
            controller: tc,
            tabs: const [Tab(text: "Settings"), Tab(text: "Library"), Tab(text: "Search"), Tab(text: "Downloads")],
          ),
          body: TabBarView(controller: tc, children: const [
            SettingsPage(key: PageStorageKey(SettingsPage)),
            LibraryPage(key: PageStorageKey(LibraryPage)),
            SearchPage(key: PageStorageKey(SearchPage)),
            DownloadsPage(key: PageStorageKey(DownloadsPage))
          ])),
    );
  }
}
