import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import '../models/character_model.dart';
import '../models/user_model.dart';
import '../models/chat_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'report_page.dart';
import 'call_page.dart';

// 视频预览组件
class VideoPreview extends StatefulWidget {
  final String videoPath;
  final VoidCallback onTap;

  const VideoPreview({
    super.key,
    required this.videoPath,
    required this.onTap,
  });

  @override
  State<VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<VideoPreview> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  String? _thumbnailPath;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  Future<void> _initializeController() async {
    _controller = VideoPlayerController.asset(widget.videoPath);

    try {
      // 尝试初始化视频控制器
      await _controller.initialize();

      if (mounted) {
        setState(() {
          _initialized = true;
        });

        // 暂停视频并定位到第一帧
        _controller.pause();
        _controller.seekTo(Duration.zero);
      }
    } catch (e) {
      print('视频初始化错误: $e');

      // 如果初始化失败，尝试使用视频路径中的ID来获取对应的图片
      if (mounted) {
        final regex = RegExp(r'figure/(\d+)/v');
        final match = regex.firstMatch(widget.videoPath);

        if (match != null) {
          final characterId = match.group(1)!;
          final imagePath =
              'lib/assets/figure/$characterId/p/${characterId}_p_2025_06_13_1.png';

          setState(() {
            _thumbnailPath = imagePath;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _initialized
                // 如果视频初始化成功，显示视频的第一帧
                ? SizedBox(
                    width: 200,
                    height: 150,
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),
                  )
                // 如果有缩略图路径，显示图片
                : _thumbnailPath != null
                    ? Image.asset(
                        _thumbnailPath!,
                        width: 200,
                        height: 150,
                        fit: BoxFit.cover,
                      )
                    // 否则显示占位符
                    : Container(
                        width: 200,
                        height: 150,
                        color: Colors.black.withOpacity(0.1),
                        child: _buildVideoPlaceholder(),
                      ),
          ),
          // 播放按钮
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF29D6E9).withOpacity(0.9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library,
            color: Colors.white.withOpacity(0.7),
            size: 40,
          ),
          const SizedBox(height: 8),
          Text(
            'Loading...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class ChatDetailPage extends StatefulWidget {
  final Character character;

  const ChatDetailPage({super.key, required this.character});

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  late UserModel _currentUser;
  bool _isLoading = false;
  late ChatHistory _chatHistory;
  bool _isInitialized = false;
  // 视频缩略图缓存
  final Map<String, String> _videoThumbnails = {};
  // 防止重复发送消息
  bool _isProcessingRequest = false;
  bool _isBlocked = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  // 初始化聊天
  Future<void> _initializeChat() async {
    await _loadUserData();
    await _loadChatHistory();
    await _checkIfBlocked();

    // 如果没有聊天记录，添加初始欢迎消息
    if (_messages.isEmpty) {
      _addMessage(
        ChatMessage(
          text: widget.character.riizeSayHi,
          isMe: false,
          timestamp: DateTime.now(),
        ),
      );
    }

    setState(() {
      _isInitialized = true;
    });

    // 初始化完成后，滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  // 检查用户是否被拉黑
  Future<void> _checkIfBlocked() async {
    final prefs = await SharedPreferences.getInstance();
    final blockedUsers = prefs.getStringList('blocked_users') ?? [];

    setState(() {
      _isBlocked = blockedUsers.contains(widget.character.riizeUserId);
    });

    if (_isBlocked) {
      _showCenteredToast('This user is blocked. Chat is disabled.');
    }
  }

  // 滚动到底部的方法
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 加载用户数据
  Future<void> _loadUserData() async {
    _currentUser = await UserModel.loadUser();
  }

  // 加载聊天历史
  Future<void> _loadChatHistory() async {
    final history =
        await ChatHistory.loadChatHistory(widget.character.riizeUserId);

    if (history != null) {
      // 去除重复消息
      final uniqueMessages = <ChatMessage>[];
      final messageTexts = <String>{};

      for (final message in history.messages) {
        // 创建一个唯一标识符，包含文本和发送者信息
        final key = '${message.text}_${message.isMe}';

        // 如果这个消息还没有被添加过，则添加到列表中
        if (!messageTexts.contains(key)) {
          uniqueMessages.add(message);
          messageTexts.add(key);
        }
      }

      setState(() {
        _chatHistory = history;
        // 使用去重后的消息列表
        _messages = uniqueMessages;
        // 更新聊天历史中的消息列表
        _chatHistory.messages.clear();
        _chatHistory.messages.addAll(uniqueMessages);
        // 保存更新后的聊天历史
        _saveChatHistory();
      });
    } else {
      // 创建新的聊天历史
      _chatHistory = ChatHistory(
        characterId: widget.character.riizeUserId,
        messages: [],
      );
    }
  }

  // 保存聊天历史
  Future<void> _saveChatHistory() async {
    await ChatHistory.saveChatHistory(
        widget.character.riizeUserId, _chatHistory);
  }

  // 添加消息到列表
  void _addMessage(ChatMessage message) {
    // 检查是否有重复消息（相同文本、相同发送者，且时间接近的消息）
    final now = DateTime.now();
    final isDuplicate = _messages.any((m) =>
        m.text == message.text &&
        m.isMe == message.isMe &&
        now.difference(m.timestamp).inSeconds < 3);

    // 如果是重复消息，则不添加
    if (isDuplicate) return;

    setState(() {
      _messages.add(message);

      // 更新聊天历史
      _chatHistory.addMessage(message);
      _saveChatHistory();
    });

    // 滚动到底部
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollToBottom();
    });
  }

  // 显示屏幕中间的toast提示
  void _showCenteredToast(String message) {
    // 移除之前的toast
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    // 显示新的居中toast
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (BuildContext context) {
        // 2秒后自动关闭
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.of(context).pop();
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

  // 拉黑用户
  void _blockUser() async {
    // 这里可以实现拉黑用户的逻辑，例如将用户ID添加到拉黑列表中
    final prefs = await SharedPreferences.getInstance();
    final blockedUsers = prefs.getStringList('blocked_users') ?? [];

    if (!blockedUsers.contains(widget.character.riizeUserId)) {
      blockedUsers.add(widget.character.riizeUserId);
      await prefs.setStringList('blocked_users', blockedUsers);
    }

    // 更新状态
    setState(() {
      _isBlocked = true;
    });

    // 显示拉黑成功提示
    if (mounted) {
      _showCenteredToast('${widget.character.riizeUserName} has been blocked');
    }
  }

  // 发送消息
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // 如果用户被拉黑，则不允许发送消息
    if (_isBlocked) {
      _showCenteredToast('Cannot send messages to blocked users');
      return;
    }

    // 防止重复发送
    if (_isProcessingRequest || _isLoading) return;
    _isProcessingRequest = true;

    // 清空输入框
    _messageController.clear();

    // 添加用户消息
    final userMessage = ChatMessage(
      text: text,
      isMe: true,
      timestamp: DateTime.now(),
    );
    _addMessage(userMessage);

    // 显示加载状态
    setState(() {
      _isLoading = true;
    });

    try {
      // 调用智谱AI API
      final response = await _getAIResponse(text);

      // 添加AI回复
      final aiMessage = ChatMessage(
        text: response,
        isMe: false,
        timestamp: DateTime.now(),
      );
      _addMessage(aiMessage);
    } catch (e) {
      // 处理错误
      _showCenteredToast('Failed to get response: $e');
    } finally {
      // 隐藏加载状态
      setState(() {
        _isLoading = false;
        _isProcessingRequest = false; // 重置处理状态
      });
    }
  }

  // 调用智谱AI API
  Future<String> _getAIResponse(String message) async {
    const apiKey = 'f933f34d08fc436cb68c84d44ecd81fe.iwo77jzrwGU92JwX';
    const apiUrl = 'https://open.bigmodel.cn/api/paas/v4/chat/completions';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'glm-4-flash',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are ${widget.character.riizeUserName}, a fashion enthusiast. Respond in English as if you are this character. Keep responses brief and friendly. Your personality: ${widget.character.riizeIntroduction}'
            },
            {'role': 'user', 'content': message}
          ],
          'temperature': 0.7,
          'max_tokens': 800,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String;
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        return "Sorry, I couldn't process your message. Let's talk about something else!";
      }
    } catch (e) {
      print('Exception during API call: $e');
      return "I'm having trouble connecting right now. Let's chat later!";
    }
  }

  // 请求照片
  Future<void> _requestPhoto() async {
    // 如果正在处理请求，则不再处理
    if (_isProcessingRequest || _isLoading) return;
    _isProcessingRequest = true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Photo'),
        content: Text(
            'Do you want to request a photo from ${widget.character.riizeUserName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Request'),
          ),
        ],
      ),
    );

    if (result == true) {
      // 添加用户请求消息
      final userMessage = ChatMessage(
        text: "Can you share a photo with me?",
        isMe: true,
        timestamp: DateTime.now(),
      );
      _addMessage(userMessage);

      // 显示加载状态
      setState(() {
        _isLoading = true;
      });

      // 延迟1秒，模拟对方思考
      await Future.delayed(const Duration(seconds: 1));

      // 随机选择一张照片
      final photos = widget.character.riizeShowPhotoArray;
      final random = Random();
      final randomPhoto = photos[random.nextInt(photos.length)];

      // 添加角色回复消息（只包含照片，没有文字）
      final photoMessage = ChatMessage(
        text: "[PHOTO:$randomPhoto]",
        isMe: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _isLoading = false;
      });

      _addMessage(photoMessage);
    }

    // 处理完成
    _isProcessingRequest = false;
  }

  // 请求视频
  Future<void> _requestVideo() async {
    // 如果正在处理请求，则不再处理
    if (_isProcessingRequest || _isLoading) return;
    _isProcessingRequest = true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Video'),
        content: Text(
            'Do you want to request a video from ${widget.character.riizeUserName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Request'),
          ),
        ],
      ),
    );

    if (result == true) {
      // 添加用户请求消息
      final userMessage = ChatMessage(
        text: "Can you share a video with me?",
        isMe: true,
        timestamp: DateTime.now(),
      );
      _addMessage(userMessage);

      // 显示加载状态
      setState(() {
        _isLoading = true;
      });

      // 延迟1秒，模拟对方思考
      await Future.delayed(const Duration(seconds: 1));

      // 获取视频
      final video = widget.character.riizeShowVideo;

      // 添加角色回复消息（只包含视频，没有文字）
      final videoMessage = ChatMessage(
        text: "[VIDEO:$video]",
        isMe: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _isLoading = false;
      });

      _addMessage(videoMessage);
    }

    // 处理完成
    _isProcessingRequest = false;
  }

  // 查看照片
  void _viewPhoto(String photoPath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenPhotoPage(photoPath: photoPath),
      ),
    );
  }

  // 查看视频
  void _viewVideo(String videoPath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenVideoPage(videoPath: videoPath),
      ),
    );
  }

  // 显示底部操作菜单
  void _showActionSheet(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Options'),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _showReportPage();
            },
            child: const Text('Report'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _showBlockDialog();
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
  void _showReportPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportPage(character: widget.character),
      ),
    );
  }

  // 显示拉黑确认对话框
  void _showBlockDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Block User'),
          content: Text(
              'Are you sure you want to block ${widget.character.riizeUserName}?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _blockUser();
              },
              child: const Text('Block'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 确保在页面构建完成后滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: AssetImage(widget.character.riizeUserIcon),
            ),
            const SizedBox(width: 8),
            Text(
              widget.character.riizeUserName,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.more_vert,
              color: Colors.black,
            ),
            onPressed: () => _showActionSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // 消息列表
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageItem(message);
              },
            ),
          ),

          // 加载指示器
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF29D6E9),
                  ),
                ),
              ),
            ),

          // 请求照片/视频按钮区域
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // 请求照片按钮
                _buildRequestButton(
                  icon: Icons.photo,
                  label: 'Request Photo',
                  onTap: _requestPhoto,
                ),

                const SizedBox(width: 16),

                // 请求视频按钮
                _buildRequestButton(
                  icon: Icons.videocam,
                  label: 'Request Video',
                  onTap: _requestVideo,
                ),
              ],
            ),
          ),

          // 输入框区域
          _buildInputArea(),
        ],
      ),
    );
  }

  // 构建请求按钮
  Widget _buildRequestButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: const Color(0xFF29D6E9),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建输入区域
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, -1),
            blurRadius: 4,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // 输入框
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  enabled: !_isBlocked,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 通话按钮
            SizedBox(
              width: 40,
              height: 40,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Image.asset(
                  'lib/assets/Photo/chat_call_2025_6_18.png',
                  width: 40,
                  height: 40,
                ),
                onPressed: _isBlocked
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CallPage(character: widget.character),
                          ),
                        );
                      },
              ),
            ),
            const SizedBox(width: 8),
            // 发送按钮
            SizedBox(
              width: 40,
              height: 40,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF29D6E9),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: _isBlocked ? null : _sendMessage,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建消息气泡
  Widget _buildMessageItem(ChatMessage message) {
    final isMe = message.isMe;
    final text = message.text;

    // 检查是否只包含照片或视频
    final photoMatch = RegExp(r'\[PHOTO:(.*?)\]').firstMatch(text);
    final videoMatch = RegExp(r'\[VIDEO:(.*?)\]').firstMatch(text);

    // 检查是否只有媒体内容，没有文本
    final isOnlyMedia = (photoMatch != null && photoMatch.group(0) == text) ||
        (videoMatch != null && videoMatch.group(0) == text);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 发送者头像
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: AssetImage(widget.character.riizeUserIcon),
            ),
            const SizedBox(width: 8),
          ],

          // 消息气泡
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // 文本消息 (如果不是纯媒体消息)
                if (!isOnlyMedia)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? const Color(0xFF29D6E9) : Colors.grey[200],
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      photoMatch != null
                          ? text.replaceAll(photoMatch.group(0)!, '')
                          : videoMatch != null
                              ? text.replaceAll(videoMatch.group(0)!, '')
                              : text,
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                  ),

                // 照片预览
                if (photoMatch != null) ...[
                  if (!isOnlyMedia) const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _viewPhoto(photoMatch.group(1)!),
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: AssetImage(photoMatch.group(1)!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ],

                // 视频预览
                if (videoMatch != null) ...[
                  if (!isOnlyMedia) const SizedBox(height: 8),
                  VideoPreview(
                    videoPath: videoMatch.group(1)!,
                    onTap: () => _viewVideo(videoMatch.group(1)!),
                  ),
                ],
              ],
            ),
          ),

          // 用户头像
          if (isMe) ...[
            const SizedBox(width: 8),
            FutureBuilder<String>(
              future: UserModel.getAvatarFullPath(_currentUser.avatarPath),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey,
                  );
                }

                if (snapshot.hasError || !snapshot.hasData) {
                  return CircleAvatar(
                    radius: 16,
                    backgroundImage:
                        AssetImage('lib/assets/Photo/me_default_2025_6_13.png'),
                  );
                }

                if (_currentUser.avatarPath.startsWith('lib/assets/')) {
                  return CircleAvatar(
                    radius: 16,
                    backgroundImage: AssetImage(_currentUser.avatarPath),
                  );
                } else {
                  return CircleAvatar(
                    radius: 16,
                    backgroundImage: FileImage(File(snapshot.data!)),
                  );
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}

// 全屏照片页面
class FullScreenPhotoPage extends StatelessWidget {
  final String photoPath;

  const FullScreenPhotoPage({super.key, required this.photoPath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 3.0,
          child: Image.asset(
            photoPath,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

// 全屏视频页面
class FullScreenVideoPage extends StatefulWidget {
  final String videoPath;

  const FullScreenVideoPage({super.key, required this.videoPath});

  @override
  State<FullScreenVideoPage> createState() => _FullScreenVideoPageState();
}

class _FullScreenVideoPageState extends State<FullScreenVideoPage> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _videoPlayerController = VideoPlayerController.asset(widget.videoPath);

    await _videoPlayerController.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      looping: false,
      aspectRatio: _videoPlayerController.value.aspectRatio,
      errorBuilder: (context, errorMessage) {
        return Center(
          child: Text(
            errorMessage,
            style: const TextStyle(color: Colors.white),
          ),
        );
      },
    );

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Video',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chewieController != null
              ? Center(
                  child: Chewie(controller: _chewieController!),
                )
              : const Center(
                  child: Text(
                    'Error loading video',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
    );
  }
}
