import 'package:flutter/material.dart';
import 'home_page.dart';
import 'like_page.dart';
import 'message_page.dart';
import 'clothing_page.dart';
import 'profile_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const LikePage(),
    const ClothingPage(),
    const MessagePage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          items: [
            BottomNavigationBarItem(
              icon: Image.asset(
                'lib/assets/Photo/home_n_2025_6_13.png',
                width: 24,
                height: 24,
              ),
              activeIcon: Image.asset(
                'lib/assets/Photo/home_s_2025_6_13.png',
                width: 24,
                height: 24,
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                'lib/assets/Photo/like_n_2025_6_13.png',
                width: 24,
                height: 24,
              ),
              activeIcon: Image.asset(
                'lib/assets/Photo/like_s_2025_6_13.png',
                width: 24,
                height: 24,
              ),
              label: 'Like',
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                'lib/assets/Photo/clothing_n_2025_6_13.png',
                width: 24,
                height: 24,
              ),
              activeIcon: Image.asset(
                'lib/assets/Photo/clothing_s_2025_6_13.png',
                width: 24,
                height: 24,
              ),
              label: 'Clothing',
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                'lib/assets/Photo/message_n_2025_6_13.png',
                width: 24,
                height: 24,
              ),
              activeIcon: Image.asset(
                'lib/assets/Photo/message_s_2025_6_13.png',
                width: 24,
                height: 24,
              ),
              label: 'Message',
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                'lib/assets/Photo/me_n_2025_6_13.png',
                width: 24,
                height: 24,
              ),
              activeIcon: Image.asset(
                'lib/assets/Photo/me_s_2025_6_13.png',
                width: 24,
                height: 24,
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
