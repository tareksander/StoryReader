
import 'package:flutter/material.dart';
import '../prefs.dart';

import '../main.dart';

class PrefLoading extends StatelessWidget {
  const PrefLoading({super.key});

  @override
  Widget build(BuildContext context) {
    Preferences.load().whenComplete(() {
      router.go("/main");
      Future.microtask(() async {
        String? n = await newerVersionAvailable;
        String? ignore = Preferences.ignoreVersion.value;
        if (n != null && (n != ignore)) {
          router.go("/update");
        }
      });
    });
    return const Center(child: CircularProgressIndicator(),);
  }
}


