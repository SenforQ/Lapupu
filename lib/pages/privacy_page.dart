import 'package:flutter/material.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
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
          Text(
            '1. Information Collection\n'
            'We collect information you provide directly to us and automatically when you use Riize.\n\n'
            '2. Use of Information\n'
            'We use collected information to provide, maintain, and improve our services.\n\n'
            '3. Information Sharing\n'
            'We do not share your personal information except in limited circumstances.\n\n'
            '4. Data Security\n'
            'We implement reasonable security measures to protect your information.\n\n'
            '5. Cookies and Similar Technologies\n'
            'We use cookies and similar technologies to collect usage information.\n\n'
            '6. Third-Party Services\n'
            'Our service may contain links to third-party websites and services.\n\n'
            '7. Children\'s Privacy\n'
            'Our service is not directed to children under 13 years of age.\n\n'
            '8. International Data Transfers\n'
            'Your information may be transferred to and processed in different countries.\n\n'
            '9. Data Retention\n'
            'We retain information for as long as necessary to provide our services.\n\n'
            '10. Your Rights\n'
            'You have rights regarding your personal information, including access and correction.\n\n'
            '11. Marketing Communications\n'
            'You can opt out of receiving promotional communications from us.\n\n'
            '12. Updates to Privacy Policy\n'
            'We may update this policy and will notify you of significant changes.\n\n'
            '13. Compliance with Laws\n'
            'We comply with applicable data protection laws and regulations.\n\n'
            '14. Contact Us\n'
            'Contact our privacy team with questions about this policy.\n\n'
            '15. Consent\n'
            'By using Riize, you consent to our collection and use of information as described.\n',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF333333),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
