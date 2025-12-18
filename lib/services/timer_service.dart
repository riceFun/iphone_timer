import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

class TimerService extends ChangeNotifier {
  Timer? _timer;
  Timer? _vibrationTimer;
  int _remainingSeconds = 0;
  int _initialSeconds = 0;
  bool _isRunning = false;
  bool _isCompleted = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  int get remainingSeconds => _remainingSeconds;
  int get initialSeconds => _initialSeconds;
  bool get isRunning => _isRunning;
  bool get isCompleted => _isCompleted;

  String get formattedTime {
    final hours = _remainingSeconds ~/ 3600;
    final minutes = (_remainingSeconds % 3600) ~/ 60;
    final seconds = _remainingSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  void startTimer(int seconds) {
    _stopVibration(); // Cancel any ongoing vibration from previous timer completion
    _isCompleted = false;
    _initialSeconds = seconds;
    _remainingSeconds = seconds;
    _isRunning = true;
    notifyListeners();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        stopTimer();
        _onTimerComplete();
      }
    });
  }

  void pauseTimer() {
    _timer?.cancel();
    _isRunning = false;
    notifyListeners();
  }

  void resumeTimer() {
    if (_remainingSeconds > 0) {
      _isRunning = true;
      notifyListeners();

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
          notifyListeners();
        } else {
          stopTimer();
          _onTimerComplete();
        }
      });
    }
  }

  void stopTimer() {
    _timer?.cancel();
    _stopVibration(); // Cancel vibration when user manually stops timer
    _isRunning = false;
    _isCompleted = false;
    _remainingSeconds = 0;
    _initialSeconds = 0;
    notifyListeners();
  }

  void dismissCompletion() {
    _stopVibration();
    _audioPlayer.stop();
    _isCompleted = false;
    notifyListeners();
  }

  void _onTimerComplete() async {
    _isCompleted = true;
    notifyListeners();

    // Play sound and start continuous vibration
    try {
      // Set audio player mode to release mode for better compatibility
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      await _audioPlayer.setVolume(1.0);

      // Play the completion sound
      await _audioPlayer.play(AssetSource('sounds/timer_complete.mp3'));
      debugPrint('Audio playing...');

      // Start continuous vibration
      _startContinuousVibration();

      // Listen for audio completion
      _audioPlayer.onPlayerComplete.listen((event) {
        debugPrint('Audio completed');
        _stopVibration();
        _isCompleted = false;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Error playing sound or vibrating: $e');
      // Even if sound fails, still vibrate
      _startContinuousVibration();
    }
  }

  void _startContinuousVibration() {
    int vibrationCount = 0;
    const maxVibrations = 120; // 60 seconds * 2 vibrations per second

    _vibrationTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (vibrationCount < maxVibrations) {
        HapticFeedback.heavyImpact();
        vibrationCount++;
      } else {
        timer.cancel();
        _vibrationTimer = null;
      }
    });
  }

  void _stopVibration() {
    _vibrationTimer?.cancel();
    _vibrationTimer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopVibration();
    _audioPlayer.dispose();
    super.dispose();
  }
}
