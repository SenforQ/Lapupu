import 'package:flutter/material.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import '../models/character_model.dart';
import '../models/chat_model.dart';
import 'chat_detail_page.dart';

class MessagePage extends StatefulWidget {
  const MessagePage({super.key});

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage>
    with AutomaticKeepAliveClientMixin {
  // 是否有历史消息
  bool _hasHistory = false;
  // 聊天历史
  Map<String, ChatHistory> _chatHistories = {};
  // 随机选择的角色
  late Character _randomCharacter;
  // 加载状态
  bool _isLoading = true;
  // 刷新指示器的key
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  bool get wantKeepAlive => false; // 不保持状态，每次都重新加载

  @override
  void initState() {
    super.initState();
    _randomCharacter = _getRandomCharacter();
    _loadChatHistories();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 每次依赖变化（如页面重新显示）时重新加载数据
    _loadChatHistories();
  }

  // 加载聊天历史
  Future<void> _loadChatHistories() async {
    setState(() {
      _isLoading = true;
    });

    final histories = await ChatHistory.getAllChatHistories();

    if (mounted) {
      setState(() {
        _chatHistories = histories;
        _hasHistory = histories.isNotEmpty;
        _isLoading = false;
      });
    }
  }

  // 刷新数据
  Future<void> _refreshData() async {
    await _loadChatHistories();
    return;
  }

  // 获取一个随机角色
  Character _getRandomCharacter() {
    final allCharacters = CharacterData.getAllCharacters();
    final random = Random(DateTime.now().millisecondsSinceEpoch);
    final randomIndex = random.nextInt(allCharacters.length);
    return allCharacters[randomIndex];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用super.build
    // 获取状态栏高度
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    if (_isLoading) {
      return Scaffold(
        body: Stack(
          children: [
            // 顶部渐变背景图 - 放在最底层
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Image.asset(
                'lib/assets/Photo/message_top_bg_2025_6_17.png',
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

            // 加载指示器
            const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF29D6E9),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      // 使用Stack作为根布局，让背景图不影响内容区域
      body: Stack(
        children: [
          // 顶部渐变背景图 - 放在最底层
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'lib/assets/Photo/message_top_bg_2025_6_17.png',
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          // 整体内容区域
          Column(
            children: [
              // 顶部标题区域
              SizedBox(
                height: statusBarHeight + 36, // 状态栏高度 + 额外空间
                child: Padding(
                  padding: EdgeInsets.only(
                    top: statusBarHeight + 11,
                    left: 15,
                    right: 15,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 左侧标题
                      Image.asset(
                        'lib/assets/Photo/message_2025_6_16.png',
                        width: 74,
                        height: 25,
                      ),

                      // 右侧刷新按钮
                      GestureDetector(
                        onTap: _refreshData,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.refresh,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 内容区域
              Expanded(
                child: RefreshIndicator(
                  key: _refreshIndicatorKey,
                  onRefresh: _refreshData,
                  color: const Color(0xFF29D6E9),
                  child:
                      _hasHistory ? _buildHistoryView() : _buildNoHistoryView(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 构建有历史消息的视图
  Widget _buildHistoryView() {
    final characterIds = _chatHistories.keys.toList();
    final allCharacters = CharacterData.getAllCharacters();
    final characterMap = {for (var c in allCharacters) c.riizeUserId: c};

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
      itemCount: characterIds.length,
      itemBuilder: (context, index) {
        final characterId = characterIds[index];
        final chatHistory = _chatHistories[characterId]!;
        final character = characterMap[characterId];

        if (character == null) {
          return const SizedBox.shrink();
        }

        final lastMessage = chatHistory.lastMessage;
        final lastUpdated = chatHistory.lastUpdated;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatDetailPage(character: character),
              ),
            ).then((_) {
              // 返回时刷新列表
              _loadChatHistories();
            });
          },
          child: Container(
            height: 84,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(42),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // 头像 - 左边距8，大小60*60
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: CircleAvatar(
                    radius: 30, // 60/2 = 30
                    backgroundImage: AssetImage(character.riizeUserIcon),
                  ),
                ),

                const SizedBox(width: 12),

                // 消息内容
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 用户名和时间
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            character.riizeUserName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF333333),
                            ),
                          ),
                          if (lastUpdated != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: Text(
                                _formatDateTime(lastUpdated),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF999999),
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // 最后一条消息
                      if (lastMessage != null)
                        Text(
                          lastMessage.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      // 今天，显示时间
      return DateFormat('HH:mm').format(dateTime);
    } else if (messageDate == yesterday) {
      // 昨天
      // return '昨天';
      return DateFormat('MM-dd').format(dateTime);
    } else {
      // 其他日期，显示月日
      return DateFormat('MM-dd').format(dateTime);
    }
  }

  // 构建无历史消息的视图
  Widget _buildNoHistoryView() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(), // 确保可以滚动以支持下拉刷新
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height - 100, // 减去顶部区域高度
          child: Column(
            children: [
              // 顶部空白区域，占用1份空间
              const Expanded(
                flex: 1,
                child: SizedBox(),
              ),

              // 中间内容区域，占用4份空间
              Expanded(
                flex: 4,
                child: LayoutBuilder(builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(), // 内部不滚动
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // 用户头像
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      spreadRadius: 1,
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                  image: DecorationImage(
                                    image: AssetImage(
                                        _randomCharacter.riizeUserIcon),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // 用户昵称
                              Text(
                                _randomCharacter.riizeUserName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF333333),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // 自我介绍
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Text(
                                  _randomCharacter.riizeIntroduction,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF666666),
                                    height: 1.4,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // "Now Chat" 胶囊按钮
                              ElevatedButton(
                                onPressed: () {
                                  // 跳转到聊天详情页
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatDetailPage(
                                        character: _randomCharacter,
                                      ),
                                    ),
                                  ).then((_) {
                                    // 返回时刷新列表
                                    _loadChatHistories();
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF29D6E9),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 40, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  elevation: 2,
                                ),
                                child: const Text(
                                  'Now Chat',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),

              // 底部空白区域，占用1份空间
              const Expanded(
                flex: 1,
                child: SizedBox(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
