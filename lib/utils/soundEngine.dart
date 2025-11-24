import 'dart:async';
import 'package:flutter_soloud/flutter_soloud.dart';

class SoundEngine {
  static final _soloud = SoLoud.instance;
  static final Map<String, AudioSource> _loadedSources = {};
  static SoundHandle? _backgroundMusicHandle;
  static bool _isBackgroundMusicPlaying = false;
  static bool _isInitialized = false;

  static const Map<String, String> _audioFiles = {
    'buttonDown': 'assets/button_down.mp3',
    'buttonUp': 'assets/button_up.mp3',
    'gameStart': 'assets/game_start.mp3',
    'gameWon': 'assets/game_won.mp3',
    'gameLost': 'assets/game_lost.mp3',
    'correctGuess': 'assets/correct_guess.mp3',
    'timeRunningOut': 'assets/time_running_out.mp3',
    'backgroundMusic': 'assets/background_music.mp3',
  };

  /// Initialize the audio engine and preload assets.
  /// This should be called once at app startup.
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize the engine with default settings
      await _soloud.init();

      // Load all assets into memory for low-latency playback
      for (final entry in _audioFiles.entries) {
        try {
          final source = await _soloud.loadAsset(entry.value);
          _loadedSources[entry.key] = source;
        } catch (e) {
          print("Error loading sound asset '${entry.key}': $e");
        }
      }

      _isInitialized = true;
      print("🔊 SoundEngine initialized with ${_loadedSources.length} assets");
    } catch (e) {
      print("Error initializing SoundEngine: $e");
    }
  }

  static void dispose() {
    _soloud.deinit();
    _isInitialized = false;
  }

  static Future<void> playSound(
    String soundName, [
    double volume = 1.0,
    bool loop = false,
  ]) async {
    if (!_isInitialized) await initialize();

    final source = _loadedSources[soundName];
    if (source == null) {
      print("⚠️ Sound '$soundName' not found or failed to load");
      return;
    }

    try {
      // Play the sound
      // SoLoud handles concurrency automatically (fire-and-forget)
      await _soloud.play(source, volume: volume, looping: loop);
    } catch (e) {
      print("Error playing sound '$soundName': $e");
    }
  }

  static Future<void> playBackgroundMusic() async {
    if (_isBackgroundMusicPlaying || _backgroundMusicHandle != null) {
      return;
    }

    if (!_isInitialized) await initialize();

    final source = _loadedSources['backgroundMusic'];
    if (source == null) return;

    try {
      _backgroundMusicHandle = await _soloud.play(
        source,
        volume: 0.009, // Keep volume low as per original
        looping: true,
      );
      _isBackgroundMusicPlaying = true;
    } catch (e) {
      print("Error playing background music: $e");
    }
  }

  static void pauseBackgroundMusic() {
    if (_backgroundMusicHandle != null) {
      _soloud.setPause(_backgroundMusicHandle!, true);
      _isBackgroundMusicPlaying = false;
    }
  }

  static void resumeBackgroundMusic() {
    if (_backgroundMusicHandle != null) {
      _soloud.setPause(_backgroundMusicHandle!, false);
      _isBackgroundMusicPlaying = true;
    }
  }

  static void stopBackgroundMusic() {
    if (_backgroundMusicHandle != null) {
      _soloud.stop(_backgroundMusicHandle!);
      _backgroundMusicHandle = null;
      _isBackgroundMusicPlaying = false;
    }
  }
}
