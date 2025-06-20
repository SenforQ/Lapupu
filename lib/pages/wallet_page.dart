import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';

// 充值项常量
class GoldProduct {
  final String productId;
  final int coins;
  final String priceText; // 预设价格文本

  GoldProduct({
    required this.productId,
    required this.coins,
    required this.priceText,
  });
}

final List<GoldProduct> kGoldProducts = [
  GoldProduct(productId: 'Lapupu', coins: 32, priceText: '\$0.99'),
  GoldProduct(productId: 'Lapupu2', coins: 96, priceText: '\$2.99'),
  GoldProduct(productId: 'Lapupu5', coins: 189, priceText: '\$5.99'),
  GoldProduct(productId: 'Lapupu9', coins: 359, priceText: '\$9.99'),
  GoldProduct(productId: 'Lapupu19', coins: 729, priceText: '\$19.99'),
  GoldProduct(productId: 'Lapupu49', coins: 1869, priceText: '\$49.99'),
  GoldProduct(productId: 'Lapupu99', coins: 3799, priceText: '\$99.99'),
  GoldProduct(productId: 'Lapupu159', coins: 5999, priceText: '\$159.99'),
  GoldProduct(productId: 'Lapupu239', coins: 9059, priceText: '\$239.99'),
];

const String kGoldBalanceKey = 'gold_coins_balance';

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

Future<void> fetchAndCacheIAPProducts(
    InAppPurchase iap, Set<String> productIds) async {
  final response = await iap.queryProductDetails(productIds);
  if (response.error == null && response.productDetails.isNotEmpty) {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> productList = response.productDetails
        .map((p) => {
              'id': p.id,
              'title': p.title,
              'description': p.description,
              'price': p.price,
              'currencySymbol': p.currencySymbol,
              'rawPrice': p.rawPrice,
            })
        .toList();
    await prefs.setString('iap_product_cache', jsonEncode(productList));
  }
}

Future<List<Map<String, dynamic>>?> getCachedIAPProducts() async {
  final prefs = await SharedPreferences.getInstance();
  final jsonStr = prefs.getString('iap_product_cache');
  if (jsonStr == null) return null;
  final List<dynamic> list = jsonDecode(jsonStr);
  return list.cast<Map<String, dynamic>>();
}

class WalletPage extends StatefulWidget {
  const WalletPage({Key? key}) : super(key: key);

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  int _balance = 0;
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
    _loadBalance();
    _checkConnectivityAndInit();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
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
      final Set<String> _kIds = kGoldProducts.map((e) => e.productId).toSet();
      print('Querying products with IDs: $_kIds');

      // 先尝试从缓存获取
      final cachedProducts = await getCachedIAPProducts();
      print('Cached products: $cachedProducts');
      if (cachedProducts != null) {
        setState(() {
          _products = {
            for (var p in cachedProducts)
              p['id']: ProductDetails(
                id: p['id'],
                title: p['title'],
                description: p['description'],
                price: p['price'],
                rawPrice: p['rawPrice'],
                currencySymbol: p['currencySymbol'],
                currencyCode: p['currencyCode'] ?? 'USD',
              )
          };
        });
      }

      // 拉取最新商品信息
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
      print('Updated products map: ${_products.keys}');

      // 缓存商品信息
      await fetchAndCacheIAPProducts(_inAppPurchase, _kIds);

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
        // 根据产品ID更新余额
        final product = _products[purchase.productID];
        if (product != null) {
          int coins = _getCoinsForProduct(purchase.productID);
          await _updateBalance(coins);
          showCenterToast(context, 'Successfully purchased $coins coins!');
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

  int _getCoinsForProduct(String productId) {
    final goldProduct = kGoldProducts.firstWhere(
      (p) => p.productId == productId,
      orElse: () => GoldProduct(productId: '', coins: 0, priceText: ''),
    );
    return goldProduct.coins;
  }

  Future<void> _loadBalance() async {
    final prefs = await SharedPreferences.getInstance();
    int balance = prefs.getInt(kGoldBalanceKey) ?? -1;

    // 如果是新用户（余额为-1），给予100金币
    if (balance == -1) {
      balance = 100;
      await prefs.setInt(kGoldBalanceKey, balance);
      print('New user detected, granted 100 coins');
    }

    setState(() {
      _balance = balance;
    });
  }

  Future<void> _updateBalance(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final newBalance = _balance + amount;
    await prefs.setInt(kGoldBalanceKey, newBalance);
    setState(() {
      _balance = newBalance;
    });
  }

  Future<void> _handlePurchase(GoldProduct goldProduct) async {
    if (!_isAvailable) {
      showCenterToast(context, 'Store is not available');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final product = _products[goldProduct.productId];
      print('Attempting to purchase product: ${goldProduct.productId}');
      print('Product details: $product');

      if (product == null) {
        throw Exception('Product not found');
      }

      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );

      print('Initiating purchase with param: $purchaseParam');
      await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      print('Purchase error: $e');
      if (mounted) {
        showCenterToast(context, 'Purchase failed: ${e.toString()}');
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 显示金币说明弹窗
  void _showCoinsExplanation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.monetization_on,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'About Coins',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4B2B3A),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Coins are used to interact with our AI Outfit Assistant:',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF4B2B3A),
              ),
            ),
            SizedBox(height: 16),
            Text(
              '• New users receive 100 coins for free\n'
              '• Each AI Outfit Assistant query costs 2 coins\n'
              '• Purchase more coins when you run out\n'
              '• Get personalized fashion advice anytime',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF666666),
                height: 1.5,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Start exploring fashion with AI today!',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFFDB64A5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Got it',
              style: TextStyle(
                color: Color(0xFFDB64A5),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          // 主要内容
          CustomScrollView(
            slivers: [
              // 顶部背景和金币显示
              SliverToBoxAdapter(
                child: _buildTopSection(),
              ),

              // 商品列表
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildCoinPackageItem(kGoldProducts[index]),
                      );
                    },
                    childCount: kGoldProducts.length,
                  ),
                ),
              ),

              // 底部安全区域
              const SliverToBoxAdapter(
                child: SizedBox(height: 20),
              ),
            ],
          ),

          // 购买Loading覆盖层
          if (_isLoading) _buildPurchaseLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildPurchaseLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
                strokeWidth: 3,
              ),
              const SizedBox(height: 16),
              const Text(
                'Processing Purchase...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please wait while we process your payment',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopSection() {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('lib/assets/Photo/message_top_bg_2025_6_17.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // AppBar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        'Wallet',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // 感叹号按钮
                    GestureDetector(
                      onTap: _showCoinsExplanation,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.info_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 金币显示卡片
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B9D), Color(0xFFFF8CC8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'My gold coins',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _balance.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoinPackageItem(GoldProduct package) {
    final product = _products[package.productId];
    final bool isProductAvailable = _isAvailable && product != null;
    final bool canPurchase = isProductAvailable && !_isLoading;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 金币图标
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.monetization_on,
              color: Colors.white,
              size: 20,
            ),
          ),

          const SizedBox(width: 16),

          // 金币数量
          Expanded(
            child: Text(
              '${package.coins} Gold coins',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),

          // 购买按钮
          GestureDetector(
            onTap: canPurchase ? () => _handlePurchase(package) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _getButtonColor(isProductAvailable),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _getButtonText(product, package),
                style: TextStyle(
                  color: _getButtonTextColor(isProductAvailable),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getButtonColor(bool isProductAvailable) {
    if (isProductAvailable && !_isLoading) {
      return const Color(0xFF4ECDC4); // 可购买
    } else {
      return const Color(0xFFE0E0E0); // 不可用
    }
  }

  Color _getButtonTextColor(bool isProductAvailable) {
    if (isProductAvailable && !_isLoading) {
      return Colors.white;
    } else {
      return Colors.grey[600]!;
    }
  }

  String _getButtonText(ProductDetails? product, GoldProduct package) {
    if (product != null) {
      return product.price;
    } else if (!_isAvailable) {
      return 'Not available';
    } else {
      return package.priceText; // 使用预设价格
    }
  }
}
