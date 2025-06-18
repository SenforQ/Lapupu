import 'package:flutter/material.dart';
import 'pages/welcome_page.dart';
import 'package:just_audio_background/just_audio_background.dart';

Future<void> main() async {
  // 确保Flutter绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化后台音频服务
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.example.riize.channel.audio',
    androidNotificationChannelName: 'Riize Audio',
    androidNotificationOngoing: true,
    androidStopForegroundOnPause: true,
    androidNotificationIcon: 'drawable/ic_launcher', // 使用应用图标作为通知图标
    notificationColor: const Color(0xFF2196f3),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Riize',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.white,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const WelcomePage(),
    );
  }
}
