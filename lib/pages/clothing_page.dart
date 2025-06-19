import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ClothingPage extends StatefulWidget {
  const ClothingPage({super.key});

  @override
  State<ClothingPage> createState() => _ClothingPageState();
}

class _ClothingPageState extends State<ClothingPage> {
  List<OutfitGroup> outfitGroups = [];

  @override
  void initState() {
    super.initState();
    _loadOutfitGroups();
  }

  Future<void> _loadOutfitGroups() async {
    final groups = await OutfitGroup.loadAll();
    setState(() {
      outfitGroups = groups;
    });
  }

  Future<void> _addNewOutfit() async {
    final List<String>? newImages = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const OutfitCreatePage()),
    );
    if (newImages != null && newImages.isNotEmpty) {
      // 只取前5张，补空
      final List<String> groupImages =
          List.generate(5, (i) => i < newImages.length ? newImages[i] : '');
      final newGroup = OutfitGroup(groupImages);
      setState(() {
        outfitGroups.add(newGroup);
      });
      await OutfitGroup.saveAll(outfitGroups);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double itemWidth =
        (MediaQuery.of(context).size.width - 30 - 12) / 2.0;
    const double itemHeight = 265;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          // 顶部渐变背景图片
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'lib/assets/Photo/message_top_bg_2025_6_17.png',
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // 顶部标题
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: const Text(
                    'Clothing',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // 内容区域
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: GridView.builder(
                      padding: const EdgeInsets.only(top: 0, bottom: 16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: itemWidth / itemHeight,
                      ),
                      itemCount: 1 + outfitGroups.length, // 第一个为加号
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          // 加号item
                          return GestureDetector(
                            onTap: _addNewOutfit,
                            child: Container(
                              width: itemWidth,
                              height: itemHeight,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.add,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ),
                          );
                        } else {
                          // 新增数据item，左2右3自适应布局，显示图片
                          final group = outfitGroups[index - 1];
                          return _buildOutfitItem(itemWidth, itemHeight, group);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutfitItem(
      double itemWidth, double itemHeight, OutfitGroup outfitGroup) {
    return Container(
      width: itemWidth,
      height: itemHeight,
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 12,
            spreadRadius: 1,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // 左2
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 10, top: 10, bottom: 10),
              child: Column(
                children: [
                  Expanded(child: _buildGridImage(outfitGroup.imagePaths[0])),
                  SizedBox(height: 9),
                  Expanded(child: _buildGridImage(outfitGroup.imagePaths[1])),
                ],
              ),
            ),
          ),
          // 右3
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                  right: 10, top: 10, bottom: 10, left: 9),
              child: Column(
                children: [
                  Expanded(child: _buildGridImage(outfitGroup.imagePaths[2])),
                  SizedBox(height: 9),
                  Expanded(child: _buildGridImage(outfitGroup.imagePaths[3])),
                  SizedBox(height: 9),
                  Expanded(child: _buildGridImage(outfitGroup.imagePaths[4])),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridImage(String fileName) {
    return FutureBuilder<Directory>(
      future: getApplicationDocumentsDirectory(),
      builder: (context, snapshot) {
        final borderRadius = BorderRadius.circular(16);
        Widget child;
        if (fileName.isNotEmpty && snapshot.hasData) {
          final dir = snapshot.data!;
          final fullPath = '${dir.path}/$fileName';
          child = GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => Dialog(
                  backgroundColor: Colors.transparent,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: borderRadius,
                        color: Colors.black,
                      ),
                      child: Image.file(File(fullPath), fit: BoxFit.contain),
                    ),
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: borderRadius,
              child: Image.file(
                File(fullPath),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.black38,
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
          );
        } else {
          // 更深的灰色+边框
          child = Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              border: Border.all(color: Colors.grey, width: 1.2),
              borderRadius: borderRadius,
            ),
          );
        }
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: borderRadius,
          ),
          child: ClipRRect(
            borderRadius: borderRadius,
            child: child,
          ),
        );
      },
    );
  }
}

// 新建穿搭页面
class OutfitCreatePage extends StatefulWidget {
  const OutfitCreatePage({super.key});

  @override
  State<OutfitCreatePage> createState() => _OutfitCreatePageState();
}

class _OutfitCreatePageState extends State<OutfitCreatePage> {
  final List<File> _images = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _images.add(File(pickedFile.path));
      });
    }
  }

  Future<void> _saveImagesToSandbox() async {
    if (_images.isEmpty) return;
    final dir = await getApplicationDocumentsDirectory();
    List<String> savedNames = [];
    for (final file in _images) {
      final String fileName = DateTime.now().millisecondsSinceEpoch.toString() +
          '_' +
          file.path.split('/').last;
      final String newPath = '${dir.path}/$fileName';
      await file.copy(newPath);
      savedNames.add(fileName); // 只存文件名
    }
    if (mounted) {
      Navigator.pop(context, savedNames);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double topPadding = MediaQuery.of(context).padding.top + 20;
    final double topMargin = topPadding + 50;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          // 顶部渐变背景图片
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'lib/assets/Photo/message_top_bg_2025_6_17.png',
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          // 主体内容
          SafeArea(
            top: true,
            child: Column(
              children: [
                // 上半部分透明背景，内容下移
                Container(
                  width: screenWidth,
                  height: 420 + topMargin,
                  color: Colors.transparent,
                  child: Center(
                    child: Container(
                      margin: EdgeInsets.only(top: topMargin),
                      width: 309,
                      height: 420,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: _OutfitInnerDemo(images: _images),
                    ),
                  ),
                ),
                // 预留底部空间，避免内容被底部ScrollView遮挡
                const SizedBox(height: 122),
              ],
            ),
          ),
          // 恢复底部横向ScrollView区域，固定在底部
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 122,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 1 + _images.length,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    // 上传图片按钮
                    return GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 70,
                        height: 110,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: Colors.grey[300]!, width: 1),
                        ),
                        child: Icon(Icons.add_a_photo,
                            size: 32, color: Colors.grey[400]),
                      ),
                    );
                  } else {
                    // 展示已上传图片
                    return Stack(
                      children: [
                        GestureDetector(
                          onTap: () {
                            // 大图预览
                            showDialog(
                              context: context,
                              builder: (_) => Dialog(
                                backgroundColor: Colors.transparent,
                                child: GestureDetector(
                                  onTap: () => Navigator.of(context).pop(),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      color: Colors.black,
                                    ),
                                    child: Image.file(_images[index - 1],
                                        fit: BoxFit.contain),
                                  ),
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: 70,
                            height: 110,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.grey[300]!, width: 1),
                              image: DecorationImage(
                                image: FileImage(_images[index - 1]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        // 删除按钮
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _images.removeAt(index - 1);
                              });
                            },
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  size: 12, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
            ),
          ),
          // 自定义导航栏（标题真正居中）放在Stack最后，确保在最上层
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 返回箭头（左侧）
                  Positioned(
                    left: 16,
                    top: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.black, size: 24),
                    ),
                  ),
                  // 居中标题
                  const Align(
                    alignment: Alignment.center,
                    child: Text(
                      'New Outfit',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  // Save胶囊按钮（右侧美化）
                  Positioned(
                    right: 16,
                    top: 10,
                    child: GestureDetector(
                      onTap: _saveImagesToSandbox,
                      child: Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Save',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 内部布局demo
class _OutfitInnerDemo extends StatelessWidget {
  final List<File> images;
  const _OutfitInnerDemo({Key? key, required this.images}) : super(key: key);

  void _showImagePreview(BuildContext context, File image) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.black,
            ),
            child: Image.file(image, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double gap = 9;
    const double totalWidth = 309;
    const double totalHeight = 420;
    final List<File?> showImages =
        List.generate(5, (i) => i < images.length ? images[i] : null);
    return Row(
      children: [
        // 左侧上下两个view
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 10, top: 10, bottom: 10),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(bottom: gap / 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: showImages[0] != null
                        ? GestureDetector(
                            onTap: () =>
                                _showImagePreview(context, showImages[0]!),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(showImages[0]!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity),
                            ),
                          )
                        : const SizedBox(),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(top: gap / 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: showImages[1] != null
                        ? GestureDetector(
                            onTap: () =>
                                _showImagePreview(context, showImages[1]!),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(showImages[1]!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity),
                            ),
                          )
                        : const SizedBox(),
                  ),
                ),
              ],
            ),
          ),
        ),
        // 右侧三行view
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(
                right: 10, top: 10, bottom: 10, left: gap),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(bottom: gap / 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: showImages[2] != null
                        ? GestureDetector(
                            onTap: () =>
                                _showImagePreview(context, showImages[2]!),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(showImages[2]!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity),
                            ),
                          )
                        : const SizedBox(),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: gap / 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: showImages[3] != null
                        ? GestureDetector(
                            onTap: () =>
                                _showImagePreview(context, showImages[3]!),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(showImages[3]!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity),
                            ),
                          )
                        : const SizedBox(),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(top: gap / 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: showImages[4] != null
                        ? GestureDetector(
                            onTap: () =>
                                _showImagePreview(context, showImages[4]!),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(showImages[4]!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity),
                            ),
                          )
                        : const SizedBox(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// 穿搭组模型
class OutfitGroup {
  final List<String> imagePaths; // 最多5个，顺序即左上、左下、右上、右中、右下
  OutfitGroup(this.imagePaths);

  Map<String, dynamic> toJson() => {'imagePaths': imagePaths};
  factory OutfitGroup.fromJson(Map<String, dynamic> json) =>
      OutfitGroup(List<String>.from(json['imagePaths']));

  // 保存所有穿搭组到SharedPreferences
  static Future<void> saveAll(List<OutfitGroup> groups) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = groups.map((g) => jsonEncode(g.toJson())).toList();
    await prefs.setStringList('outfitGroups', jsonList);
  }

  // 读取所有穿搭组
  static Future<List<OutfitGroup>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList('outfitGroups') ?? [];
    return jsonList.map((e) => OutfitGroup.fromJson(jsonDecode(e))).toList();
  }
}
