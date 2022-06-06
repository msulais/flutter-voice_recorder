import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import '../data/settings.dart';

bool changeSystemUI(Settings settings, {Color? navigationColor}){
  bool darkMode = settings.theme == 'Dark' || settings.theme == 'System default' && SchedulerBinding.instance.window.platformBrightness == Brightness.dark;
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarIconBrightness: darkMode? Brightness.light : Brightness.dark,
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: navigationColor ?? Colors.grey[darkMode? 850 : 50],
    systemNavigationBarIconBrightness: darkMode? Brightness.light : Brightness.dark
  ));
  return darkMode;
}