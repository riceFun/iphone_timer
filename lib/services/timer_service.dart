import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

class TimerService extends ChangeNotifier {
  Timer? _timer;
  int _remainingSeconds = 0;
  int _initialSeconds = 0;
  bool _isRunning = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  int get remainingSeconds => _remainingSeconds;
  int get initialSeconds => _initialSeconds;
  bool get isRunning => _isRunning;

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
    _isRunning = false;
    _remainingSeconds = 0;
    _initialSeconds = 0;
    notifyListeners();
  }

  void _onTimerComplete() async {
    // Play sound and vibrate
    try {
      await _audioPlayer.play(AssetSource('sounds/timer_complete.mp3'));
      await HapticFeedback.vibrate();

      // Vibrate pattern for iOS-like effect
      Future.delayed(const Duration(milliseconds: 200), () {
        HapticFeedback.vibrate();
      });
      Future.delayed(const Duration(milliseconds: 400), () {
        HapticFeedback.vibrate();
      });
    } catch (e) {
      debugPrint('Error playing sound or vibrating: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
