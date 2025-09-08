import 'package:audioplayers/audioplayers.dart';

class SoundEngine {
  static AudioPlayer? _audioPlayer;
  static AudioPlayer? _backgroundMusicPlayer;
  static String? _currentPlayingSound;
  static bool _isBackgroundMusicPlaying = false;

  static Map audioFiles = {
    'buttonDown': 'button_down.mp3',
    'buttonUp': 'button_up.mp3',
    'gameStart': 'game_start.mp3',
    'gameWon': 'game_won.mp3',
    'gameLost': 'game_lost.mp3',
    'correctGuess': 'correct_guess.mp3',
    'timeRunningOut': 'time_running_out.mp3',
    'backgroundMusic': 'background_music.mp3',
  };

  static void playSound(
    String soundName, [
    double volume = 1.0,
    bool loop = false,
  ]) {
    _audioPlayer ??= AudioPlayer(); //singleton

    // If the same sound is currently playing, stop it first
    if (_currentPlayingSound == soundName && _audioPlayer != null) {
      _audioPlayer!.stop();
    }

    if (loop) {
      _audioPlayer?.setReleaseMode(ReleaseMode.loop);
    }

    // Play the new sound
    _audioPlayer?.play(AssetSource(audioFiles[soundName]!), volume: volume);

    // Update the current playing sound
    _currentPlayingSound = soundName;
  }

  static void playBackgroundMusic() {
    if (_isBackgroundMusicPlaying) {
      return;
    }
    _backgroundMusicPlayer ??= AudioPlayer();
    _backgroundMusicPlayer?.setReleaseMode(ReleaseMode.loop);
    _backgroundMusicPlayer?.play(
      AssetSource(audioFiles['backgroundMusic']!),
      volume: 0.009,
    );
    _isBackgroundMusicPlaying = true;
  }

  static void pauseBackgroundMusic() {
    _backgroundMusicPlayer?.pause();
    _isBackgroundMusicPlaying = false;
  }

  static void resumeBackgroundMusic() {
    _backgroundMusicPlayer?.resume();
    _isBackgroundMusicPlaying = true;
  }

  static void stopBackgroundMusic() {
    _backgroundMusicPlayer?.stop();
    _isBackgroundMusicPlaying = false;
  }
}
