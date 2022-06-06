import 'package:flutter_sound/flutter_sound.dart';

import 'package:flutter/material.dart' show ChangeNotifier;
import 'package:shared_preferences/shared_preferences.dart';

import '../others/record.dart';

class Settings extends ChangeNotifier {

  final Map<String, dynamic> _settings = {
    'theme': 'System default', // options: 'System default', 'Dark', 'Light'
    'record-list': <String>[], 
    'codec': Codec.aacADTS.index, 
    'bit-rate': 16000, 
    'sample-rate': 44000
  };

  Codec get codec => Codec.values[(_settings['codec'] as int)]; set codec(Codec value) => _changeSettings('codec', value.index);
  List<String> get recordList => _settings['record-list']; set recordList(List<String> value) => _changeSettings('record-list', value);
  String get theme      => _settings['theme'      ]; set theme     (String value) => _changeSettings('theme'      , value);
  int    get bitRate    => _settings['bit-rate'   ]; set bitRate   (int    value) => _changeSettings('bit-rate'   , value);
  int    get sampleRate => _settings['sample-rate']; set sampleRate(int    value) => _changeSettings('sample-rate', value);


  void addRecordList(String recordItem){
    (_settings['record-list'] as List<String>).add(recordItem);
    (_settings['record-list'] as List<String>).sort((a, b) => RecordItem.parse(a).fileName.compareTo(RecordItem.parse(b).fileName));
    _changeSettings('record-list', _settings['record-list'] as List<String>);
  }

  void replaceRecordList(RecordItem oldItem, RecordItem newItem){
    (_settings['record-list'] as List<String>)[(_settings['record-list'] as List<String>).indexOf(oldItem.toString())] = newItem.toString();
    _changeSettings('record-list', _settings['record-list'] as List<String>);
  }

  void removeRecordList(RecordItem recordItem){
    (_settings['record-list'] as List<String>).removeWhere((element) => RecordItem.parse(element).path == recordItem.path);
    _changeSettings('record-list', _settings['record-list'] as List<String>);
  }

  void _changeSettings(String key, dynamic value) async {
    _settings[key] = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    switch (value.runtimeType){
      case int   : await prefs.setInt   (key, value as int   ); break;
      case String: await prefs.setString(key, value as String); break;
      case bool  : await prefs.setBool  (key, value as bool  ); break;
      case double: await prefs.setDouble(key, value as double); break;
      case List<String>: await prefs.setStringList(key, value as List<String>); break;
    }
  }

  Future<void> readFile() async {
    final prefs = await SharedPreferences.getInstance();

    dynamic data(String key) => prefs.get(key);
    theme = data('theme') ?? 'System default';
    recordList = prefs.getStringList('record-list') ?? [];
    codec = Codec.values[data('codec') ?? Codec.aacADTS.index];
    bitRate = data('bit-rate') ?? 16000;
    sampleRate = data('sample-rate') ?? 44000;
  }
}