import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:provider/provider.dart';
import 'package:wakelock/wakelock.dart';

import 'src/data/settings.dart';
import 'src/others/change_phone_window.dart';
import 'src/pages/record.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Wakelock.enable();

  await _initBackgroundServices();

  var settings = Settings(); await settings.readFile();

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: settings),
    ], 
    child: const MyApp()
  ) );
}



Future<void> _initBackgroundServices() async {
  final service = FlutterBackgroundService();
  await service.configure(

    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
    ),

    // I dont make an ios app (for now)
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: (service) {},
      onBackground: (service) => false,
    ),
  );
}



void onStart(ServiceInstance service) async {

  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });

    service.on('updateDuration').listen((event) {
      service.setForegroundNotificationInfo(
        title: event!['title'], 
        content: event['duration']
      );
    });
  }

  service.on('stop').listen((event) {
    service.stopSelf();
  });

  // bring to foreground
  // Timer.periodic(const Duration(seconds: 1), (timer) async {

  //   if (service is AndroidServiceInstance) {
  //     service.setForegroundNotificationInfo(
  //       title: "My App Service",
  //       content: "Updated at ${DateTime.now()}",
  //     );
  //   }
  // });
}



class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {

  @override
  void initState(){
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose(){
    super.dispose();
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state){
      case AppLifecycleState.resumed:
        setState((){});
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Settings>(
      builder: (context, settings, _) {
        bool darkMode = changeSystemUI(settings);
        return MaterialApp(
          title: 'Voice Recorder',  
          theme: ThemeData(
            elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
              textStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))
            )),
            snackBarTheme: SnackBarThemeData(
              behavior: SnackBarBehavior.floating, 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), 
            ),
            inputDecorationTheme: InputDecorationTheme(
              errorStyle: TextStyle(color: darkMode? Colors.white : Colors.black), 
            ),
            textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(
              textStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5
              ),
              primary: Colors.red[darkMode? 200 : 700],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))
            )),
            dialogTheme: DialogTheme(shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)
            )),
            popupMenuTheme: PopupMenuThemeData(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
            ),
            brightness: darkMode? Brightness.dark : Brightness.light,
            primarySwatch: Colors.red,
            listTileTheme: ListTileThemeData(
              selectedColor: Colors.red[900],
              selectedTileColor: Colors.red[100],
              iconColor: darkMode? Colors.white : Colors.black ,
            )
          ),
          debugShowCheckedModeBanner: false,
          home: RecordPage(settings: settings),
        );
      }
    );
  }
}