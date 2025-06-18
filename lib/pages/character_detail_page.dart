import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/character_model.dart';
import 'chat_detail_page.dart';
import 'report_page.dart';

class CharacterDetailPage extends StatefulWidget {
  final Character character;

  const CharacterDetailPage({super.key, required this.character});

  @override
  State<CharacterDetailPage> createState() => _CharacterDetailPageState();
}

class _CharacterDetailPageState extends State<CharacterDetailPage> {
  late String headerImage;
  bool _isBlocked = false;

  @override
  void initState() {
    super.initState();
    // 从角色的riizeShowPhotoArray中随机选择一张图片作为顶部图片
    final random = Random(DateTime.now().millisecondsSinceEpoch);
    final photos = widget.character.riizeShowPhotoArray;
    headerImage = photos[random.nextInt(photos.length)];

    // 检查用户是否已被拉黑
    _checkIfBlocked();
  }

  // 检查用户是否已被拉黑
  Future<void> _checkIfBlocked() async {
    final prefs = await SharedPreferences.getInstance();
    final blockedUsers = prefs.getStringList('blocked_users') ?? [];

    setState(() {
      _isBlocked = blockedUsers.contains(widget.character.riizeUserId);
    });

    if (_isBlocked) {
      _showCenteredToast('This user is blocked');
    }
  }

  // 显示底部操作菜单
  void _showActionSheet() {
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

  // 拉黑用户
  void _blockUser() async {
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

  // 跳转到聊天详情页
  void _navigateToChatDetail() {
    if (_isBlocked) {
      _showCenteredToast('Cannot chat with blocked users');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailPage(character: widget.character),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          // 顶部图片
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              width: screenWidth,
              height: 260,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(headerImage),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // 返回按钮
          Positioned(
            top: statusBarHeight + 10,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),

          // 右上角举报按钮
          Positioned(
            top: statusBarHeight + 10,
            right: 16 + 40 + 8, // 状态栏 + 间距 + 消息按钮宽度 + 按钮间距
            child: GestureDetector(
              onTap: _showActionSheet,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),

          // 右上角消息按钮
          Positioned(
            top: statusBarHeight + 10,
            right: 16,
            child: GestureDetector(
              onTap: _navigateToChatDetail,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isBlocked
                      ? Colors.grey.withOpacity(0.3)
                      : Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.message,
                  color: _isBlocked ? Colors.grey[400] : Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),

          // 用户头像 - 位于顶部图片底部-40的位置，左边距20
          Positioned(
            top: 260 - 40, // 顶部图片高度 - 40
            left: 20,
            child: Container(
              width: 60,
              height: 60,
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
          ),

          // 用户信息内容
          Positioned(
            top: 260 + 30, // 顶部图片高度 + 间距
            left: 0,
            right: 0,
            bottom: 0,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 用户名
                  Text(
                    widget.character.riizeUserName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 用户昵称
                  Text(
                    widget.character.riizeNickName,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF666666),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 用户介绍
                  Text(
                    widget.character.riizeIntroduction,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 粉丝数
                  Row(
                    children: [
                      const Icon(
                        Icons.people,
                        size: 18,
                        color: Color(0xFF999999),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.character.riizeFansCount} followers',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF999999),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // 图片标题
                  const Text(
                    'Photos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 图片网格
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: widget.character.riizeShowPhotoArray.length,
                    itemBuilder: (context, index) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          widget.character.riizeShowPhotoArray[index],
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
