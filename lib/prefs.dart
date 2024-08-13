import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


final class Preferences {
  Preferences._();
  
  static late SharedPreferences _prefs;
  static Future<void>? _loading;
  
  
  static const _useImagesKey = "thumbnails";
  static const _readingFontSizeKey = "readingFontSize";
  static const _maxTextWidthKey = "maxTextWidth";
  static const _themeKey = "theme";
  static const _lightKey = "light_mode";
  
  static Future<void> load() {
    _loading ??= () async {
        _prefs = await SharedPreferences.getInstance();
        
        useImages.value = _prefs.getBool(_useImagesKey) ?? true;
        useImages.addListener(() => _prefs.setBool(_useImagesKey, useImages.value));
        
        readingFontSize.value = _prefs.getInt(_readingFontSizeKey) ?? 14;
        readingFontSize.addListener(() => _prefs.setInt(_readingFontSizeKey, readingFontSize.value));
        
        maxTextWidth.value = _prefs.getInt(_maxTextWidthKey) ?? 1000;
        maxTextWidth.addListener(() => _prefs.setInt(_maxTextWidthKey, maxTextWidth.value));
        
        _setupNotifier(sortAlphabetically, "librarySort", true);
      }();
    return _loading!;
  }
  
  static void _setupNotifier<T>(ValueNotifier<T> n, String key, T def) {
    n.value = _prefs.get(key) as T? ?? def;
    switch (T) {
      case const (int):
        n.addListener(() => _prefs.setInt(key, n.value as int));
        break;
      case const (bool):
        n.addListener(() => _prefs.setBool(key, n.value as bool));
        break;
      default:
        throw UnimplementedError("_setupNotifier not implemented for type ${T}");
    }
  }
  
  static ValueNotifier<bool> useImages = ValueNotifier(true);
  static ValueNotifier<int> readingFontSize = ValueNotifier(14);
  static ValueNotifier<int> maxTextWidth = ValueNotifier(1000);
  static ValueNotifier<bool> sortAlphabetically = ValueNotifier(true);
  
  
}


