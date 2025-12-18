import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../services/timer_service.dart';
import '../services/notification_service.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  final TimerService _timerService = TimerService();

  final List<int> _presetSeconds = [
    60, 120, 180, 240, 300, 600, 900, 1200, 1800, 2700, 3600, 5400, 7200,
  ];

  final List<String> _presetLabels = [
    '1分钟', '2分钟', '3分钟', '4分钟', '5分钟', '10分钟', '15分钟',
    '20分钟', '30分钟', '45分钟', '1小时', '1.5小时', '2小时',
  ];

  int _selectedIndex = 5; // 默认10分钟

  @override
  void initState() {
    super.initState();
    _timerService.addListener(_onTimerUpdate);
  }

  @override
  void dispose() {
    _timerService.removeListener(_onTimerUpdate);
    _timerService.dispose();
    super.dispose();
  }

  void _onTimerUpdate() {
    if (mounted) {
      setState(() {});

      if (_timerService.isRunning) {
        NotificationService.showTimerNotification(
          timeRemaining: _timerService.formattedTime,
        );
      } else if (_timerService.remainingSeconds == 0) {
        NotificationService.showTimerCompleteNotification();
        NotificationService.cancelTimerNotification();
      }
    }
  }

  void _startTimer() {
    final seconds = _presetSeconds[_selectedIndex];
    _timerService.startTimer(seconds);
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _timerService.isRunning || _timerService.remainingSeconds > 0;

    return Scaffold(
      body: Stack(
        children: [
          // 背景渐变
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1a1a2e),
                  Color(0xFF16213e),
                  Color(0xFF0f3460),
                  Color(0xFF533483),
                ],
              ),
            ),
          ),
          // 磨砂玻璃效果
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
            child: Container(
              color: Colors.black.withValues(alpha: 0.3),
            ),
          ),
          // 主内容
          SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  if (isActive) _buildActiveTimerHeader() else _buildSetupHeader(),
                  const Spacer(),
                  _buildCapsuleBar(),
                  const Spacer(),
                  _buildActionButton(),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupHeader() {
    return Column(
      children: [
        const Text(
          '设置计时器:',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: _showTimePicker,
          child: Text(
            _presetLabels[_selectedIndex],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveTimerHeader() {
    return Column(
      children: [
        Text(
          _presetLabels[_selectedIndex],
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _timerService.formattedTime,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.w200,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _buildCapsuleBar() {
    final isActive = _timerService.isRunning || _timerService.remainingSeconds > 0;

    double progress;
    if (isActive) {
      final initialTime = _timerService.initialSeconds > 0
          ? _timerService.initialSeconds
          : _presetSeconds[_selectedIndex];
      progress = _timerService.remainingSeconds / initialTime;
    } else {
      // 设置模式: 根据选中的索引显示进度
      // 索引0(1分钟)在底部, 索引12(2小时)在顶部
      progress = (_selectedIndex + 1) / _presetSeconds.length;
    }

    // 计算颜色: progress高(刚开始)=绿色, progress低(快结束)=红色
    Color progressColor;
    if (isActive) {
      // 倒计时中: 从绿色渐变到红色
      progressColor = Color.lerp(
        Color(0xFFFF3B30), // 红色(剩余0%)
        Color(0xFF34C759), // 绿色(剩余100%)
        progress,
      )!;
    } else {
      // 设置模式: 白色
      progressColor = Colors.white;
    }

    return GestureDetector(
      onVerticalDragUpdate: isActive ? null : (details) {
        _handleDrag(details.localPosition.dy);
      },
      onTapDown: isActive ? null : (details) {
        _handleTap(details.localPosition.dy);
      },
      child: Container(
        width: 140,
        height: 380,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              // 上半部分 - 深色/已用时间
              Expanded(
                flex: ((1 - progress) * 100).toInt(),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.8),
                        Colors.black.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                  child: isActive ? null : _buildSegmentLines(((1 - progress) * 10).toInt()),
                ),
              ),
              // 下半部分 - 剩余时间(颜色渐变)
              Expanded(
                flex: (progress * 100).toInt(),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        progressColor.withValues(alpha: 0.9),
                        progressColor.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                  child: isActive ? null : _buildSegmentLines((progress * 10).toInt()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleDrag(double localY) {
    // 计算点击/拖动位置对应的时间索引
    // 从底部到顶部: 1分钟 -> 2小时
    final ratio = 1 - (localY / 380); // 反转,底部为0,顶部为1
    final index = (_presetSeconds.length * ratio).floor().clamp(0, _presetSeconds.length - 1);

    if (index != _selectedIndex) {
      HapticFeedback.lightImpact(); // 轻微振动
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _handleTap(double localY) {
    _handleDrag(localY);
  }

  Widget _buildSegmentLines(int count) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        count > 0 ? count : 1,
        (index) => Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          color: Colors.white24,
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    final isActive = _timerService.isRunning || _timerService.remainingSeconds > 0;

    if (isActive) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCircleButton(
            label: '取消',
            color: Colors.grey,
            onTap: () {
              _timerService.stopTimer();
              NotificationService.cancelTimerNotification();
            },
          ),
          _buildCircleButton(
            label: _timerService.isRunning ? '暂停' : '继续',
            color: Colors.orange,
            onTap: () {
              if (_timerService.isRunning) {
                _timerService.pauseTimer();
                NotificationService.cancelTimerNotification();
              } else {
                _timerService.resumeTimer();
              }
            },
          ),
        ],
      );
    }

    return _buildCircleButton(
      label: '启动',
      color: const Color(0xFF34C759),
      onTap: _startTimer,
    );
  }

  Widget _buildCircleButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 15,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  void _showTimePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      builder: (context) => Container(
        height: 300,
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消', style: TextStyle(color: Colors.orange)),
                  ),
                  const Text(
                    '选择时间',
                    style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('完成', style: TextStyle(color: Colors.orange)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListWheelScrollView.useDelegate(
                controller: FixedExtentScrollController(initialItem: _selectedIndex),
                itemExtent: 44,
                perspective: 0.005,
                diameterRatio: 1.2,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: (index) {
                  setState(() => _selectedIndex = index);
                },
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: _presetLabels.length,
                  builder: (context, index) {
                    return Center(
                      child: Text(
                        _presetLabels[index],
                        style: TextStyle(
                          fontSize: 22,
                          color: index == _selectedIndex
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.4),
                          fontWeight: index == _selectedIndex ? FontWeight.w500 : FontWeight.w400,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
