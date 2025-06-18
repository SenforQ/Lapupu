import 'package:flutter/material.dart';
import 'dart:math';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../models/character_model.dart';

class CallPage extends StatefulWidget {
  final Character character;

  const CallPage({super.key, required this.character});

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimationX;
  late Animation<double> _shakeAnimationY;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isDisposed = false;
  int _rippleKey = 0; // 用于强制重建水波纹动画
  late String _backgroundImage; // 存储随机选择的背景图片路径

  @override
  void initState() {
    super.initState();

    // 在初始化时随机选择背景图片
    final random = Random();
    _backgroundImage = widget.character.riizeShowPhotoArray.isEmpty
        ? widget.character.riizeUserIcon
        : widget.character.riizeShowPhotoArray[
            random.nextInt(widget.character.riizeShowPhotoArray.length)];

    // 初始化抖动动画，更快的频率
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

  Future<void> _playCallSound() async {
    try {
      // 创建音频源
      final audioSource = AudioSource.asset(
        'lib/assets/audio/chat_call_2025_6_18.mp3',
        tag: MediaItem(
          id: 'call_sound',
          album: 'Riize',
          title: 'Call Sound',
        ),
      );

      // 设置音频源并播放
      await _audioPlayer.setAudioSource(audioSource);
      await _audioPlayer.play();
    } catch (e) {
      print('Error playing call sound: $e');
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
                const Text(
                  'On the line...',
                  style: TextStyle(
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
