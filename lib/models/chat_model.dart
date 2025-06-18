import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ChatMessage {
  final String text;
  final bool isMe;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isMe,
    required this.timestamp,
  });

  // 将消息转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isMe': isMe,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  // 从JSON创建消息
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'],
      isMe: json['isMe'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
    );
  }
}

class ChatHistory {
  // 角色ID
  final String characterId;
  // 消息列表
  final List<ChatMessage> messages;
  // 最后一条消息
  ChatMessage? lastMessage;
  // 最后更新时间
  DateTime? lastUpdated;

  ChatHistory({
    required this.characterId,
    required this.messages,
    this.lastMessage,
    this.lastUpdated,
  });

  // 添加消息
  void addMessage(ChatMessage message) {
    messages.add(message);
    lastMessage = message;
    lastUpdated = DateTime.now();
  }

  // 将聊天历史转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'characterId': characterId,
      'messages': messages.map((message) => message.toJson()).toList(),
      'lastMessage': lastMessage?.toJson(),
      'lastUpdated': lastUpdated?.millisecondsSinceEpoch,
    };
  }

  // 从JSON创建聊天历史
  factory ChatHistory.fromJson(Map<String, dynamic> json) {
    final List<dynamic> messagesJson = json['messages'];
    final List<ChatMessage> messages = messagesJson
        .map((messageJson) => ChatMessage.fromJson(messageJson))
        .toList();

    return ChatHistory(
      characterId: json['characterId'],
      messages: messages,
      lastMessage: json['lastMessage'] != null
          ? ChatMessage.fromJson(json['lastMessage'])
          : null,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastUpdated'])
          : null,
    );
  }

  // 保存聊天历史
  static Future<void> saveChatHistory(
      String characterId, ChatHistory history) async {
    final prefs = await SharedPreferences.getInstance();
    final String historyJson = jsonEncode(history.toJson());
    await prefs.setString('chat_history_$characterId', historyJson);

    // 保存聊天历史列表
    final List<String> chatHistoryIds =
        prefs.getStringList('chat_history_ids') ?? [];
    if (!chatHistoryIds.contains(characterId)) {
      chatHistoryIds.add(characterId);
      await prefs.setStringList('chat_history_ids', chatHistoryIds);
    }
  }

  // 加载聊天历史
  static Future<ChatHistory?> loadChatHistory(String characterId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyJson = prefs.getString('chat_history_$characterId');

    if (historyJson == null) {
      return null;
    }

    try {
      final Map<String, dynamic> historyMap = jsonDecode(historyJson);
      return ChatHistory.fromJson(historyMap);
    } catch (e) {
      print('Error loading chat history: $e');
      return null;
    }
  }

  // 获取所有聊天历史ID
  static Future<List<String>> getAllChatHistoryIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('chat_history_ids') ?? [];
  }

  // 获取所有聊天历史
  static Future<Map<String, ChatHistory>> getAllChatHistories() async {
    final Map<String, ChatHistory> result = {};
    final List<String> ids = await getAllChatHistoryIds();

    for (final id in ids) {
      final history = await loadChatHistory(id);
      if (history != null) {
        result[id] = history;
      }
    }

    return result;
  }
}
