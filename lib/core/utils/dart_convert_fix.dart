/*
Contenido para dart_convert_fix.dart (colócalo en lib/core/utils/dart_convert_fix.dart o similar):
Este archivo es necesario debido a un problema conocido con el SDK de google_generative_ai y Flutter.
Fuente: https://github.com/google/generative-ai-dart/issues/29
*/
// ignore: unused_import
import 'dart:convert' as convert;

String? get platformVersion => null;
bool get isDesktop => false;
bool get isWeb => false;