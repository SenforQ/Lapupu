import 'package:flutter/material.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Terms of Service',
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
            '1. Acceptance of Terms\n'
            'By accessing and using the Riize app, you agree to be bound by these Terms of Service.\n\n'
            '2. Service Description\n'
            'Riize is a fashion sharing community platform that allows users to share and discover fashion content.\n\n'
            '3. User Content\n'
            'You retain ownership of your content but grant Riize a license to use, modify, and display it.\n\n'
            '4. Prohibited Content\n'
            'Users may not post content that is illegal, harmful, threatening, abusive, or infringing on others\' rights.\n\n'
            '5. Intellectual Property Rights\n'
            'All content and materials available through Riize are protected by intellectual property laws.\n\n'
            '6. User Conduct\n'
            'Users must comply with all applicable laws and respect other users\' rights while using Riize.\n\n'
            '7. Privacy\n'
            'Your use of Riize is also governed by our Privacy Policy.\n\n'
            '8. Modifications to Service\n'
            'We reserve the right to modify or discontinue Riize at any time without notice.\n\n'
            '9. Limitation of Liability\n'
            'Riize is not liable for any indirect, incidental, or consequential damages.\n\n'
            '10. Third-Party Links\n'
            'Riize may contain links to third-party websites that we do not control or maintain.\n\n'
            '11. Copyright Policy\n'
            'We respect intellectual property rights and will respond to notices of alleged copyright infringement.\n\n'
            '12. Indemnification\n'
            'You agree to indemnify Riize against any claims arising from your use of the service.\n\n'
            '13. Governing Law\n'
            'These terms are governed by the laws of the jurisdiction where Riize operates.\n\n'
            '14. Changes to Terms\n'
            'We may update these terms at any time, and continued use constitutes acceptance of changes.\n\n'
            '15. Contact Information\n'
            'For questions about these terms, please contact our support team.\n',
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
