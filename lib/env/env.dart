// run `dart run build_runner build -d` after updating this file to generate env variables for flutter

// ignore_for_file: non_constant_identifier_names

import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
final class Env {
  @EnviedField()
  static const String FIREBASE_API_KEY_WEB = _Env.FIREBASE_API_KEY_WEB;
  @EnviedField()
  static const String FIREBASE_API_KEY_ANDROID = _Env.FIREBASE_API_KEY_ANDROID;
  @EnviedField()
  static const String FIREBASE_API_KEY_IOS = _Env.FIREBASE_API_KEY_IOS;
  @EnviedField()
  static const String FIREBASE_API_KEY_MACOS = _Env.FIREBASE_API_KEY_MACOS;
  @EnviedField()
  static const String FIREBASE_API_KEY_WINDOWS = _Env.FIREBASE_API_KEY_WINDOWS;
  @EnviedField()
  static const String FINGERPRINT_API_KEY = _Env.FINGERPRINT_API_KEY;
}
