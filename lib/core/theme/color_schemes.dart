import 'package:flutter/material.dart';

const timberwolf = Color(0xFFDADBD2);
const renoSand = Color(0xFFB87334);
const softDarkBackground = Color(0xFF1E1E1E); // Less stark than pure black
const scaffoldBackgroundLight = Color(0xFFF0F0E8); // Lighter than timberwolf
const scaffoldBackgroundDark = Color(0xFF121212); // Darker than softDarkBackground

const lightColorScheme = ColorScheme.light(
  surface: timberwolf,
  primary: renoSand,
  onPrimary: Colors.white,
  onSurface: Colors.black,
  shadow: Colors.black,
);

const darkColorScheme = ColorScheme.dark(
  surface: softDarkBackground,
  primary: renoSand,
  onPrimary: Colors.white,
  onSurface: timberwolf,
  shadow: Colors.black54,
);