import 'package:flutter/material.dart';
import '../models/character_model.dart';

class ReportPage extends StatefulWidget {
  final Character character;

  const ReportPage({super.key, required this.character});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final List<String> _reportReasons = [
    'Inappropriate content',
    'Harassment or bullying',
    'Spam or scam',
    'Impersonation',
    'False information',
    'Hate speech',
    'Other'
  ];

  String? _selectedReason;
  final TextEditingController _detailsController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  void _submitReport() async {
    if (_selectedReason == null) {
      _showCenteredToast('Please select a reason for reporting');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // 模拟提交报告的网络请求
    await Future.delayed(const Duration(seconds: 1));

    // 提交成功后返回上一页
    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });

      _showCenteredToast('Report submitted successfully');

      // 延迟一下再返回，让用户看到提示
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    }
  }

  // 显示屏幕中间的toast提示
  void _showCenteredToast(String message) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (BuildContext context) {
        // 2秒后自动关闭
        Future.delayed(const Duration(seconds: 2), () {
          if (Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }
        });

        return AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.7),
          content: Text(
            message,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Report',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Why are you reporting this user?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // 举报原因列表
            ...List.generate(
              _reportReasons.length,
              (index) => RadioListTile<String>(
                title: Text(_reportReasons[index]),
                value: _reportReasons[index],
                groupValue: _selectedReason,
                onChanged: (value) {
                  setState(() {
                    _selectedReason = value;
                  });
                },
                activeColor: const Color(0xFF29D6E9),
              ),
            ),

            const SizedBox(height: 16),
            const Text(
              'Additional details (optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // 额外细节输入框
            TextField(
              controller: _detailsController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Please provide any additional information',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF29D6E9),
                    width: 2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // 提交按钮
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF29D6E9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Submit',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
