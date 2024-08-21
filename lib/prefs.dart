import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


final class Preferences {
  Preferences._();
  
  static late SharedPreferences _prefs;
  static Future<void>? _loading;
  
  
  static Future<void> load() {
    _loading ??= () async {
        _prefs = await SharedPreferences.getInstance();
        
        _setupNotifier(useImages, "thumbnails", true);
        _setupNotifier(readingFontSize, "readingFontSize", 14);
        _setupNotifier(maxTextWidth, "maxTextWidth", 1000);
        _setupNotifier(sortAlphabetically, "librarySort", true);
        _setupNotifier(ignoreVersion, "ignoreVersion", null);
      }();
    return _loading!;
  }
  
  static ValueNotifier<bool> useImages = ValueNotifier(true);
  static ValueNotifier<int> readingFontSize = ValueNotifier(14);
  static ValueNotifier<int> maxTextWidth = ValueNotifier(1000);
  static ValueNotifier<bool> sortAlphabetically = ValueNotifier(true);
  static ValueNotifier<String?> ignoreVersion = ValueNotifier(null);


  static void _setOrRemove<T>(String key, T? value) {
    if (value == null) {
      _prefs.remove(key);
    } else {
      if (typeOrNull<T, int>()) {
        _prefs.setInt(key, value as int);
      }
      if (typeOrNull<T, bool>()) {
        _prefs.setBool(key, value as bool);
      }
      if (typeOrNull<T, String>()) {
        _prefs.setString(key, value as String);
      }
    }
  }

  static void _setupNotifier<T>(ValueNotifier<T> n, String key, T def) {
    n.value = _prefs.get(key) as T? ?? def;
    n.addListener(() => _setOrRemove(key, n.value));
  }
  
}

Type _type<T>() => T;

bool typeOrNull<A, B>() {
  return A == B || A == _type<B?>();
}
