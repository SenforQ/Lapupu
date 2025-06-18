import 'dart:io';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'terms_page.dart';
import 'privacy_page.dart';
import 'about_page.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<UserModel> _userFuture;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    setState(() {
      _userFuture = UserModel.loadUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<UserModel>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final user = snapshot.data!;

          return CustomScrollView(
            slivers: [
              // 顶部背景和用户信息
              SliverToBoxAdapter(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 顶部背景图
                    Image.asset(
                      'lib/assets/Photo/me_top_bg_2025_6_13.png',
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),

                    // 编辑按钮
                    Positioned(
                      top: 50,
                      right: 20,
                      child: GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProfilePage(user: user),
                            ),
                          );

                          if (result == true) {
                            _loadUserData(); // 刷新数据
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Editor',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 用户信息卡片
                    Positioned(
                      bottom: -60,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Column(
                          children: [
                            // 头像
                            _buildAvatarImage(user),

                            const SizedBox(height: 16),

                            // 用户名
                            Text(
                              user.username,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),

                            const SizedBox(height: 8),

                            // 个性签名
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                user.bio,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 空白间隔
              const SliverToBoxAdapter(child: SizedBox(height: 80)),

              // 列表项
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // User Contract
                    _buildListItem(
                      icon: 'lib/assets/Photo/me_user_2025_6_13.png',
                      title: 'User Contract',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const TermsPage()),
                        );
                      },
                    ),

                    const Divider(
                        height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

                    // Privacy Policy
                    _buildListItem(
                      icon: 'lib/assets/Photo/me_privacy_2025_6_13.png',
                      title: 'Privacy Policy',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const PrivacyPage()),
                        );
                      },
                    ),

                    const Divider(
                        height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

                    // About us
                    _buildListItem(
                      icon: 'lib/assets/Photo/me_about_2025_6_13.png',
                      title: 'About us',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AboutPage()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAvatarImage(UserModel user) {
    if (user.avatarPath.startsWith('lib/assets/')) {
      return CircleAvatar(
        radius: 50,
        backgroundImage: AssetImage(user.avatarPath),
      );
    } else {
      // 显示沙盒中的图片
      return FutureBuilder<String>(
        future: UserModel.getAvatarFullPath(user.avatarPath),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircleAvatar(
              radius: 50,
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return CircleAvatar(
              radius: 50,
              backgroundImage:
                  AssetImage('lib/assets/Photo/me_default_2025_6_13.png'),
            );
          }

          return CircleAvatar(
            radius: 50,
            backgroundImage: FileImage(File(snapshot.data!)),
          );
        },
      );
    }
  }

  Widget _buildListItem({
    required String icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        color: Colors.white,
        child: Row(
          children: [
            const SizedBox(width: 20),

            // 图标
            Image.asset(
              icon,
              width: 24,
              height: 24,
            ),

            const SizedBox(width: 16),

            // 标题
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),

            const Spacer(),

            // 箭头
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),

            const SizedBox(width: 20),
          ],
        ),
      ),
    );
  }
}
