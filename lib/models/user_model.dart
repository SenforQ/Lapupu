import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserModel {
  static const String _keyUsername = 'username';
  static const String _keyBio = 'bio';
  static const String _keyHasCustomAvatar = 'has_custom_avatar';
  static const String _keyAvatarPath = 'avatar_path';

  String username;
  String bio;
  bool hasCustomAvatar;
  String avatarPath;

  UserModel({
    required this.username,
    required this.bio,
    required this.hasCustomAvatar,
    required this.avatarPath,
  });

  // 生成随机用户名
  static String generateRandomUsername() {
    final random = Random();
    final number = random.nextInt(100000).toString().padLeft(5, '0');
    return 'Riize00$number';
  }

  // 从SharedPreferences加载用户数据
  static Future<UserModel> loadUser() async {
    final prefs = await SharedPreferences.getInstance();

    final username = prefs.getString(_keyUsername) ?? generateRandomUsername();
    final bio = prefs.getString(_keyBio) ?? 'No personal signature set yet';
    final hasCustomAvatar = prefs.getBool(_keyHasCustomAvatar) ?? false;
    final avatarPath = prefs.getString(_keyAvatarPath) ??
        'lib/assets/Photo/me_default_2025_6_13.png';

    return UserModel(
      username: username,
      bio: bio,
      hasCustomAvatar: hasCustomAvatar,
      avatarPath: avatarPath,
    );
  }

  // 保存用户数据到SharedPreferences
  Future<void> saveUser() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_keyUsername, username);
    await prefs.setString(_keyBio, bio);
    await prefs.setBool(_keyHasCustomAvatar, hasCustomAvatar);
    await prefs.setString(_keyAvatarPath, avatarPath);
  }

  // 更新用户名
  Future<void> updateUsername(String newUsername) async {
    username = newUsername;
    await saveUser();
  }

  // 更新个性签名
  Future<void> updateBio(String newBio) async {
    bio = newBio;
    await saveUser();
  }

  // 更新头像
  Future<void> updateAvatar(String newAvatarPath) async {
    avatarPath = newAvatarPath;
    hasCustomAvatar = true;
    await saveUser();
  }

  // 保存图片到沙盒目录
  static Future<String> saveImageToAppDirectory(File imageFile) async {
    try {
      // 获取应用文档目录
      final appDir = await getApplicationDocumentsDirectory();

      // 创建用户头像目录
      final avatarDir = Directory('${appDir.path}/avatars');
      if (!await avatarDir.exists()) {
        await avatarDir.create(recursive: true);
      }

      // 生成唯一文件名
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // 目标文件路径
      final targetPath = p.join(avatarDir.path, fileName);

      // 复制图片到目标路径
      final savedImage = await imageFile.copy(targetPath);

      // 返回相对路径
      return 'avatars/$fileName';
    } catch (e) {
      debugPrint('Error saving image: $e');
      return 'lib/assets/Photo/me_default_2025_6_13.png'; // 返回默认头像路径
    }
  }

  // 获取头像的完整路径
  static Future<String> getAvatarFullPath(String relativePath) async {
    // 如果是内置资源路径，直接返回
    if (relativePath.startsWith('lib/assets/')) {
      return relativePath;
    }

    // 获取应用文档目录
    final appDir = await getApplicationDocumentsDirectory();

    // 返回完整路径
    return p.join(appDir.path, relativePath);
  }
}
