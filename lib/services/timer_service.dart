import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

class TimerService extends ChangeNotifier {
  static const MethodChannel _foregroundChannel =
      MethodChannel('com.example.iphone_timer/foreground_service');
  static const MethodChannel _alarmChannel =
      MethodChannel('com.example.iphone_timer/alarm');

  Timer? _timer;
  Timer? _vibrationTimer;
  int _remainingSeconds = 0;
  int _initialSeconds = 0;
  bool _isRunning = false;
  bool _isCompleted = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  static bool _initialized = false;

  TimerService() {
    if (!_initialized) {
      _initialized = true;
      // 监听来自MainActivity的完成回调
      _alarmChannel.setMethodCallHandler((call) async {
        if (call.method == 'onTimerComplete') {
          debugPrint('Received timer complete callback from MainActivity');
          onTimerCompleted();
        }
      });
    }
  }

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

  void startTimer(int seconds) async {
    _stopVibration();
    _isCompleted = false;
    _initialSeconds = seconds;
    _remainingSeconds = seconds;
    _isRunning = true;
    notifyListeners();

    // 启动前台服务中的倒计时 - 这样即使应用被杀死,倒计时也会继续
    try {
      await _foregroundChannel.invokeMethod('startTimerInService', {'seconds': seconds});
      debugPrint('Timer started in foreground service: $seconds seconds');
    } catch (e) {
      debugPrint('Failed to start timer in service: $e');
    }

    // 同时在Flutter中运行Timer用于UI更新(如果应用在前台)
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

  void pauseTimer() async {
    _timer?.cancel();
    _isRunning = false;
    notifyListeners();
  }

  void resumeTimer() async {
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

  void stopTimer() async {
    _timer?.cancel();
    _stopVibration();
    _isRunning = false;
    _isCompleted = false;
    _remainingSeconds = 0;
    _initialSeconds = 0;

    // 停止前台服务
    try {
      await _foregroundChannel.invokeMethod('stopForegroundService');
      // 通知MainActivity倒计时已停止
      await _foregroundChannel.invokeMethod('stopTimer');
      debugPrint('Foreground service stopped');
    } catch (e) {
      debugPrint('Failed to stop foreground service: $e');
    }

    notifyListeners();
  }

  void dismissCompletion() async {
    _stopVibration();
    _audioPlayer.stop();
    _isCompleted = false;

    // 停止前台服务
    try {
      await _foregroundChannel.invokeMethod('stopForegroundService');
      // 通知MainActivity倒计时已停止
      await _foregroundChannel.invokeMethod('stopTimer');
    } catch (e) {
      debugPrint('Failed to stop foreground service: $e');
    }

    notifyListeners();
  }

  /// Called when timer completes (from service or alarm)
  void onTimerCompleted() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _remainingSeconds = 0;
    _onTimerComplete();
  }

  void _onTimerComplete() async {
    _isCompleted = true;
    notifyListeners();

    // Play sound and start continuous vibration
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      await _audioPlayer.setVolume(1);
      await _audioPlayer.play(AssetSource('sounds/timer_complete.mp3'));
      debugPrint('Audio playing...');

      // Start continuous vibration
      _startContinuousVibration();

      // Listen for audio completion
      _audioPlayer.onPlayerComplete.listen((event) async {
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
