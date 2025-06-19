import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/character_model.dart';

class CallPage extends StatefulWidget {
  final Character character;

  const CallPage({super.key, required this.character});

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> with TickerProviderStateMixin {
  // 音频播放器
  final AudioPlayer _audioPlayer = AudioPlayer();

  // 背景图片路径
  late String _backgroundImage;
  // 是否已销毁
  bool _isDisposed = false;
  // 抖动动画控制器
  late AnimationController _shakeController;
  // X轴抖动动画
  late Animation<double> _shakeAnimationX;
  // Y轴抖动动画
  late Animation<double> _shakeAnimationY;
  // 水波纹动画key
  int _rippleKey = 0;
  // 是否正在响铃
  bool _isRinging = false;

  @override
  void initState() {
    super.initState();
    // 设置背景图片
    _backgroundImage = widget.character.riizeUserIcon;

    // 初始化抖动动画控制器
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    // 创建X轴抖动效果
    _shakeAnimationX = Tween<double>(begin: -3, end: 3).animate(
      CurvedAnimation(
        parent: _shakeController,
        curve: Curves.linear,
      ),
    );

    // 创建Y轴抖动效果
    _shakeAnimationY = Tween<double>(begin: -3, end: 3).animate(
      CurvedAnimation(
        parent: _shakeController,
        curve: Curves.linear,
      ),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _shakeController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _shakeController.forward();
        }
      });

    // 开始抖动动画
    _shakeController.forward();

    // 播放通话音效
    _playCallSound();

    // 30秒后自动返回
    Future.delayed(const Duration(seconds: 30), () {
      if (!_isDisposed) {
        Navigator.of(context).pop();
      }
    });
  }

  // 播放通话音效
  Future<void> _playCallSound() async {
    setState(() {
      _isRinging = true;
    });

    try {
      print('Starting to play call sound...');

      // 设置音频配置
      print('Setting call sound configuration...');
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);

      // 播放通话音效
      print('Playing call sound file: audio/chat_call_2025_6_18.mp3');
      await _audioPlayer.play(AssetSource('audio/chat_call_2025_6_18.mp3'));

      print('Call sound playback started successfully');

      // 监听播放完成
      _audioPlayer.onPlayerComplete.listen((_) {
        print('Call sound playback completed');
        if (mounted) {
          setState(() => _isRinging = false);
        }
      });

      // 监听播放状态变化
      _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
        print('Call sound player state changed: $state');
        if (mounted) {
          setState(() {
            _isRinging = state == PlayerState.playing;
          });
        }
      });
    } catch (e) {
      print('Error playing call sound: $e');
      if (mounted) {
        setState(() => _isRinging = false);
      }
    }
  }

  // 创建水波纹动画组件
  Widget _buildRippleEffect() {
    return TweenAnimationBuilder<double>(
      key: ValueKey(_rippleKey),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1500),
      builder: (context, value, child) {
        return Container(
          width: 80 + (value * 20),
          height: 80 + (value * 20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF01E3E9).withOpacity(1 - value),
          ),
        );
      },
      onEnd: () {
        if (!_isDisposed) {
          setState(() {
            _rippleKey++; // 更新key以重建动画
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _shakeController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 背景图片
          Positioned.fill(
            child: Image.asset(
              _backgroundImage,
              fit: BoxFit.cover,
            ),
          ),
          // 遮罩层
          Positioned.fill(
            child: Image.asset(
              'lib/assets/Photo/chat_bg_2025_6_18.png',
              fit: BoxFit.cover,
            ),
          ),
          // 头像和名称
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            left: 20,
            child: Row(
              children: [
                // 头像
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                    image: DecorationImage(
                      image: AssetImage(widget.character.riizeUserIcon),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // 名称
                Text(
                  widget.character.riizeUserName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // 挂断按钮和文字
          Positioned(
            left: 0,
            right: 0,
            bottom: 80,
            child: Column(
              children: [
                Text(
                  _isRinging ? 'Ringing...' : 'On the line...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 30),
                // 带水波纹和抖动效果的挂断按钮
                Center(
                  child: AnimatedBuilder(
                    animation:
                        Listenable.merge([_shakeAnimationX, _shakeAnimationY]),
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(
                            _shakeAnimationX.value, _shakeAnimationY.value),
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              _buildRippleEffect(),
                              Image.asset(
                                'lib/assets/Photo/chat_call_2025_6_18.png',
                                width: 60,
                                height: 60,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
