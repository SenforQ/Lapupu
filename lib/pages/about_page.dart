import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'About us',
          style: TextStyle(
            color: Colors.black,
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          // Logo
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircleAvatar(
                radius: 50,
                backgroundImage:
                    AssetImage('lib/assets/Photo/logo_2025_6_18.png'),
              ),
            ),
          ),

          // App Name
          Center(
            child: Text(
              'Lapupu',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),

          // Version
          Center(
            child: Padding(
              padding: EdgeInsets.only(top: 8, bottom: 32),
              child: Text(
                'Version 1.0.0',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ),
          ),

          // Description
          Text(
            'Riize is a fashion sharing community platform where users can discover and share the latest fashion trends, outfits, and styles.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Color(0xFF333333),
            ),
          ),

          SizedBox(height: 32),

          // Contact Info
          Text(
            'Contact Us',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          SizedBox(height: 16),

          Text(
            'Email: support@riize.com',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Color(0xFF333333),
            ),
          ),

          SizedBox(height: 32),

          // Copyright
          Text(
            '© 2025 Riize. All rights reserved.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
