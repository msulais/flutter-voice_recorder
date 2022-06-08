import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/settings.dart';
import '../others/codec.dart';
import '../widget/appbar.dart';
import '../others/record.dart';

class RecordListPage extends StatefulWidget {
  const RecordListPage({Key? key, required this.settings}) : super(key: key);

  final Settings settings;

  @override
  State<RecordListPage> createState() => _RecordListPageState();
}

class _RecordListPageState extends State<RecordListPage> {

  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  final TextEditingController _text1 = TextEditingController();
  final ScrollController _listViewScroll = ScrollController();
  StreamSubscription? _playerSubscription;
  List<int> _selectedIndex = [];
  int? _expandedIndex;
  double _sliderPosition = 0.0;
  bool 
    _isPaused = true, 
    _isEditMode = false
  ;



  Future<void> _renamePlayer(RecordItem recordItem) async {
    String message = '';

    _text1.text = recordItem.fileName.substring(0, recordItem.fileName.indexOf(ext[recordItem.codec.index]));

    bool? isRename = await showModalBottomSheet(
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
                    suffixText: ext[recordItem.codec.index],
                    labelText: 'Rename'
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
                  child: const Text('CANCEL'),
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
                  child: const Text('DONE')
                ),
        
                const SizedBox(width: 8),
        
              ]), 
        
              const SizedBox(height: 8),
              
            ]);
          }
        ),
      )
    );

    if (isRename != true) return;

    File(recordItem.path).rename(recordItem.path.substring(0, recordItem.path.indexOf(recordItem.fileName)) + _text1.text + ext[recordItem.codec.index]);
    widget.settings.replaceRecordList(
      recordItem, 
      RecordItem(
        path: recordItem.path.substring(0, recordItem.path.indexOf(recordItem.fileName)) + _text1.text + ext[recordItem.codec.index], 
        codec: recordItem.codec, 
        duration: recordItem.duration, 
        dateCreated: recordItem.dateCreated, 
        bitRate: recordItem.bitRate, 
        sampleRate: recordItem.sampleRate
      )
    );
  }



  Future<void> _playPlayer(RecordItem recordItem) async {


    if (!await _player.isDecoderSupported(recordItem.codec)){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('This audio player doesn\'t support "${codecToString(recordItem.codec)}" codec.')));
      return;
    }

    await _playerSubscription?.cancel();
    if (_player.isPlaying){
      await _player.stopPlayer();
    }

    try {
      await _player.startPlayer(
        fromURI: recordItem.path, 
        whenFinished: (){
          _playerSubscription?.cancel();
          setState(() {
            _isPaused = true;
            _sliderPosition = 0;
          });
        }
      );
    } catch (e){
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('[ERROR] Can\'t play "${recordItem.fileName}"')));
      return;
    }

    setState(() {
      _isPaused = false;
    });

    _playerSubscription = _player.onProgress!.listen((event) {
      setState(() {
        _sliderPosition = event.position.inMilliseconds.toDouble();
        if (_sliderPosition > recordItem.duration.inMilliseconds.toDouble()){
          _sliderPosition = recordItem.duration.inMilliseconds.toDouble();
        }
      });
    });
  }



  Future<void> _seekPlayer(int milliseconds) async {
    setState(() {
      _sliderPosition = milliseconds.toDouble();
    });
    await _player.seekToPlayer(Duration(milliseconds: milliseconds));
    if (_player.isPlaying){
      await _player.pausePlayer();
    }
  }



  Future<void> _pausePlayer() async {
    if (_player.isPlaying){
      await _player.pausePlayer();
      setState(() {
        _isPaused = true;
      });
    }
  }



  Future<void> _resumePlayer() async {
    if (_player.isPaused){
      await _player.resumePlayer();
      setState(() {
        _isPaused = false;
      });
    }
  }



  Future<void> _deletePlayer(List<RecordItem> files) async {
    bool? isDelete = await showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        title: const Text('Delete'),
        content: Text('Are you sure want to delete ${files.length == 1? '"${files[0].fileName}"' : 'selected files'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('CANCEL')
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('DELETE')
          ),
        ],
      )
    );

    if (isDelete != true) return;

    if (_player.isPlaying) await _player.stopPlayer();
    await _playerSubscription?.cancel();

    for (var file in files){
      widget.settings.removeRecordList(file);
      await File(file.path).delete(recursive: true);
    }

    setState((){
      _selectedIndex.clear();
      _isEditMode = false;
    });

    if (widget.settings.recordList.isEmpty && mounted) Navigator.pop(context);
  }



  Future<void> _sharePlayer(List<String> filesPath) async {
    await Share.shareFiles(filesPath);
  }



  void _showDetail(RecordItem recordItem) async {

    bool darkMode = Theme.of(context).brightness == Brightness.dark;
    String size = await recordItem.fileSize();

    showModalBottomSheet(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(
        topLeft: Radius.circular(10),
        topRight: Radius.circular(10)
      )),
      isScrollControlled: true,
      context: context,
      builder: (context){

        Widget title(String text){
          return Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(text, style: TextStyle(color: Colors.red[darkMode? 200 : 700], fontWeight: FontWeight.bold))
            ),
          );
        }

        Widget subtitle(String text){
          return Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16,0),
              child: SelectableText(text)),
          );
        }

        Widget divider = const Divider(endIndent: 16, indent: 16);

        DateTime date = recordItem.dateCreated;
        String month = '';

        switch (date.month){
          case  1: month = 'January'  ; break;
          case  2: month = 'February' ; break;
          case  3: month = 'March'    ; break;
          case  4: month = 'April'    ; break;
          case  5: month = 'May'      ; break;
          case  6: month = 'June'     ; break;
          case  7: month = 'July'     ; break;
          case  8: month = 'August'   ; break;
          case  9: month = 'September'; break;
          case 10: month = 'October'  ; break;
          case 11: month = 'November' ; break;
          case 12: month = 'December' ; break;
        }

        String dateCreated = '$month ${date.day}, ${date.year}, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';


        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - 50
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                color: Colors.grey
              ),
            ),

            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  title('Title:'), 
                  subtitle(recordItem.fileName), 
                  divider,

                  title('Path:'), 
                  subtitle(recordItem.path), 
                  divider,

                  title('Size:'), 
                  subtitle(size), 
                  divider,

                  title('Length:'), 
                  subtitle(recordItem.duration.toString().substring(0, recordItem.duration.toString().indexOf('.'))), 
                  divider,

                  title('Codec:'), 
                  subtitle(recordItem.getCodec), 
                  divider,

                  title('Bit rate:'), 
                  subtitle('${recordItem.bitRate} Hz'), 
                  divider,

                  title('Sample rate:'), 
                  subtitle('${recordItem.sampleRate} Hz'),
                  divider,

                  title('Date created:'), 
                  subtitle(dateCreated), 
            
                  const SizedBox(height: 16),
                ]),
              ),
            )
          ])
        );
      }
    );
  }



  void _selectPlayer(int index){
    setState((){
      if (_selectedIndex.contains(index)){
        _selectedIndex.remove(index);
        if (_selectedIndex.isEmpty){
          _isEditMode = false;
        }
      } else {
        _selectedIndex.add(index);
      }
    });
  }



  void _clearRecordList() async {
    bool? isClear = await showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        title: const Text('Delete'),
        content: const Text('Are you sure want to clear all record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('CANCEL')
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('CLEAR')
          ),
        ],
      )
    );

    if (isClear != true) return;

    for (var recordItem in List.from(widget.settings.recordList)){
      await File(RecordItem.parse(recordItem).path).delete(recursive: true);
      widget.settings.recordList.clear();
    }

    if (mounted) Navigator.pop(context);
  }



  void _selectAllPlayer(){
    _selectedIndex.clear();
    setState(() {
      _selectedIndex = [for (int i = 0; i < widget.settings.recordList.length; i++) i];
    });
  }



  @override
  void initState(){
    super.initState();
    _player.openPlayer().then((value) async {
      await _player.setSubscriptionDuration(const Duration(milliseconds: 10));
    });
  }



  @override
  void dispose(){
    _player.closePlayer();
    _playerSubscription?.cancel();
    _text1.dispose();
    _listViewScroll.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {

    bool darkMode = Theme.of(context).brightness == Brightness.dark;

    PreferredSizeWidget appBar = PreferredSize(
      preferredSize: const Size.fromHeight(50),
      child: AppBarWidget(
        icon: _isEditMode? Icons.clear : Icons.arrow_back, 
        title: _isEditMode? _selectedIndex.length.toString() : 'Recording list', 
        onPressed: () {
          if (_isEditMode){
            setState((){
              _isEditMode = false;
              _selectedIndex.clear();
            });
            return;
          }
          Navigator.pop(context);
        }, 
        actions: [
          if (_isEditMode)...List.generate(_selectedIndex.length == widget.settings.recordList.length? 2 : 3, (index) {

            bool isSameLength = _selectedIndex.length == widget.settings.recordList.length;

            List<String> tooltip = [
              if (!isSameLength) 'Select all', 
              'Share', 
              'Delete'
            ];

            List<IconData> icon = [
              if (!isSameLength) Icons.select_all_rounded, 
              Icons.share, 
              Icons.delete_outline
            ];

            List<VoidCallback> onPressed = [
              if (!isSameLength) () => _selectAllPlayer(), 
              () => _sharePlayer([for(int i in _selectedIndex) RecordItem.parse(widget.settings.recordList[i]).path]), 
              () => _deletePlayer([for(int i in _selectedIndex) RecordItem.parse(widget.settings.recordList[i])]), 
            ];

            return IconButton(
              tooltip: tooltip[index],
              icon: Icon(icon[index]), 
              onPressed: onPressed[index],
            );
          }) 
          else PopupMenuButton(
            itemBuilder: (context) => List.generate(1, (index){
              List<String> text = ['Clear'];
              return PopupMenuItem(value: text[index], child: Text(text[index]));
            }), 
            onSelected: (value){
              switch (value){
                case 'Clear': _clearRecordList(); break;
              }
            },
          )
        ],
      ),
    );

    return WillPopScope(
      onWillPop: () async {
        if (_isEditMode){
          setState((){
            _isEditMode = false;
            _selectedIndex.clear();
          });
          return Future.value(false);
        }
        return Future.value(true);
      },
      child: Scaffold(
        appBar: appBar,
        body: ListView.builder(
          controller: _listViewScroll,
          physics: const BouncingScrollPhysics(),
          itemCount: widget.settings.recordList.length,
          itemBuilder: (context, index) {
    
            RecordItem recordItem = RecordItem.parse(widget.settings.recordList[index]);
            Duration 
              duration = recordItem.duration, 
              durationNow = Duration(milliseconds: _sliderPosition.toInt())
            ;
            String 
              filePath = recordItem.path, 
              durationText = '${duration.inHours == 0? '' : '${duration.inHours}:'}${(duration.inMinutes % 60).toString().padLeft(duration.inHours == 0? 1 : 2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}', 
              durationNowText = '${durationNow.inHours == 0? '' : '${durationNow.inHours}:'}${(durationNow.inMinutes % 60).toString().padLeft(durationNow.inHours == 0? 1 : 2, '0')}:${(durationNow.inSeconds % 60).toString().padLeft(2, '0')}'
            ;
    
            return Column(children: [

              // header
              ListTile(
                title: Text(
                  recordItem.fileName, 
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () async  {
                  if (_isEditMode){
                    _selectPlayer(index);
                    return;
                  }
    
                  if (_player.isPlaying){
                    await _player.stopPlayer();
                  }
    
                  await _playerSubscription?.cancel();
                  setState(() {
                    _expandedIndex = _expandedIndex == index? null : index;
                    _sliderPosition = 0;
                    _isPaused = true;
                  });

                  if (index == widget.settings.recordList.length - 1 && _listViewScroll.hasClients){
                    Future.delayed(const Duration(milliseconds: 200), (){
                      _listViewScroll.animateTo(
                        _listViewScroll.position.maxScrollExtent, 
                        duration: const Duration(milliseconds: 200), 
                        curve: Curves.linear
                      );
                    });
                  }
                },
                onLongPress: () async {
    
                  if (_player.isPlaying){
                    await _player.stopPlayer();
                  }
    
                  await _playerSubscription?.cancel();
    
                  setState((){
                    _sliderPosition = 0;
                    _isPaused = true;
                    _isEditMode = true;
                    _expandedIndex = null;
                  });
    
                  _selectPlayer(index);
                },
                selected: _selectedIndex.contains(index),
                subtitle: Text(durationText),
                trailing: index == _expandedIndex? const Icon(Icons.expand_less) : null,
              ),
    
              // body
              AnimatedCrossFade(
                firstChild: Column(
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(_isPaused? 5 : 1, (index2) {
                        
                        List<String> tooltip = [
                          _isPaused
                            ? _sliderPosition == 0
                              ? 'Play'
                              : 'Resume'
                            : 'Pause', 
                          'Share', 
                          'Delete', 
                          'Rename', 
                          'Description'
                        ];
                        
                        List<VoidCallback> onPressed = [
                          _isPaused
                            ? _sliderPosition == 0
                              ? () => _playPlayer(recordItem)
                              : () => _resumePlayer()
                            : () => _pausePlayer(),
                          () => _sharePlayer([filePath]), 
                          () => _deletePlayer([recordItem]), 
                          () => _renamePlayer(recordItem),
                          () => _showDetail(recordItem)
                        ];
                        
                        List<IconData> icon = [
                          _isPaused
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                          Icons.share_outlined, 
                          Icons.delete_outlined,
                          Icons.edit,
                          Icons.description_outlined
                        ];
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
                          child: Tooltip(
                            message: tooltip[index2],
                            child: 
                            OutlinedButton(
                              onPressed: onPressed[index2],
                              style: OutlinedButton.styleFrom(
                                primary: Colors.red[darkMode? 300 : 500],
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                                minimumSize: const Size(60, 60)
                              ),
                              child: Icon(icon[index2]),
                            ),
                          ),
                        );
                        
                      })),
                    ),
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 200),
                      crossFadeState: _sliderPosition > 0 || !_isPaused ? CrossFadeState.showFirst : CrossFadeState.showSecond ,
                      secondChild: Container(),
                      firstChild: Listener(
                        onPointerUp: (event) async {
                          if (_player.isPaused && !_isPaused){
                            await _player.resumePlayer();
                          }
                        } ,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 24.0),
                              child: Text('$durationNowText/$durationText'),
                            ),
                            Slider(
                              min: 0.0,
                              max: recordItem.duration.inMilliseconds.toDouble(),
                              value: math.min(_sliderPosition, recordItem.duration.inMilliseconds.toDouble()),
                              onChanged: (double value) => _seekPlayer(value.toInt())
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 0)
                  ],
                ),
                secondChild: Container(),
                crossFadeState: index == _expandedIndex? CrossFadeState.showFirst : CrossFadeState.showSecond,
                duration: const Duration(milliseconds: 200),
              ),
              
            ]);
    
          }
        )
      ),
    );
  }
}