
import 'package:pigallery2_android/data/storage/storage_key.dart';
import 'package:pigallery2_android/domain/models/media_background_mode.dart';
import 'package:pigallery2_android/domain/models/sort_option.dart';
import 'package:pigallery2_android/util/extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TypeHelper<T> {
  const TypeHelper();
  bool operator >=(TypeHelper other) => other is TypeHelper<T>;
  bool operator <=(TypeHelper other) => other >= this;
}

class SharedPrefsStorage {
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  T? _get<T>(String key) {
    return switch(TypeHelper<T>()) {
      <= const TypeHelper<String>() => _prefs.getString(key) as T?,
      <= const TypeHelper<int>() => _prefs.getInt(key) as T?,
      <= const TypeHelper<bool>() => _prefs.getBool(key) as T?,
      <= const TypeHelper<double>() => _prefs.getDouble(key) as T?,
      <= const TypeHelper<List<String>>() => _prefs.getStringList(key) as T?,
      <= const TypeHelper<SortOption>() => _prefs.getInt(key)?.let((it) => SortOption.values[it]) as T?,
      <= const TypeHelper<MediaBackgroundMode>() => _prefs.getInt(key)?.let((it) => MediaBackgroundMode.values[it]) as T?,
      _ => throw UnsupportedError("Unsupported data type $T")
    };
  }

  T? getWithKey<T>(String key) {
    try {
      return _get(key);
    } on Exception {
      return null;
    }
  }

  T get<T>(StorageKey<T> key) {
    try {
      return _get(key.key) ?? key.defaultValue;
    } on Exception {
      return key.defaultValue;
    }
  }

  Future<bool> _set<T>(String key, T value) {
    return switch(TypeHelper<T>()) {
      <= const TypeHelper<String>() => _prefs.setString(key, value as String),
      <= const TypeHelper<int>() => _prefs.setInt(key, value as int),
      <= const TypeHelper<bool>() => _prefs.setBool(key, value as bool),
      <= const TypeHelper<double>() => _prefs.setDouble(key, value as double),
      <= const TypeHelper<List<String>>() => _prefs.setStringList(key, value as List<String>),
      <= const TypeHelper<Enum>() => _prefs.setInt(key, (value as Enum).index),
      _ => throw UnsupportedError("Unsupported data type $T")
    };
  }

  Future<bool> setWithKey<T>(String key, T value) async {
    try {
      return await _set(key, value);
    } on Exception {
      return Future.value(false);
    }
  }

  Future<bool> set<T>(StorageKey<T> key, T value) async {
    try {
      return await _set(key.key, value);
    } on Exception {
      return Future.value(false);
    }
  }
}