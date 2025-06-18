import 'package:flutter/material.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/character_model.dart';
import 'character_detail_page.dart';

class LikePage extends StatefulWidget {
  const LikePage({super.key});

  @override
  State<LikePage> createState() => _LikePageState();
}

class _LikePageState extends State<LikePage>
    with AutomaticKeepAliveClientMixin {
  // 用于跟踪图像加载失败的Map
  final Map<String, bool> _failedImages = {};

  // 用于存储关注状态
  final Map<String, bool> _followStatus = {};

  // 用于存储角色粉丝数
  final Map<String, int> _fansCount = {};

  // 所有角色列表
  late List<Character> allCharacters;

  // 随机选择的角色
  late List<Character> displayCharacters;

  @override
  bool get wantKeepAlive => true; // 保持页面状态，避免重新渲染

  @override
  void initState() {
    super.initState();
    allCharacters = CharacterData.getAllCharacters();
    displayCharacters = getRandomCharacters();
    _loadFollowStatus();
  }

  // 加载关注状态
  Future<void> _loadFollowStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (var character in allCharacters) {
        final isFollowed =
            prefs.getBool('follow_${character.riizeUserId}') ?? false;
        _followStatus[character.riizeUserId] = isFollowed;
        _fansCount[character.riizeUserId] =
            character.riizeFansCount + (isFollowed ? 1 : 0);
      }
    });
  }

  // 保存关注状态
  Future<void> _saveFollowStatus(String userId, bool isFollowed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('follow_$userId', isFollowed);
  }

  // 切换关注状态
  void _toggleFollow(String userId) {
    final currentStatus = _followStatus[userId] ?? false;
    final newStatus = !currentStatus;

    setState(() {
      _followStatus[userId] = newStatus;
      // 更新粉丝数
      _fansCount[userId] = (_fansCount[userId] ?? 0) + (newStatus ? 1 : -1);
    });

    _saveFollowStatus(userId, newStatus);
  }

  // 获取随机头像，确保不重复
  List<String> getRandomAvatars(String excludeUserId, int count) {
    final avatars = <String>[];
    final usedIds = <String>{excludeUserId};
    final random = Random(DateTime.now().millisecondsSinceEpoch);

    while (avatars.length < count && usedIds.length < allCharacters.length) {
      final randomIndex = random.nextInt(allCharacters.length);
      final randomId = allCharacters[randomIndex].riizeUserId;

      if (!usedIds.contains(randomId)) {
        usedIds.add(randomId);
        avatars.add(allCharacters[randomIndex].riizeUserIcon);
      }
    }

    return avatars;
  }

  // 获取6个随机角色
  List<Character> getRandomCharacters() {
    final characters = List<Character>.from(allCharacters);
    characters.shuffle(Random(DateTime.now().millisecondsSinceEpoch));
    return characters.take(6).toList();
  }

  // 显示全屏图片预览
  void _showFullScreenImage(BuildContext context, String imagePath) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // 图片居中显示
              Center(
                child: Image.asset(
                  imagePath,
                  width: MediaQuery.of(context).size.width,
                  fit: BoxFit.contain,
                ),
              ),

              // 关闭按钮
              Positioned(
                top: 40,
                left: 20,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.black,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = screenWidth - 30;
    final cardHeight = itemWidth * 0.913; // 设置卡片高度为宽度的0.913倍，保持合适的比例

    // 计算图片网格的尺寸
    final imageWidth = (screenWidth - 60 - 12) / 3; // 屏幕宽度 - 左右边距 - 间隙
    final imageHeight = 140.0;

    return Scaffold(
      body: Stack(
        children: [
          // 顶部背景图 - 使用绝对定位，不占用列表空间
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'lib/assets/Photo/like_top_bg_2025_6_16.png',
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),

          // 列表内容 - 从顶部68px开始
          Positioned(
            top: 68, // 列表从顶部68px开始
            left: 0,
            right: 0,
            bottom: 0,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(), // 确保始终可滚动
              padding: EdgeInsets.zero, // 移除默认内边距
              itemCount: displayCharacters.length,
              itemBuilder: (context, index) {
                final character = displayCharacters[index];
                final userId = character.riizeUserId;
                final isFollowed = _followStatus[userId] ?? false;
                final fansCount =
                    _fansCount[userId] ?? character.riizeFansCount;

                // 获取3个随机头像用于粉丝显示
                final randomAvatars = getRandomAvatars(userId, 3);

                return Padding(
                  padding: EdgeInsets.only(
                    left: 15,
                    right: 15,
                    bottom: 24,
                  ),
                  child: Stack(
                    clipBehavior: Clip.none, // 允许子元素超出边界
                    children: [
                      // 卡片主体
                      Container(
                        height: cardHeight,
                        width: itemWidth,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: const DecorationImage(
                            image: AssetImage(
                                'lib/assets/Photo/like_people_2025_6_16.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Stack(
                          children: [
                            // 只有第一个项目显示热门标签，精确放在左上角(0,0)位置
                            // 使用外层Stack确保热门标签不受卡片圆角的影响
                            if (index == 0)
                              Positioned(
                                top: -20,
                                left: 0,
                                child: Image.asset(
                                  'lib/assets/Photo/like_people_hot_2025_6_16.png',
                                  width: 60,
                                  height: 60,
                                ),
                              ),
                            // 用户圆形头像 - 放在指定位置，使用角色自己的头像
                            Positioned(
                              left: 15,
                              top: 43,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CharacterDetailPage(
                                        character: character,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    // 使用条件判断选择显示的图像
                                    image: DecorationImage(
                                      image: _failedImages[
                                                  character.riizeUserIcon] ==
                                              true
                                          ? const AssetImage(
                                              'lib/assets/Photo/me_default_2025_6_13.png')
                                          : AssetImage(character.riizeUserIcon),
                                      fit: BoxFit.cover,
                                      onError: (exception, stackTrace) {
                                        // 标记图像加载失败
                                        setState(() {
                                          _failedImages[
                                              character.riizeUserIcon] = true;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // 用户名和个性签名 - 放在头像右侧8px位置
                            Positioned(
                              left: 15 + 50 + 8, // 头像左边距 + 头像宽度 + 间距8px
                              top: 43, // 与头像顶部对齐
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // 用户名 - 白色、18号、粗体
                                  Text(
                                    character.riizeUserName,
                                    style: const TextStyle(
                                      color: Color(0xFFFFFFFF),
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  // 个性签名 - #D1D1D1、14号、常规
                                  SizedBox(
                                    width: 250,
                                    height: 20,
                                    child: Text(
                                      character.riizeNickName,
                                      style: const TextStyle(
                                        color: Color(0xFFD1D1D1),
                                        fontSize: 14,
                                        fontWeight: FontWeight.normal,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 图片滚动区域 - 放在头像下方16px位置
                            Positioned(
                              left: 15,
                              top: 43 + 50 + 16, // 头像顶部位置 + 头像高度 + 间距16px
                              right: 15,
                              child: SizedBox(
                                height: imageHeight,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount:
                                      character.riizeShowPhotoArray.length,
                                  itemBuilder: (context, photoIndex) {
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        right: photoIndex <
                                                character.riizeShowPhotoArray
                                                        .length -
                                                    1
                                            ? 6
                                            : 0,
                                      ),
                                      child: GestureDetector(
                                        onTap: () => _showFullScreenImage(
                                          context,
                                          character
                                              .riizeShowPhotoArray[photoIndex],
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: Image.asset(
                                            character.riizeShowPhotoArray[
                                                photoIndex],
                                            width: imageWidth,
                                            height: imageHeight,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),

                            // 粉丝数量
                            Positioned(
                              left: 15,
                              bottom: 15,
                              child: Row(
                                mainAxisSize: MainAxisSize.min, // 确保行仅占用所需的空间
                                children: [
                                  // 粉丝头像组
                                  SizedBox(
                                    width: 55,
                                    height: 19, // 明确指定高度
                                    child: Stack(
                                      children: [
                                        for (int i = 0;
                                            i < randomAvatars.length;
                                            i++)
                                          Positioned(
                                            left: i * 17.0, // 间距为-2，所以19-2=17
                                            child: Container(
                                              width: 19,
                                              height: 19,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 1,
                                                ),
                                                image: DecorationImage(
                                                  image: AssetImage(
                                                      randomAvatars[i]),
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    '$fansCount followers',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 关注按钮 - 修改尺寸为56*28
                            Positioned(
                              right: 15,
                              bottom: 15,
                              child: GestureDetector(
                                onTap: () => _toggleFollow(userId),
                                child: Image.asset(
                                  isFollowed
                                      ? 'lib/assets/Photo/like_people_follow_s_2025_6_16.png'
                                      : 'lib/assets/Photo/like_people_follow_n_2025_6_16.png',
                                  width: 56,
                                  height: 28,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
