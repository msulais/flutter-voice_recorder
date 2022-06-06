import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart' show Codec, FlutterSoundRecorder, ext;
import 'package:url_launcher/url_launcher_string.dart';
import 'package:voice_recorder/src/others/codec.dart';

import '../data/settings.dart';
import '../widget/appbar.dart';
import '../widget/list_tile.dart';
import '../widget/select_dialog.dart';
import '../constant/app_version.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key, required this.settings}) : super(key: key);

  final Settings settings;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  final TextEditingController _text1 = TextEditingController();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder(); // to check unsupported codec only



  void _selectCodec() async {
    List<int> unsupportedCodecIndex = [];
    for (var i in Codec.values){
      if (!await _recorder.isEncoderSupported(i)){
        unsupportedCodecIndex.add(i.index);
      }
    }

    if (mounted){
      selectDialogWidget(context, 'Codec', List.generate(Codec.values.length, (index) {

        if (index == 0 || unsupportedCodecIndex.contains(index)) return Container(); 

        bool selected = widget.settings.codec == Codec.values[index];
        return ListTile(
          selected: selected,
          title: Text(codecToString(Codec.values[index])),
          trailing: Material(
            color: Colors.red[100],
            borderRadius: BorderRadius.circular(100),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10),
              child: Text(ext[Codec.values[index].index], style: TextStyle(color: Colors.red[900], fontWeight: FontWeight.w500))
            ),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onTap: () {
            widget.settings.codec = Codec.values[index];
            Navigator.pop(context);
          },
        );
      }));
    }
  }



  Future<void> _changeHertzValue(String label, int defaultValue) async {

    String message = '';

    _text1.text = defaultValue.toString();

    bool? isChanged = await showModalBottomSheet(
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
                    suffixText: 'Hz',
                    labelText: label, 
                  ),
                  keyboardType: TextInputType.number,
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
                  onPressed: () {
                    if (_text1.text.contains(RegExp(r'[^0-9]'))){
                      setState(() => message = 'The value must be a number only');
                      return;
                    }
                    Navigator.pop(context, true);
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

    if (isChanged != true) return;

    switch (label){
      case 'Bit rate'   : widget.settings.bitRate    = int.parse(_text1.text); break;
      case 'Sample rate': widget.settings.sampleRate = int.parse(_text1.text); break;
    }
  }



  @override
  void initState(){
    super.initState();
    _recorder.openRecorder();
  }



  @override
  void dispose(){
    _text1.dispose();
    _recorder.closeRecorder();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {

    bool darkMode = Theme.of(context).brightness == Brightness.dark;

    PreferredSizeWidget appBar = PreferredSize(
      preferredSize: const Size.fromHeight(50),
      child: AppBarWidget(
        icon: Icons.arrow_back, 
        title: 'Settings', 
        onPressed: () => Navigator.pop(context)
      ),
    );

    Widget themeWidget = Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(children: List.generate(3, (index) {
        List<String> text = ['System default', 'Light', 'Dark'];
        List<IconData> icon = [
          Icons.brightness_4_outlined,
          Icons.light_mode_outlined,
          Icons.dark_mode_outlined,
        ];
        List<Color> color = [Colors.red[100]! , Colors.grey[200]!, Colors.grey[800]!];
        List<Color> textColor = [Colors.red[900]! , Colors.black, Colors.white];
        return Expanded(child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: SizedBox(height: 150, child: Material(
            elevation: text[index] == widget.settings.theme? 4.0 : 0,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.hardEdge,
            color: color[index],
            child: InkWell(
              onTap: () => setState(() =>  widget.settings.theme = text[index]),
              child: SizedBox(width: double.infinity, child: Column(children: [
                const SizedBox(height: 8),
                Expanded(child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Icon(icon[index], color: textColor[index], size: 28)
                )),
                const SizedBox(height: 8.0),
                Expanded(child: Text(
                  text[index],
                  style: Theme.of(context).textTheme.subtitle1!.copyWith(
                    fontWeight: FontWeight.w500,
                    color: textColor[index]
                  ),
                  textAlign: TextAlign.center
                )),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 50,
                  height: 8,
                  decoration: BoxDecoration(
                    color: text[index] == widget.settings.theme? Colors.red : Colors.transparent,
                    borderRadius: BorderRadius.circular(100)
                  )
                ),
                const SizedBox(height: 8)
              ] ) ),
            )
          )),
        ));
      })),
    );

    return Scaffold(
      appBar: appBar,
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [

          // Theme
          themeWidget, 

          const Divider(),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('Audio', style: TextStyle(color: Colors.red[darkMode? 200 : 700], fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ),

          SelectListTileWidget(
            icon: Icons.graphic_eq, 
            labelText: 'Bit rate', 
            value: '${widget.settings.bitRate} Hz',
            onTap: () => _changeHertzValue('Bit rate', widget.settings.bitRate)
          ),

          SelectListTileWidget(
            icon: Icons.graphic_eq, 
            labelText: 'Sample rate', 
            value: '${widget.settings.sampleRate} Hz',
            onTap: () => _changeHertzValue('Sample rate', widget.settings.sampleRate)
          ),

          SelectListTileWidget(
            icon: Icons.audio_file_outlined, 
            labelText: 'Codec', 
            value: codecToString(widget.settings.codec),
            onTap: () => _selectCodec()
          ),

          const Divider(),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('About', style: TextStyle(color: Colors.red[darkMode? 200 : 700], fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ), 

          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('About app'),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'Voice Recorder',
              applicationVersion: appVersion,
              applicationIcon: Image.asset(
                'assets/images/ic_launcher_view.png', 
                width: 48, 
                height: 48, 
                filterQuality: FilterQuality.high
              ),
              applicationLegalese: '© 2022 Kubus',
            ),
          ),

          ListTile(
            leading: const Icon(Icons.feedback_outlined),
            title: const Text('Send feedback'),
            onTap: (){
              launchUrlString('mailto:daundua2@gmail.com?subject=My Feedback about Kubus Voice Recorder app', mode: LaunchMode.externalApplication);
            },
          ), 

          ListTile(
            leading: const Icon(Icons.star_outline),
            title: const Text('Rate us'),
            onTap: (){
              launchUrlString('https://play.google.com/store/apps/details?id=com.kubus.voice_recorder', mode: LaunchMode.externalApplication);
            },
          ), 
        ],
      )
    );
  }
}