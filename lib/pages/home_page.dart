import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/character_model.dart';
import 'character_detail_page.dart';
import 'report_page.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  // 滚动控制器
  final ScrollController _scrollController = ScrollController();
  // 导航栏透明度
  double _navbarOpacity = 0.0;
  // 获取所有角色数据
  final List<Character> _characters = CharacterData.getAllCharacters();
  // 随机选择8个角色用于展示 - 初始化为空列表，避免late错误
  List<Character> _randomCharacters = [];
  // 随机数生成器
  final Random _random = Random();
  // 存储每个角色的随机展示图片，避免滚动时重新选择
  final Map<int, String> _characterShowPhotos = {};
  // 存储被拉黑的用户ID
  Set<String> _blockedUserIds = {};
  // 是否正在加载数据
  bool _isLoading = true;

  // 音频播放器
  late AudioPlayer _audioPlayer;
  // 是否正在播放音乐
  bool _isPlaying = false;
  // 是否每次都显示提示
  bool _shouldShowPrompt = true;
  // 旋转动画控制器
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    // 监听滚动事件，更新导航栏透明度
    _scrollController.addListener(_updateNavbarOpacity);
    // 加载被拉黑的用户和初始化数据
    _initializeData();
    // 初始化音频播放器
    _initAudioPlayer();
    // 初始化旋转动画控制器
    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
  }

  @override
  void dispose() {
    // 销毁滚动控制器
    _scrollController.removeListener(_updateNavbarOpacity);
    _scrollController.dispose();
    // 销毁音频播放器
    _audioPlayer.dispose();
    // 销毁动画控制器
    _rotationController.dispose();
    super.dispose();
  }

  // 初始化音频播放器
  Future<void> _initAudioPlayer() async {
    _audioPlayer = AudioPlayer();
    // 加载用户偏好设置
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _shouldShowPrompt = prefs.getBool('show_music_prompt') ?? true;
    });

    // 监听播放状态变化
    _audioPlayer.playerStateStream.listen((state) {
      if (state.playing) {
        _rotationController.repeat(); // 开始旋转
      } else {
        _rotationController.stop(); // 停止旋转
      }
    });
  }

  // 播放背景音乐
  Future<void> _playBackgroundMusic() async {
    if (!_isPlaying) {
      try {
        // 创建带有MediaItem标签的音频源
        final audioSource = AudioSource.asset(
          'lib/assets/audio/home_background_music_2025_6_18.mp3',
          tag: MediaItem(
            id: 'background_music',
            album: 'Riize',
            title: 'Background Music',
            artUri:
                Uri.parse('asset://lib/assets/Photo/home_music_2025_6_18.png'),
          ),
        );

        // 设置音频源
        await _audioPlayer.setAudioSource(audioSource);
        // 设置循环播放
        await _audioPlayer.setLoopMode(LoopMode.all);
        // 开始播放
        await _audioPlayer.play();
        setState(() {
          _isPlaying = true;
        });
      } catch (e) {
        print('Error playing music: $e');
      }
    } else {
      // 如果正在播放，则暂停
      await _audioPlayer.pause();
      setState(() {
        _isPlaying = false;
      });
    }
  }

  // 显示音乐播放提示对话框
  void _showMusicPrompt() {
    bool tempShouldShowPrompt = _shouldShowPrompt;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Background Music'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                      'This app features AI-generated background music. Would you like to play it?'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Checkbox(
                        value: !tempShouldShowPrompt,
                        onChanged: (bool? value) {
                          setState(() {
                            tempShouldShowPrompt = !value!;
                          });
                        },
                      ),
                      const Text('Don\'t show this again'),
                    ],
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    // 保存用户选择
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool(
                        'show_music_prompt', tempShouldShowPrompt);
                    setState(() {
                      _shouldShowPrompt = tempShouldShowPrompt;
                    });
                    // 播放音乐
                    _playBackgroundMusic();
                  },
                  child: const Text('Play'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 处理音乐按钮点击
  void _handleMusicButtonTap() async {
    if (_shouldShowPrompt) {
      _showMusicPrompt();
    } else {
      _playBackgroundMusic();
    }
  }

  // 加载被拉黑的用户
  Future<void> _loadBlockedUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final blockedUsers = prefs.getStringList('blocked_users') ?? [];
    setState(() {
      _blockedUserIds = Set.from(blockedUsers);
    });
  }

  // 更新导航栏透明度
  void _updateNavbarOpacity() {
    // 当滚动超过100像素时开始显示导航栏
    final double opacity = (_scrollController.offset / 100).clamp(0.0, 1.0);
    setState(() {
      _navbarOpacity = opacity;
    });
  }

  // 随机选择指定数量的角色（排除被拉黑的用户）
  List<Character> _getRandomCharacters(int count) {
    // 创建角色列表的副本，避免修改原始列表
    final List<Character> availableCharacters = _characters
        .where((character) => !_blockedUserIds.contains(character.riizeUserId))
        .toList();

    // 打乱列表顺序
    availableCharacters.shuffle(_random);

    // 返回前count个角色，如果角色数量不足，则返回所有角色
    return availableCharacters.take(count).toList();
  }

  // 为每个随机选择的角色预先选择一张展示图片
  void _preSelectRandomPhotos() {
    for (int i = 0; i < _randomCharacters.length; i++) {
      Character character = _randomCharacters[i];
      if (character.riizeShowPhotoArray.isEmpty) {
        // 如果没有展示图片，使用用户头像
        _characterShowPhotos[i] = character.riizeUserIcon;
      } else {
        // 随机选择一张展示图片
        _characterShowPhotos[i] = character.riizeShowPhotoArray[
            _random.nextInt(character.riizeShowPhotoArray.length)];
      }
    }
  }

  // 获取角色的预选展示图片
  String _getCharacterShowPhoto(int index) {
    return _characterShowPhotos[index] ??
        _randomCharacters[index].riizeUserIcon;
  }

  // 显示底部操作菜单
  void _showActionSheet(Character character) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Options'),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _showReportPage(character);
            },
            child: const Text('Report'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _showBlockDialog(character);
            },
            child: const Text('Block'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  // 显示举报页面
  void _showReportPage(Character character) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportPage(character: character),
      ),
    );
  }

  // 显示拉黑确认对话框
  void _showBlockDialog(Character character) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Block User'),
          content: Text(
              'Are you sure you want to block ${character.riizeUserName}?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _blockUser(character);
              },
              child: const Text('Block'),
            ),
          ],
        );
      },
    );
  }

  // 拉黑用户
  void _blockUser(Character character) async {
    final prefs = await SharedPreferences.getInstance();
    final blockedUsers = prefs.getStringList('blocked_users') ?? [];

    if (!blockedUsers.contains(character.riizeUserId)) {
      blockedUsers.add(character.riizeUserId);
      await prefs.setStringList('blocked_users', blockedUsers);
    }

    // 更新被拉黑用户集合
    setState(() {
      _blockedUserIds.add(character.riizeUserId);
    });

    // 重新加载角色数据（排除被拉黑的用户）
    setState(() {
      _randomCharacters = _getRandomCharacters(8);
      _preSelectRandomPhotos();
    });

    // 显示拉黑成功提示
    _showCenteredToast('${character.riizeUserName} has been blocked');
  }

  // 显示屏幕中间的toast提示
  void _showCenteredToast(String message) {
    // 移除之前的toast
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    // 显示新的居中toast
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (BuildContext dialogContext) {
        // 2秒后自动关闭
        Future.delayed(const Duration(seconds: 2), () {
          // 检查widget是否仍然mounted，并使用dialogContext
          if (mounted && Navigator.canPop(dialogContext)) {
            Navigator.of(dialogContext).pop();
          }
        });

        return AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.7),
          content: Text(
            message,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        );
      },
    );
  }

  // 构建角色卡片
  Widget _buildCharacterCard(Character character, int index) {
    // 根据索引计算垂直偏移量
    double verticalOffset = (index % 2) * 12.0; // 偶数索引为0，奇数索引为12
    double verticalBottomOffset =
        (index % 2 == 1) ? 0.0 : 12.0; // 奇数索引为12，偶数索引为0

    return Container(
      width: 100,
      height: 160,
      margin: const EdgeInsets.symmetric(horizontal: 6), // 左右间距为12的一半
      // 添加顶部边距，根据索引决定
      padding:
          EdgeInsets.only(top: verticalOffset, bottom: verticalBottomOffset),
      child: GestureDetector(
        onTap: () {
          // 点击卡片跳转到角色详情页
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CharacterDetailPage(character: character),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black, // 黑色背景
            borderRadius: BorderRadius.circular(16), // 圆角16px
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 2), // 头像距离顶部y:2的位置
            child: Column(
              children: [
                // 角色图片
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    character.riizeUserIcon,
                    width: 96,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 8),
                // 角色名字
                Text(
                  character.riizeNickName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 构建胶囊按钮
  Widget _buildCapsuleButton(String text, VoidCallback onTap,
      {double left = 0, double top = 0}) {
    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withOpacity(0.1), width: 1),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  // 构建胶囊按钮区域
  Widget _buildCapsuleButtonsArea() {
    // 第一行显示5个角色
    final firstRowCharacters = _characters.take(5).toList();
    // 第二行显示4个角色（不与第一行重复）
    final secondRowCharacters = _characters.skip(5).take(4).toList();

    // 计算第一行按钮的总宽度
    double firstRowWidth = 0;
    for (var character in firstRowCharacters) {
      // 估算每个按钮的宽度（文本长度 * 字体大小 + 左右内边距 + 外边距）
      firstRowWidth += character.riizeNickName.length * 8 + 32 + 8;
    }

    // 计算第二行按钮的总宽度
    double secondRowWidth = 0;
    for (var character in secondRowCharacters) {
      // 估算每个按钮的宽度
      secondRowWidth += character.riizeNickName.length * 8 + 32 + 8;
    }

    // 第二行起始位置增加40像素
    secondRowWidth += 40;

    // 取两行中较大的宽度作为内容宽度
    double contentWidth =
        firstRowWidth > secondRowWidth ? firstRowWidth : secondRowWidth;

    // 创建按钮列表
    List<Widget> buttonWidgets = [];

    // 添加第一行胶囊按钮 (y: 0)
    double left = 0;
    for (int index = 0; index < firstRowCharacters.length; index++) {
      buttonWidgets.add(
        _buildCapsuleButton(
          firstRowCharacters[index].riizeNickName,
          () {
            // 点击跳转到角色详情页
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CharacterDetailPage(
                  character: firstRowCharacters[index],
                ),
              ),
            );
          },
          left: left,
          top: 0,
        ),
      );
      left += firstRowCharacters[index].riizeNickName.length * 8 + 32 + 8;
    }

    // 添加第二行胶囊按钮 (y: 60)
    left = 40; // 第二行起始位置增加40像素
    for (int index = 0; index < secondRowCharacters.length; index++) {
      buttonWidgets.add(
        _buildCapsuleButton(
          secondRowCharacters[index].riizeNickName,
          () {
            // 点击跳转到角色详情页
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CharacterDetailPage(
                  character: secondRowCharacters[index],
                ),
              ),
            );
          },
          left: left,
          top: 60,
        ),
      );
      left += secondRowCharacters[index].riizeNickName.length * 8 + 32 + 8;
    }

    return Container(
      height: 100,
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          width: contentWidth,
          height: 100,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Stack(
            children: buttonWidgets,
          ),
        ),
      ),
    );
  }

  // 构建角色图片展示项
  Widget _buildCharacterPhotoItem(
      Character character, int index, double itemWidth) {
    return GestureDetector(
      onTap: () {
        // 点击跳转到角色详情页
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CharacterDetailPage(character: character),
          ),
        );
      },
      child: Container(
        width: itemWidth,
        height: 222, // 固定高度为222px
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10), // 整个item圆角为10px
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start, // 左对齐
              children: [
                // 上方角色展示图片
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                  child: SizedBox(
                    width: itemWidth,
                    height: 182,
                    child: Image.asset(
                      _getCharacterShowPhoto(index),
                      width: itemWidth,
                      height: 182,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // 下方角色信息区域
                SizedBox(
                  width: itemWidth,
                  height: 40,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center, // 垂直居中
                      children: [
                        // 角色头像
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: AssetImage(character.riizeUserIcon),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        // 角色名字
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            character.riizeNickName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // 点赞按钮和数量
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  character.isLiked = !character.isLiked;
                                  if (character.isLiked) {
                                    character.likeCount++;
                                  } else {
                                    character.likeCount--;
                                  }
                                });
                              },
                              child: Icon(
                                character.isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: character.isLiked
                                    ? Colors.red
                                    : Colors.grey,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${character.likeCount}',
                              style: TextStyle(
                                fontSize: 12,
                                color: character.isLiked
                                    ? Colors.red
                                    : Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // 右上角举报按钮
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _showActionSheet(character),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建角色图片网格
  Widget _buildCharacterPhotoGrid(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = (screenWidth - 30 - 7) / 2.0; // 计算每个Item的宽度

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: GridView.builder(
        shrinkWrap: true, // 高度自适应内容
        physics: const NeverScrollableScrollPhysics(), // 禁用滚动，让外层ScrollView处理滚动
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 一行两个
          mainAxisSpacing: 14, // 垂直间距增加为14
          crossAxisSpacing: 7, // 水平间距
          childAspectRatio: itemWidth / 222, // 宽高比例，确保高度为222px
        ),
        itemCount: _randomCharacters.length,
        itemBuilder: (context, index) {
          return _buildCharacterPhotoItem(
              _randomCharacters[index], index, itemWidth);
        },
      ),
    );
  }

  // 初始化数据
  Future<void> _initializeData() async {
    await _loadBlockedUsers();

    setState(() {
      // 随机选择8个角色
      _randomCharacters = _getRandomCharacters(8);
      // 为每个随机选择的角色预先选择一张展示图片
      _preSelectRandomPhotos();
      // 数据加载完成
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 获取屏幕宽度
    final screenWidth = MediaQuery.of(context).size.width;
    // 获取状态栏高度
    final statusBarHeight = MediaQuery.of(context).padding.top;
    // 导航栏总高度 = 状态栏高度 + 44
    final navbarHeight = statusBarHeight + 44;

    return Scaffold(
      body: Stack(
        children: [
          // 主内容区域
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController, // 使用滚动控制器
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.zero, // 设置上下左右边距为0
                  child: Column(
                    children: [
                      // 顶部背景图片区域（包含角色卡片）
                      Stack(
                        children: [
                          // 背景图片
                          Image.asset(
                            'lib/assets/Photo/home_top_bg_2025_6_17.png',
                            width: screenWidth, // 宽度为屏幕宽度
                            fit: BoxFit.cover, // 图片自适应高度并覆盖
                          ),

                          // 角色卡片横向滚动区域
                          Positioned(
                            top: statusBarHeight + 70, // 距离顶部状态栏高度+70
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 172,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal, // 横向滚动
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6), // 整体左右各留6px边距
                                itemCount: _characters.length,
                                itemBuilder: (context, index) {
                                  return _buildCharacterCard(
                                      _characters[index], index);
                                },
                              ),
                            ),
                          ),

                          // 胶囊按钮区域 - 在角色卡片下方
                          Positioned(
                            top: statusBarHeight +
                                70 +
                                172 +
                                20, // 状态栏高度 + 70 + 角色卡片高度 + 20px间距
                            left: 0,
                            right: 0,
                            child: _buildCapsuleButtonsArea(),
                          ),
                        ],
                      ),

                      // home_look_2025_6_18图片区域 - 在顶部背景图片区域下方24px处
                      SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Image.asset(
                          'lib/assets/Photo/home_look_2025_6_18.png',
                          width: screenWidth - 30, // 宽度为屏幕宽度减30
                          fit: BoxFit.fitWidth, // 图片宽度自适应，高度按比例调整
                        ),
                      ),

                      // home_daily_2025_6_18图片区域 - 在home_look_2025_6_18图片下方28px处
                      SizedBox(height: 28),
                      Center(
                        child: Image.asset(
                          'lib/assets/Photo/home_daily_2025_6_18.png',
                          width: screenWidth - 172, // 宽度为屏幕宽度减172
                          fit: BoxFit.fitWidth, // 图片宽度自适应，高度按比例调整
                        ),
                      ),

                      // 角色图片网格区域 - 在home_daily_2025_6_18图片下方28px处
                      SizedBox(height: 0),
                      _buildCharacterPhotoGrid(context),

                      // 底部留白
                      SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 顶部自定义导航栏 - 初始透明度为0，随滚动显示
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  height: navbarHeight,
                  color: Colors.white.withOpacity(_navbarOpacity * 0.9),
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: statusBarHeight,
                      left: 16,
                      right: 16,
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Opacity(
                            opacity: _navbarOpacity,
                            child: const Text(
                              "Daily Design Update",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                        // 音乐播放按钮
                        Positioned(
                          right: 15,
                          top: 6,
                          child: GestureDetector(
                            onTap: _handleMusicButtonTap,
                            child: RotationTransition(
                              turns: _rotationController,
                              child: Image.asset(
                                'lib/assets/Photo/home_music_2025_6_18.png',
                                width: 32,
                                height: 32,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
