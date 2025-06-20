import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'vip_page.dart';

class EditProfilePage extends StatefulWidget {
  final UserModel user;

  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  late String _avatarPath;
  bool _isEdited = false;
  bool _isUsingAssetImage = true;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user.username);
    _bioController = TextEditingController(text: widget.user.bio);
    _avatarPath = widget.user.avatarPath;
    _isUsingAssetImage = _avatarPath.startsWith('lib/assets/');

    // 监听文本变化
    _usernameController.addListener(_checkEdited);
    _bioController.addListener(_checkEdited);
  }

  void _checkEdited() {
    final isEdited = _usernameController.text != widget.user.username ||
        _bioController.text != widget.user.bio ||
        _avatarPath != widget.user.avatarPath ||
        _imageFile != null;

    if (isEdited != _isEdited) {
      setState(() {
        _isEdited = isEdited;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<bool> _checkVipStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final vipExpiry = prefs.getInt('vip_expiry_timestamp') ?? 0;
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    return vipExpiry > currentTime;
  }

  Future<void> _showVipRequiredDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'VIP Required',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'This feature is only available for VIP members. Please upgrade to VIP to edit your profile.',
            style: TextStyle(fontSize: 16),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4ECDC4),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Go',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VipPage(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveChanges() async {
    // 检查VIP状态
    final isVip = await _checkVipStatus();

    if (!isVip) {
      // 如果不是VIP，显示提示对话框
      await _showVipRequiredDialog();
      return;
    }

    // VIP用户可以保存数据
    // 更新用户数据
    widget.user.username = _usernameController.text;
    widget.user.bio = _bioController.text;

    // 如果选择了新图片，保存到沙盒目录
    if (_imageFile != null) {
      final savedPath = await UserModel.saveImageToAppDirectory(_imageFile!);
      await widget.user.updateAvatar(savedPath);
    } else if (_avatarPath != widget.user.avatarPath) {
      await widget.user.updateAvatar(_avatarPath);
    } else {
      await widget.user.saveUser();
    }

    if (mounted) {
      // 显示保存成功提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile saved successfully!'),
          backgroundColor: Color(0xFF4ECDC4),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context, true);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _isUsingAssetImage = false;
          _isEdited = true;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _selectAvatar() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Use Default Avatar'),
              onTap: () {
                setState(() {
                  _avatarPath = 'lib/assets/Photo/me_default_2025_6_13.png';
                  _imageFile = null;
                  _isUsingAssetImage = true;
                  _isEdited = true;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_album),
              title: const Text('Use Alternative Avatar'),
              onTap: () {
                setState(() {
                  _avatarPath = 'lib/assets/Photo/me_n_2025_6_13.png';
                  _imageFile = null;
                  _isUsingAssetImage = true;
                  _isEdited = true;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 头像编辑
            GestureDetector(
              onTap: _selectAvatar,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  _buildAvatarImage(),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 用户名编辑
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Username',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    hintText: 'Enter your username',
                    border: UnderlineInputBorder(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 个性签名编辑
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bio',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: _bioController,
                    decoration: const InputDecoration(
                      hintText: 'Enter your bio',
                      contentPadding: EdgeInsets.all(12),
                      border: InputBorder.none,
                    ),
                    maxLines: 3,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _isEdited ? _saveChanges : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isEdited ? const Color(0xFF35D1E3) : Colors.grey,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
            ),
          ),
          child: const Text(
            'Save',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarImage() {
    if (_imageFile != null) {
      return CircleAvatar(
        radius: 50,
        backgroundImage: FileImage(_imageFile!),
      );
    } else if (_isUsingAssetImage) {
      return CircleAvatar(
        radius: 50,
        backgroundImage: AssetImage(_avatarPath),
      );
    } else {
      // 显示沙盒中的图片
      return FutureBuilder<String>(
        future: UserModel.getAvatarFullPath(_avatarPath),
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
}
