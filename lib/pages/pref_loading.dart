
import 'package:flutter/material.dart';
import '../prefs.dart';

import '../main.dart';

class PrefLoading extends StatelessWidget {
  const PrefLoading({super.key});

  @override
  Widget build(BuildContext context) {
    Preferences.load().whenComplete(() => router.go("/main"));
    return const Center(child: CircularProgressIndicator(),);
  }
}


