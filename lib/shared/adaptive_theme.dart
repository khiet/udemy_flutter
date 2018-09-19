import 'package:flutter/material.dart';

final ThemeData _androidTheme = ThemeData(
  brightness: Brightness.light,
  primarySwatch: Colors.deepOrange,
  accentColor: Colors.deepPurple,
  buttonColor: Colors.deepPurple,
);

final ThemeData _iOSTheme = ThemeData(
  brightness: Brightness.light,
  primarySwatch: Colors.grey,
  accentColor: Colors.blue,
  buttonColor: Colors.blue,
);

ThemeData getAdaptiveThemeData(BuildContext context) {
  return (Theme.of(context).platform == TargetPlatform.iOS)
      ? _iOSTheme
      : _androidTheme;
}
