# wibble

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

Run `dart run build_runner build` after creating a `@JsonSerializable()` class to generate json methods
Run `dart run build_runner build` after creating updating .env and env.dart
Run `flutter clean && flutter pub get` after adding or removing files in the `/assets` directory

### deploy to google playstore

cd into android

#### alpha (internal testing)

run `fastlane android alpha`

#### deploy to public

run `fastlane android deploy`
