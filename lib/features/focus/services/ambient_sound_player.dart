import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

/// Ambient Sound Player — loops background audio during focus sessions.
/// Uses just_audio for gapless looping and audio_session for interruption handling.
class AmbientSoundPlayer {
  static AudioPlayer? _player;
  static String? _currentSound;

  static bool _sessionListenersRegistered = false;
  static bool _wasPlayingBeforeInterruption = false;
  static StreamSubscription? _interruptionSubscription;
  static StreamSubscription? _noisySubscription;

  static const _assets = {
    'binaural': 'assets/sounds/bodhisounds-gamma-binaural-beats-enhance-brain-power-relaxing-music-for-study-161763.mp3',
    'rain': 'assets/sounds/boons_freak-rain-sound-188158.mp3',
    'cafe': 'assets/sounds/km007-cafe-ambience-9263.mp3',
    'piano': 'assets/sounds/the_mountain-piano-background-487020.mp3',
    'synth': 'assets/sounds/freemusiclab-dark-cyberpunk-i-free-background-music-i-free-music-lab-release-469493.mp3',
  };

  /// Asynchronously configures the audio session and registers OS listeners once.
  static Future<void> _initAudioSession() async {
    if (_sessionListenersRegistered) return;
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      _interruptionSubscription = session.interruptionEventStream.listen((event) {
        final player = _player;
        if (player == null) return;

        if (event.begin) {
          switch (event.type) {
            case AudioInterruptionType.duck:
              // Lower volume
              player.setVolume(player.volume * 0.2);
              break;
            case AudioInterruptionType.pause:
            case AudioInterruptionType.unknown:
              _wasPlayingBeforeInterruption = player.playing;
              player.pause();
              break;
          }
        } else {
          // Interruption ended
          switch (event.type) {
            case AudioInterruptionType.duck:
              player.setVolume(0.4);
              break;
            case AudioInterruptionType.pause:
              if (_wasPlayingBeforeInterruption) {
                // Resume loop only if active before interruption and not manually paused
                player.play();
              }
              break;
            case AudioInterruptionType.unknown:
              break;
          }
        }
      });

      _noisySubscription = session.becomingNoisyEventStream.listen((_) {
        // Headphone unplugged -> pause loop, requires manual resume
        stop();
      });

      _sessionListenersRegistered = true;
    } catch (e) {
      debugPrint('⚠️ AudioSession setup failed: $e');
    }
  }

  /// Lazily initializes the player.
  static AudioPlayer? _getPlayer() {
    try {
      if (_player == null) {
        _player = AudioPlayer();
        _initAudioSession();
      }
      return _player;
    } catch (e) {
      debugPrint('⚠️ AudioPlayer initialization failed: $e');
      return null;
    }
  }

  /// Verify an asset exists in the bundle.
  static Future<bool> _assetExists(String assetPath) async {
    try {
      await rootBundle.load(assetPath);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Start playing a sound loop.
  static Future<void> play(String soundKey) async {
    if (soundKey == 'none' || !_assets.containsKey(soundKey)) {
      await stop();
      return;
    }

    if (_currentSound == soundKey && (_player?.playing ?? false)) return;

    final player = _getPlayer();
    if (player == null) {
      debugPrint('⚠️ AmbientSound: no player available, skipping $soundKey');
      return;
    }

    final assetPath = _assets[soundKey]!;

    // Check asset exists before attempting playback
    final exists = await _assetExists(assetPath);
    if (!exists) {
      debugPrint('⚠️ AmbientSound: asset not found — $assetPath (skipping silently)');
      return;
    }

    try {
      await player.setAsset(assetPath);
      await player.setLoopMode(LoopMode.one); // Gapless loop
      await player.setVolume(0.4); // Subtle by default
      await player.play();
      _currentSound = soundKey;
      _wasPlayingBeforeInterruption = true;
      debugPrint('🔊 Playing: $soundKey');
    } catch (e) {
      debugPrint('⚠️ AmbientSound playback error ($soundKey): $e');
      _currentSound = null;
    }
  }

  /// Stop playing. Safe to call even if nothing is playing.
  static Future<void> stop() async {
    try {
      await _player?.stop();
    } catch (e) {
      debugPrint('⚠️ AmbientSound stop error: $e');
    }
    _currentSound = null;
    _wasPlayingBeforeInterruption = false;
  }

  /// Adjust volume (0.0 – 1.0).
  static Future<void> setVolume(double volume) async {
    try {
      await _player?.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      debugPrint('⚠️ AmbientSound volume error: $e');
    }
  }

  /// Fade out over duration.
  static Future<void> fadeOut({
    Duration duration = const Duration(seconds: 3),
  }) async {
    final player = _player;
    if (player == null || !player.playing) {
      _currentSound = null;
      return;
    }

    try {
      final currentVolume = player.volume;
      const steps = 15;
      final stepDuration = duration ~/ steps;

      for (int i = steps; i >= 0; i--) {
        if (!player.playing) break; // Guard against external stop
        await player.setVolume(currentVolume * (i / steps));
        await Future.delayed(stepDuration);
      }
    } catch (e) {
      debugPrint('⚠️ AmbientSound fadeOut error: $e');
    }

    await stop();
  }

  /// Whether audio is currently playing
  static bool get isPlaying => _player?.playing ?? false;

  /// Current sound key
  static String? get currentSound => _currentSound;

  /// Available sound keys for UI display
  static List<String> get availableKeys => _assets.keys.toList();

  /// Dispose player resources.
  static Future<void> dispose() async {
    try {
      await _interruptionSubscription?.cancel();
      await _noisySubscription?.cancel();
      _sessionListenersRegistered = false;
      await _player?.dispose();
      _player = null;
      _currentSound = null;
    } catch (e) {
      debugPrint('⚠️ AmbientSound dispose error: $e');
    }
  }
}
