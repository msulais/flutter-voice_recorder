import 'dart:async' show StreamSubscription;
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../others/codec.dart';
import '../others/record.dart';
import '../data/settings.dart';
import 'record_list.dart';
import 'settings.dart';

class RecordPage extends StatefulWidget {
  const RecordPage({Key? key, required this.settings}) : super(key: key);

  final Settings settings;

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {

  bool _isRecording = false;
  Duration _duration = const Duration();
  StreamSubscription? _recorderSubscription;
  double _decibel = 0;
  final TextEditingController _text1 = TextEditingController();
  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();



  Future<void> _initAudio() async {

    // recorder
    await _audioRecorder.openRecorder();
    await _audioRecorder.setSubscriptionDuration(const Duration(milliseconds: 10));

    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth | AVAudioSessionCategoryOptions.defaultToSpeaker,
      avAudioSessionMode: AVAudioSessionMode.spokenAudio,
      avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.voiceCommunication,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    ));
  }



  Future<void> _startOrPauseRecording() async {
    final service = FlutterBackgroundService();

    // pause recorder
    if (_isRecording){
      await _pauseRecorder();
      setState(() {
        _isRecording = false;
        _decibel = 0;
      });
      return;
    }

    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Microphone permission denied.')));
      return;
    }

    // start recorder
    if (_duration.inMilliseconds == 0){
      await service.startService();
      bool success = await _startRecorder();
      if (!success) {
        service.invoke('stop');
        return;
      }
    // resume recorder
    } else {
      await _resumeRecorder();
    }

    setState(() => _isRecording = true);
  }



  Future<bool> _startRecorder() async {
    if (!await _audioRecorder.isEncoderSupported(widget.settings.codec)){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('This recorder doesn\'t support "${codecToString(widget.settings.codec)}" codec.')));
      return false;
    }

    try {
      Directory doc = await getApplicationDocumentsDirectory();
      await _audioRecorder.startRecorder(
        toFile: '${doc.path}${Platform.pathSeparator}cache_file${ext[widget.settings.codec.index]}', 
        codec: widget.settings.codec, 
        bitRate: widget.settings.bitRate, 
        sampleRate: widget.settings.sampleRate
      );
    } catch (e){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('[ERROR] Can\'t start recorder')));
      return false;
    }


    _recorderSubscription = _audioRecorder.onProgress!.listen((event) {
      setState(() {
        _duration = _duration + const Duration(milliseconds: 10);
        _decibel = event.decibels == 0? _decibel : event.decibels ?? _decibel;
      });
      FlutterBackgroundService().invoke('updateDuration', {
        'title': 'Recording', 
        'duration': '${_duration.inHours == 0? '' : '${_duration.inHours}:'}${(_duration.inMinutes % 60).toString().padLeft(_duration.inHours == 0? 1 : 2, '0')}:${(_duration.inSeconds % 60).toString().padLeft(2, '0')}'
      });
    });


    return true;
  }



  Future<void> _resumeRecorder() async {
    if (_audioRecorder.isPaused){
      _recorderSubscription?.resume();
      await _audioRecorder.resumeRecorder();
    }
  }



  Future<void> _pauseRecorder() async {
    if (_audioRecorder.isRecording){
      _recorderSubscription?.pause();
      await _audioRecorder.pauseRecorder();
      print('HERE-' * 10);
      FlutterBackgroundService().invoke('updateDuration', {
        'title': 'Paused', 
        'duration': '${_duration.inHours == 0? '' : '${_duration.inHours}:'}${(_duration.inMinutes % 60).toString().padLeft(_duration.inHours == 0? 1 : 2, '0')}:${(_duration.inSeconds % 60).toString().padLeft(2, '0')}'
      });
    }
  }



  Future<void> _stopRecorder() async {
    await _recorderSubscription?.cancel();
    await _audioRecorder.stopRecorder() ?? '';

    // if ((url == null || url.isEmpty) && mounted){
    //   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cache file not found, try another codec.')));
    //   setState((){
    //     _duration = const Duration();
    //     _decibel = 0;
    //   });
    //   return;
    // }

    await _saveOrDeleteRecord();

    setState((){
      _duration = const Duration();
      _decibel = 0;
    });

    FlutterBackgroundService().invoke('stop');
  }



  void _showRecordList() async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => RecordListPage(settings: widget.settings)));

    setState(() {});
  }



  Future<void> _saveOrDeleteRecord() async {

    String message = '';

    final now = DateTime.now();
    String p(int value, [int width = 2]) => value.toString().padLeft(width, '0');
    _text1.text = 'VR_${p(now.year, 4)}${p(now.month)}${p(now.day)}_${p(now.hour)}${p(now.minute)}${p(now.second)}';

    bool? isSave = await showModalBottomSheet(
      isDismissible: false,
      context: context, 
      isScrollControlled: true,
      builder: (context) => AnimatedPadding(
        padding: MediaQuery.of(context).viewInsets,
        duration: const Duration(milliseconds: 100),
        child: StatefulBuilder(
          builder: (context, setState) {
            return Column(mainAxisSize: MainAxisSize.min, children: [
        
              const SizedBox(height: 16.0),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  controller: _text1,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), 
                    isDense: true,
                    errorText: message.isEmpty? null : 'ⓘ $message',
                    hintText: _text1.text, 
                    suffixText: ext[widget.settings.codec.index],
                    labelText: 'File name'
                  ),
                  minLines: 1,
                  maxLines: 1,
                ),
              ), 
        
              const SizedBox(height: 8),
        
              Row(children: [
        
                const Spacer(), 
        
                TextButton(
                  onPressed: () => Navigator.pop(context), 
                  child: const Text('DELETE'),
                ),
        
                TextButton(
                  onPressed: () async {
                    RegExp checkFileNameRegex = RegExp(r'^[\w,\s-_\.]+$');
        
                    if (_text1.text.trim().isEmpty) {
                      setState(() => message = 'File name is empty.');
                      return;
                    }

                    if (checkFileNameRegex.firstMatch(_text1.text) == null){
                      setState(() => message = 'File name is not right.');
                      return;
                    }

                    Directory doc = await getApplicationDocumentsDirectory();

                    // to avoid replace other file
                    if (await File('${doc.path}${Platform.pathSeparator}${_text1.text}${ext[widget.settings.codec.index]}').exists()){
                      setState(() => message = 'File name already exist');
                      return;
                    }
        
                    if (mounted) Navigator.pop(context, true);
                  },
                  child: const Text('SAVE')
                ),
        
                const SizedBox(width: 8),
        
              ]), 
        
              const SizedBox(height: 8),
              
            ]);
          }
        ),
      )
    );
    Directory doc = await getApplicationDocumentsDirectory();
    String cacheFilePath = '${doc.path}${Platform.pathSeparator}cache_file${ext[widget.settings.codec.index]}';

    if (isSave == true){

      String newPath = '${doc.path}${Platform.pathSeparator}${_text1.text}${ext[widget.settings.codec.index]}';

      // rename file
      await File(cacheFilePath).rename(newPath);

      widget.settings.addRecordList(RecordItem(
        path: newPath, 
        codec: widget.settings.codec, 
        duration: _duration, 
        dateCreated: DateTime.now(), 
        bitRate: widget.settings.bitRate, 
        sampleRate: widget.settings.sampleRate
      ).toString());
      
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('File saved to "${doc.path}${Platform.pathSeparator}${_text1.text}${ext[widget.settings.codec.index]}"')));
      return;

    }

    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));

    // Delete cache file
    File(cacheFilePath).delete(recursive: true);
  }



  @override
  void initState(){
    super.initState();
    _initAudio();
  }



  @override
  void dispose(){
    _text1.dispose();
    _audioRecorder.stopRecorder();
    _recorderSubscription?.cancel();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {

    String hour = '${_duration.inHours}';
    if (_duration.inHours == 0) hour = '';

    String minute = '${_duration.inMinutes % 60}'.padLeft(hour.isNotEmpty? 2 : 1, '0');
    String seconds = '${_duration.inSeconds % 60}'.padLeft(2, '0');

    return Scaffold(
      body: SafeArea(child: SizedBox.expand(child: Column(
        children: [

          Expanded(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${hour.isNotEmpty? '$hour:' : ''}$minute:$seconds', style: const TextStyle(fontSize: 72)),
              if (_isRecording || _duration.inMilliseconds != 0) Text(_isRecording? 'Recording' : 'Paused', style: const TextStyle(fontSize: 18))
            ],
          )), 

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              if (!_isRecording && _duration.inMilliseconds == 0) Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: () async {
                      await Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => SettingsPage(settings: widget.settings))
                      );
                      setState(() {});
                    }, 
                    icon: const Icon(Icons.settings_outlined), 
                    iconSize: 28,
                  ),
                ),
              ) else const Spacer(),

              const SizedBox(width: 16),

              ElevatedButton(
                onPressed: () => _startOrPauseRecording(),
                style: ElevatedButton.styleFrom(
                  fixedSize:  const Size(150, 70)
                ), 
                child: Icon(_isRecording
                  ? Icons.pause_rounded 
                  : Icons.play_arrow_rounded,
                  size: 40
                )
              ),

              const SizedBox(width: 16),

              if (!_isRecording && (_duration.inMilliseconds != 0 || widget.settings.recordList.isNotEmpty)) Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: (){
                      // show record list
                      if (_duration.inMilliseconds == 0){
                        _showRecordList();
                        return;
                      }
                      _stopRecorder();
                    }, 
                    icon: Icon(_duration.inMilliseconds == 0
                      ? Icons.queue_music 
                      : Icons.square_outlined,
                    ), 
                    iconSize: 28,
                  ),
                ),
              ) else const Spacer(),

            ]
          ),

          const SizedBox(height: 16.0),

          AnimatedContainer(
            duration: const Duration(milliseconds: 10), 
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100), 
              color: Colors.red
            ),
            width: _decibel.abs() / 120 * (MediaQuery.of(context).size.width - 32) ,
            height: 8,
          ),

        ]
      )))
    );
  }
}