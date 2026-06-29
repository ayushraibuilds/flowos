import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// Ambient Sound Player — loops background audio during focus sessions.
///
/// Available sounds:
/// - Binaural beats (40Hz gamma)
/// - Rain
/// - Café ambiance
/// - Forest / Nature
///
/// Uses just_audio for gapless looping and volume control.
class AmbientSoundPlayer {
  static final _player = AudioPlayer();
  static String? _currentSound;

  /// Asset paths for bundled ambient sounds
  static const _assets = {
    'binaural': 'assets/sounds/bodhisounds-gamma-binaural-beats-enhance-brain-power-relaxing-music-for-study-161763.mp3',
    'rain': 'assets/sounds/boons_freak-rain-sound-188158.mp3',
    'cafe': 'assets/sounds/km007-cafe-ambience-9263.mp3',
    'forest': 'assets/sounds/the_mountain-piano-background-487020.mp3',
    'synth': 'assets/sounds/freemusiclab-dark-cyberpunk-i-free-background-music-i-free-music-lab-release-469493.mp3',
  };

  /// Start playing a sound loop
  static Future<void> play(String soundKey) async {
    if (soundKey == 'none' || !_assets.containsKey(soundKey)) {
      await stop();
      return;
    }

    if (_currentSound == soundKey && _player.playing) return;

    try {
      await _player.setAsset(_assets[soundKey]!);
      await _player.setLoopMode(LoopMode.one); // Gapless loop
      await _player.setVolume(0.4); // Subtle by default
      await _player.play();
      _currentSound = soundKey;
      debugPrint('🔊 Playing: $soundKey');
    } catch (e) {
      debugPrint('Ambient sound error: $e');
    }
  }

  /// Stop playing
  static Future<void> stop() async {
    await _player.stop();
    _currentSound = null;
  }

  /// Adjust volume (0.0 – 1.0)
  static Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }

  /// Fade out over duration (for session end)
  static Future<void> fadeOut({
    Duration duration = const Duration(seconds: 3),
  }) async {
    final currentVolume = _player.volume;
    const steps = 15;
    final stepDuration = duration ~/ steps;

    for (int i = steps; i >= 0; i--) {
      await _player.setVolume(currentVolume * (i / steps));
      await Future.delayed(stepDuration);
    }

    await stop();
  }

  /// Is currently playing
  static bool get isPlaying => _player.playing;

  /// Current sound key
  static String? get currentSound => _currentSound;

  /// Dispose player
  static Future<void> dispose() async {
    await _player.dispose();
  }
}
