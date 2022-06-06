import 'dart:convert' show jsonDecode, jsonEncode;
import 'dart:io';

import 'package:flutter_sound/flutter_sound.dart' show Codec;
import 'package:voice_recorder/src/others/codec.dart';

import 'remove_dot.dart';

class RecordItem {
  RecordItem({
    required this.path, 
    required this.codec,
    required this.duration,
    required this.dateCreated,
    required this.bitRate, 
    required this.sampleRate,
  });

  late final String path;
  late final Codec codec;
  late final int bitRate;
  late final int sampleRate;
  late final Duration duration;
  late final DateTime dateCreated;


  set renameFile(String newName) {
    RegExpMatch? match = RegExp(r'[\w,\s-_\.]+\.[A-Za-z0-9]+$').firstMatch(path);
    String newPath = '${path.substring(0, match!.start)}${Platform.pathSeparator}$newName.$codec';

    File(path).rename(newPath);
    path = newPath;
  }

  

  String get fileName {
    RegExpMatch? match = RegExp(r'[\w,\s-_\.]+\.[A-Za-z0-9]+$').firstMatch(path);
    return path.substring(match!.start);
  }



  String get getCodec => codecToString(codec);



  Future<String> fileSize() async {
    double size = (await File(path).length()).toDouble();

    // GB
    if (size > 1000000000){
      return '${removeDotZero((size / 1000000000).toStringAsFixed(2))} GB';
    }

    // MB
    if (size > 1000000){
      return '${removeDotZero((size / 1000000).toStringAsFixed(2))} MB';
    }

    // KB
    if (size > 1000){
      return '${removeDotZero((size / 1000).toStringAsFixed(2))} KB';
    }
    
    return '${removeDotZero('$size')} bytes';
  }



  static RecordItem parse(String recordItem){
    Map<String, dynamic> data = jsonDecode(recordItem);

    return RecordItem(
      bitRate: data['bit-rate'],
      sampleRate: data['sample-rate'],
      path: data['path'], 
      codec: Codec.values[(data['codec'] as int)], 
      duration: Duration(microseconds: data['duration'] as int), 
      dateCreated: DateTime.parse(data['date-created'])
    );
  }



  @override
  String toString(){
    return jsonEncode({
      'path': path, 
      'bit-rate': bitRate, 
      'sample-rate': sampleRate,
      'duration': duration.inMicroseconds, 
      'codec': codec.index, 
      'date-created': dateCreated.toIso8601String()
    });
  }
}