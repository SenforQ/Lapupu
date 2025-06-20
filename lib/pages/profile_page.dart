import 'dart:io';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'terms_page.dart';
import 'privacy_page.dart';
import 'about_page.dart';
import 'edit_profile_page.dart';
import 'ai_outfit_assistant_page.dart';
import 'vip_page.dart';
import 'wallet_page.dart';

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

              // VIP Club 入口
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: _buildVipClubWidget(),
                ),
              ),

              // 列表项间隔
              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // 列表项
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // AI Outfit Assistant - 放在第一位
                    _buildListItem(
                      icon: 'lib/assets/Photo/rob_2025_6_19.png',
                      title: 'AI Outfit Assistant',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AiOutfitAssistantPage(),
                          ),
                        );
                      },
                    ),

                    const Divider(
                        height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

                    // Wallet - 新增
                    _buildListItem(
                      icon: 'lib/assets/Photo/me_wallet_2025_6_19.png',
                      title: 'Wallet',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const WalletPage(),
                          ),
                        );
                      },
                    ),

                    const Divider(
                        height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

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

  Widget _buildVipClubWidget() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const VipPage(),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: MediaQuery.of(context).size.width - 30,
          child: Stack(
            children: [
              // 背景图片，使用Image.asset以保持原始宽高比
              Image.asset(
                'lib/assets/Photo/me_vip_club_2025_6_19.png',
                width: MediaQuery.of(context).size.width - 30,
                fit: BoxFit.fitWidth,
              ),

              // Join按钮
              Positioned(
                right: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const VipPage(),
                        ),
                      );
                    },
                    child: Image.asset(
                      'lib/assets/Photo/me_vip_join_2025_6_19.png',
                      width: 82,
                      height: 32,
                      fit: BoxFit.contain,
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
