import 'package:flutter/material.dart';

const timberwolf = Color(0xFFDADBD2);
const renoSand = Color(0xFFB87334);
const softDarkBackground = Color(0xFF1E1E1E); // Less stark than pure black

const lightColorScheme = ColorScheme.light(
  surface: timberwolf,
  primary: renoSand,
  onPrimary: Colors.white,
  onSurface: Colors.black,
);

const darkColorScheme = ColorScheme.dark(
  surface: softDarkBackground,
  primary: renoSand,
  onPrimary: Colors.white,
  onSurface: timberwolf,
);