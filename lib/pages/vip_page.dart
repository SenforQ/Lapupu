import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:convert';

// VIP产品定义
class VipProduct {
  final String productId;
  final int days;
  final String priceText;

  VipProduct({
    required this.productId,
    required this.days,
    required this.priceText,
  });
}

final List<VipProduct> kVipProducts = [
  VipProduct(productId: 'LapupuWeekVIP', days: 7, priceText: '\$12.99'),
  VipProduct(productId: 'LapupuMonthVIP', days: 30, priceText: '\$49.99'),
];

// 居中自动消失提示
Future<void> showCenterToast(BuildContext context, String message,
    {int milliseconds = 1800}) async {
  showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: '',
    transitionDuration: const Duration(milliseconds: 150),
    pageBuilder: (context, anim1, anim2) {
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.85),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            message,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    },
    transitionBuilder: (context, anim1, anim2, child) {
      return FadeTransition(opacity: anim1, child: child);
    },
  );
  await Future.delayed(Duration(milliseconds: milliseconds));
  if (Navigator.of(context, rootNavigator: true).canPop()) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}

class VipPage extends StatefulWidget {
  const VipPage({super.key});

  @override
  State<VipPage> createState() => _VipPageState();
}

class _VipPageState extends State<VipPage> {
  bool _isVip = false;
  int _remainingDays = 0;
  int _selectedProductIndex = 0; // 0: 7天, 1: 30天
  bool _isLoading = false;
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isAvailable = false;
  Map<String, ProductDetails> _products = {};
  int _retryCount = 0;
  static const int maxRetries = 3;

  @override
  void initState() {
    super.initState();
    _loadVipStatus();
    _checkConnectivityAndInit();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _loadVipStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final vipExpiry = prefs.getInt('vip_expiry_timestamp') ?? 0;
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    if (vipExpiry > currentTime) {
      final remainingTime = vipExpiry - currentTime;
      final remainingDays = (remainingTime / (1000 * 60 * 60 * 24)).ceil();
      setState(() {
        _isVip = true;
        _remainingDays = remainingDays;
      });
    } else {
      setState(() {
        _isVip = false;
        _remainingDays = 0;
      });
    }
  }

  Future<void> _checkConnectivityAndInit() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      showCenterToast(context,
          'No internet connection. Please check your network settings.');
      return;
    }
    await _initIAP();
  }

  Future<void> _initIAP() async {
    try {
      final available = await _inAppPurchase.isAvailable();
      print('IAP Available: $available');
      if (!mounted) return;
      setState(() {
        _isAvailable = available;
      });
      if (!available) {
        if (mounted) {
          showCenterToast(context, 'In-App Purchase not available');
        }
        return;
      }

      // 获取所有产品ID
      final Set<String> _kIds = kVipProducts.map((e) => e.productId).toSet();
      print('Querying VIP products with IDs: $_kIds');

      // 拉取商品信息
      final response = await _inAppPurchase.queryProductDetails(_kIds);
      print('Query response error: ${response.error}');
      print('Found products: ${response.productDetails.length}');
      print('Not found products: ${response.notFoundIDs}');

      if (response.error != null) {
        if (_retryCount < maxRetries) {
          _retryCount++;
          print(
              'Retrying IAP initialization. Attempt $_retryCount of $maxRetries');
          await Future.delayed(Duration(seconds: 2));
          await _initIAP();
          return;
        }
        showCenterToast(
            context, 'Failed to load products: ${response.error!.message}');
      }

      setState(() {
        _products = {for (var p in response.productDetails) p.id: p};
      });
      print('Updated VIP products map: ${_products.keys}');

      // 监听购买流
      _subscription = _inAppPurchase.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: () {
          _subscription?.cancel();
        },
        onError: (e) {
          print('Purchase stream error: $e');
          if (mounted) {
            showCenterToast(context, 'Purchase error: ${e.toString()}');
          }
        },
      );
    } catch (e) {
      print('IAP initialization error: $e');
      if (_retryCount < maxRetries) {
        _retryCount++;
        print(
            'Retrying IAP initialization. Attempt $_retryCount of $maxRetries');
        await Future.delayed(Duration(seconds: 2));
        await _initIAP();
      } else {
        if (mounted) {
          showCenterToast(context,
              'Failed to initialize in-app purchases. Please try again later.');
        }
      }
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        await _inAppPurchase.completePurchase(purchase);
        // 根据产品ID更新VIP状态
        final vipProduct = kVipProducts.firstWhere(
          (p) => p.productId == purchase.productID,
          orElse: () => VipProduct(productId: '', days: 0, priceText: ''),
        );
        if (vipProduct.productId.isNotEmpty) {
          await _activateVip(vipProduct.days);
          showCenterToast(
              context, 'VIP activated for ${vipProduct.days} days!');
        }
      } else if (purchase.status == PurchaseStatus.error) {
        showCenterToast(
            context, 'Purchase failed: ${purchase.error?.message ?? ''}');
      } else if (purchase.status == PurchaseStatus.canceled) {
        showCenterToast(context, 'Purchase canceled.');
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _activateVip(int days) async {
    final prefs = await SharedPreferences.getInstance();
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final existingExpiry = prefs.getInt('vip_expiry_timestamp') ?? currentTime;
    final startTime =
        existingExpiry > currentTime ? existingExpiry : currentTime;
    final newExpiry = startTime + (days * 24 * 60 * 60 * 1000);

    await prefs.setInt('vip_expiry_timestamp', newExpiry);
    _loadVipStatus();
  }

  Future<void> _purchaseVip(int days) async {
    if (!_isAvailable) {
      showCenterToast(context, 'Store is not available');
      return;
    }

    if (_isVip) {
      showCenterToast(context, 'You are already a VIP member');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final vipProduct = kVipProducts.firstWhere(
        (p) => p.days == days,
        orElse: () => VipProduct(productId: '', days: 0, priceText: ''),
      );

      if (vipProduct.productId.isEmpty) {
        throw Exception('VIP product not found');
      }

      final product = _products[vipProduct.productId];
      print('Attempting to purchase VIP product: ${vipProduct.productId}');
      print('Product details: $product');

      if (product == null) {
        throw Exception('Product not found');
      }

      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );

      print('Initiating VIP purchase with param: $purchaseParam');
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      print('VIP Purchase error: $e');
      if (mounted) {
        showCenterToast(context, 'Purchase failed: ${e.toString()}');
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _restorePurchases() async {
    if (!_isAvailable) {
      showCenterToast(context, 'Store is not available');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _inAppPurchase.restorePurchases();
      showCenterToast(context, 'Restore completed');
    } catch (e) {
      print('Restore error: $e');
      if (mounted) {
        showCenterToast(context, 'Restore failed: ${e.toString()}');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 背景图片
          Positioned.fill(
            child: Image.asset(
              'lib/assets/Photo/me_top_bg_2025_6_13.png',
              fit: BoxFit.cover,
            ),
          ),

          // 主要内容
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // 顶部AppBar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: const Icon(
                              Icons.arrow_back_ios,
                              color: Colors.black,
                              size: 20,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'VIP Club',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 36), // 平衡左边的返回按钮
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // VIP状态卡片
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFFD700), Color(0xFF000000)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Image.asset(
                          'lib/assets/Photo/diamond_2025_6_20.png',
                          width: 40,
                          height: 40,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'VIP Club',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isVip
                                    ? '$_remainingDays days'
                                    : 'Not activated',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_isVip)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'ACTIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // VIP特权列表 - 固定高度
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    height: 600, // 固定高度
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildVipFeature(
                          'lib/assets/Photo/diamond_2025_6_20.png',
                          'Remove Ads',
                          'VIPs can enjoy ad-free experience',
                        ),
                        const SizedBox(height: 20),
                        _buildVipFeature(
                          'lib/assets/Photo/diamond_2025_6_20.png',
                          'Edit Profile Freely',
                          'VIPs can modify profile without limits',
                        ),
                        const SizedBox(height: 20),
                        _buildVipFeature(
                          'lib/assets/Photo/diamond_2025_6_20.png',
                          'Unlimited Profile Views',
                          'VIPs can view other profiles endlessly',
                        ),

                        const Spacer(),

                        // 购买选项
                        Row(
                          children: [
                            Expanded(
                              child: _buildPurchaseOption(
                                'lib/assets/Photo/diamond_little_2025_6_20.png',
                                '\$12.99',
                                '7 Days',
                                0,
                                _selectedProductIndex == 0,
                                () => setState(() => _selectedProductIndex = 0),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildPurchaseOption(
                                'lib/assets/Photo/diamond_more_2025_6_20.png',
                                '\$49.99',
                                '30 Days',
                                1,
                                _selectedProductIndex == 1,
                                () => setState(() => _selectedProductIndex = 1),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // 确认按钮
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isVip || _isLoading
                                ? null
                                : () {
                                    // 根据选中的产品执行购买
                                    final days =
                                        _selectedProductIndex == 0 ? 7 : 30;
                                    _purchaseVip(days);
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isVip
                                  ? Colors.grey
                                  : const Color(0xFF4ECDC4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _isVip ? 'Already VIP' : 'Confirm',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Restore按钮
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: TextButton(
                            onPressed: _isLoading ? null : _restorePurchases,
                            style: TextButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: const Text(
                              'Restore',
                              style: TextStyle(
                                color: Color(0xFF4ECDC4),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // 加载覆盖层
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Processing...',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVipFeature(String iconPath, String title, String description) {
    return Row(
      children: [
        Image.asset(
          iconPath,
          width: 40,
          height: 40,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPurchaseOption(String iconPath, String price, String duration,
      int index, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4ECDC4).withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4ECDC4)
                : Colors.grey.withOpacity(0.3),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.1 : 0.05),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Image.asset(
              iconPath,
              width: 60,
              height: 60,
            ),
            const SizedBox(height: 12),
            Text(
              price,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              duration,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
