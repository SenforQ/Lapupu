import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_model.dart';
import 'wallet_page.dart';

class AiOutfitAssistantPage extends StatefulWidget {
  const AiOutfitAssistantPage({super.key});

  @override
  State<AiOutfitAssistantPage> createState() => _AiOutfitAssistantPageState();
}

class _AiOutfitAssistantPageState extends State<AiOutfitAssistantPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  int _currentCoins = 0;

  static const String _assistantName = 'AI Outfit Assistant';
  static const String _assistantAvatar =
      'lib/assets/Photo/rot_icon_2025_6_19.png';
  static const String _headerBg =
      'lib/assets/Photo/rot_headericon_2025_6_19.png';
  static const String _chatBg = 'lib/assets/Photo/chat_bg_2025_6_18.png';
  static const String _historyKey = 'ai_outfit_assistant_history';
  static const String _noMoreRemindKey = 'ai_no_more_remind';
  static const String kGoldBalanceKey = 'gold_coins_balance';
  static const int _costPerQuery = 2;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
    _loadCoinsBalance();
  }

  Future<void> _loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyJson = prefs.getString(_historyKey);
    if (historyJson != null) {
      try {
        final List<dynamic> list = jsonDecode(historyJson);
        _messages = list.map((e) => ChatMessage.fromJson(e)).toList();
      } catch (e) {
        _messages = [];
      }
    }
    if (_messages.isEmpty) {
      _addMessage(
        ChatMessage(
          text:
              'Hello! I\'m AI Outfit Assistant, I can provide you with fashion styling advice. Feel free to ask me anything!',
          isMe: false,
          timestamp: DateTime.now(),
        ),
      );
    }
    setState(() {
      _isInitialized = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _saveChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String historyJson =
        jsonEncode(_messages.map((e) => e.toJson()).toList());
    await prefs.setString(_historyKey, historyJson);
  }

  Future<void> _loadCoinsBalance() async {
    final prefs = await SharedPreferences.getInstance();
    int balance = prefs.getInt(kGoldBalanceKey) ?? -1;

    // 如果是新用户（余额为-1），给予100金币
    if (balance == -1) {
      balance = 100;
      await prefs.setInt(kGoldBalanceKey, balance);
      print('New user detected, granted 100 coins');
    }

    setState(() {
      _currentCoins = balance;
    });
  }

  Future<void> _updateCoinsBalance(int newBalance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(kGoldBalanceKey, newBalance);
    setState(() {
      _currentCoins = newBalance;
    });
  }

  Future<bool> _checkAndConsumeCoins() async {
    if (_currentCoins < _costPerQuery) {
      _showInsufficientCoinsDialog();
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final bool noMoreRemind = prefs.getBool(_noMoreRemindKey) ?? false;

    if (!noMoreRemind) {
      return await _showCoinsConfirmDialog();
    } else {
      // 直接消耗金币
      final newBalance = _currentCoins - _costPerQuery;
      await _updateCoinsBalance(newBalance);
      return true;
    }
  }

  Future<bool> _showCoinsConfirmDialog() async {
    bool? result = await showDialog<bool>(
      context: context,
      builder: (context) {
        bool dontRemindAgain = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.monetization_on,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Coins Required',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4B2B3A),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Balance: $_currentCoins coins',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4B2B3A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This query will cost $_costPerQuery coins',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: dontRemindAgain,
                        onChanged: (value) {
                          setState(() {
                            dontRemindAgain = value ?? false;
                          });
                        },
                        activeColor: const Color(0xFFDB64A5),
                      ),
                      const Expanded(
                        child: Text(
                          'Don\'t remind me again',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 16,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    if (dontRemindAgain) {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool(_noMoreRemindKey, true);
                    }
                    Navigator.of(context).pop(true);
                  },
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      color: Color(0xFFDB64A5),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            );
          },
        );
      },
    );

    if (result == true) {
      final newBalance = _currentCoins - _costPerQuery;
      await _updateCoinsBalance(newBalance);
      return true;
    }
    return false;
  }

  void _showInsufficientCoinsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.warning,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Insufficient Coins',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4B2B3A),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Balance: $_currentCoins coins',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4B2B3A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You need $_costPerQuery coins to ask AI Outfit Assistant.',
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please go to Wallet to purchase more coins.',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFFDB64A5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Later',
              style: TextStyle(
                color: Color(0xFF666666),
                fontSize: 16,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WalletPage()),
              ).then((_) => _loadCoinsBalance()); // 重新加载余额
            },
            child: const Text(
              'Go to Wallet',
              style: TextStyle(
                color: Color(0xFFDB64A5),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });
    _saveChatHistory();
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

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

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    if (_isLoading) return;

    // 检查和消耗金币
    final canProceed = await _checkAndConsumeCoins();
    if (!canProceed) return;

    _messageController.clear();
    final userMessage = ChatMessage(
      text: text,
      isMe: true,
      timestamp: DateTime.now(),
    );
    _addMessage(userMessage);
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await _getAIResponse(text);
      final aiMessage = ChatMessage(
        text: response,
        isMe: false,
        timestamp: DateTime.now(),
      );
      _addMessage(aiMessage);
    } catch (e) {
      _addMessage(ChatMessage(
        text:
            'Sorry, AI assistant is temporarily unavailable, please try again later.',
        isMe: false,
        timestamp: DateTime.now(),
      ));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

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
                  'You are AI Outfit Assistant, a professional fashion styling consultant. Please respond in English with concise, friendly, and professional tone to users\' outfit-related questions. Do not output images, videos, or emojis, text only.',
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
        return 'AI assistant is temporarily unavailable, please try again later.';
      }
    } catch (e) {
      return 'AI assistant is temporarily unavailable, please try again later.';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: AssetImage(_assistantAvatar),
            ),
            const SizedBox(width: 8),
            Text(
              _assistantName,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          // 显示金币余额
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.monetization_on,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '$_currentCoins',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 聊天背景遮罩
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(_chatBg),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.white.withOpacity(0.7),
                    BlendMode.lighten,
                  ),
                ),
              ),
            ),
          ),
          // 聊天内容
          Column(
            children: [
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return _buildMessageItem(message);
                  },
                ),
              ),
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
              _buildInputArea(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(ChatMessage message) {
    final isMe = message.isMe;
    final text = message.text;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: AssetImage(_assistantAvatar),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF29D6E9) : Colors.grey[200],
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.person, color: Colors.white, size: 18),
            ),
          ],
        ],
      ),
    );
  }

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
                    hintText: 'Ask me about fashion styling...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                  enabled: !_isLoading,
                ),
              ),
            ),
            const SizedBox(width: 8),
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
                  onPressed: _isLoading ? null : _sendMessage,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
