import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'admin_pages.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

// ── Design tokens ───────────────────────────────────────────────────────
// A small, deliberate palette: deep navy for trust/authority, a warm
// signal-orange for calls to action (echoes an "on" indicator LED), and a
// cool electric blue reserved only for prices, so the number that matters
// most on a shopping app always reads as a price at a glance.
const navy = Color(0xFF0E2A5E); // primary brand ink
const navyDeep = Color(0xFF081A3D); // headlines, high-contrast text
const navySoft = Color(0xFF335488); // secondary brand tone
const orange = Color(0xFFFF5A1F); // signal accent / CTAs
const orangeSoft = Color(0xFFFFE7DA); // accent tint for badges
const priceBlue = Color(0xFF2557D6); // price emphasis only
const priceBlueSoft = Color(0xFFE8EEFF);
const successColor = Color(0xFF17A34A);
const successSoft = Color(0xFFDCFCE7);
const dangerColor = Color(0xFFE0402A);
const dangerSoft = Color(0xFFFCE4E0);
const pageBg = Color(0xFFF5F7FB); // app canvas
const surfaceTint = Color(0xFFF1F4FA); // image plates / subtle fills
const lineColor = Color(0xFFE6E9F2); // hairline borders
const mutedText = Color(0xFF667085); // secondary copy
const spacing = 4.0; // base spacing unit (multiples of 4)

final apiBaseUrl = 'https://electromart-backend-ab2n.onrender.com/api';

void main() => runApp(const ElectroMartApp());

class ElectroMartApp extends StatefulWidget {
  const ElectroMartApp({super.key});

  @override
  State<ElectroMartApp> createState() => _ElectroMartAppState();
}

class _ElectroMartAppState extends State<ElectroMartApp> {
  UserAccount? currentUser;
  final cart = <CartLine>[];
  final wishlist = <Product>{};
  final orders = <OrderRecord>[];
  bool checkingSavedLogin = true;

  int get cartCount => cart.fold(0, (sum, item) => sum + item.quantity);

  @override
  void initState() {
    super.initState();
    loadSavedUser();
  }

  Future<void> loadSavedUser() async {
    final prefs = await SharedPreferences.getInstance();

    final accessToken = prefs.getString('accessToken');
    final refreshToken = prefs.getString('refreshToken');

    if (accessToken == null || refreshToken == null) {
      setState(() => checkingSavedLogin = false);
      return;
    }

    final name = prefs.getString('name') ?? '';
    final email = prefs.getString('email') ?? '';
    final phone = prefs.getString('phone') ?? '';

    setState(() {
      currentUser = UserAccount(
        name: name,
        email: email,
        phone: phone,
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      checkingSavedLogin = false;
    });
  }

  Future<void> setUser(UserAccount user) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('name', user.name);
    await prefs.setString('email', user.email);
    await prefs.setString('phone', user.phone);
    await prefs.setString('accessToken', user.accessToken);
    await prefs.setString('refreshToken', user.refreshToken);

    setState(() => currentUser = user);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    setState(() {
      currentUser = null;
      cart.clear();
      wishlist.clear();
    });
  }

  Future<void> addToCart(Product product) async {
    if (currentUser == null) return;

    await http.post(
      Uri.parse('$apiBaseUrl/cart/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${currentUser!.accessToken}',
      },
      body: jsonEncode({'product_id': product.id, 'quantity': 1}),
    );

    final index = cart.indexWhere((item) => item.product.id == product.id);

    setState(() {
      if (index == -1) {
        cart.add(CartLine(product: product));
      } else {
        cart[index].quantity++;
      }
    });
  }

  void toggleWishlist(Product product) {
    setState(() {
      wishlist.contains(product)
          ? wishlist.remove(product)
          : wishlist.add(product);
    });
  }

  void updateQuantity(CartLine line, int quantity) {
    setState(() {
      if (quantity <= 0) {
        cart.remove(line);
      } else {
        line.quantity = quantity;
      }
    });
  }

  Future<OrderRecord?> placeOrder({
    required String fullName,
    required String phone,
    required String email,
    required String address,
    required String paymentMethod,
  }) async {
    if (currentUser == null) return null;

    final response = await http.post(
      Uri.parse('$apiBaseUrl/checkout/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${currentUser!.accessToken}',
      },
      body: jsonEncode({
        'full_name': fullName,
        'phone': phone,
        'address': address,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception(response.body);
    }

    final data = jsonDecode(response.body);

    final order = OrderRecord(
      id: 'EM-${data['id']}',
      fullName: data['full_name'],
      phone: data['phone'],
      email: email,
      address: data['address'],
      paymentMethod: data['payment_method'],
      status: data['status'],
      createdAt: DateTime.now(),
      items: cart
          .map(
            (item) => CartLine(product: item.product, quantity: item.quantity),
          )
          .toList(),
    );

    setState(() {
      orders.insert(0, order);
      cart.clear();
    });

    return order;
  }

  @override
  Widget build(BuildContext context) {
    if (checkingSavedLogin) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: pageBg,
          body: const Center(
            child: CircularProgressIndicator(color: orange, strokeWidth: 3),
          ),
        ),
      );
    }
    final baseTextTheme = ThemeData(useMaterial3: true).textTheme;
    final textTheme = baseTextTheme.copyWith(
      displaySmall: baseTextTheme.displaySmall?.copyWith(
        color: navyDeep,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        height: 1.08,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        color: navyDeep,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        height: 1.15,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        color: navyDeep,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        color: navyDeep,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        color: navyDeep,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        color: const Color(0xFF1F2937),
        height: 1.5,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        color: const Color(0xFF1F2937),
        height: 1.5,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
      ),
      labelSmall: baseTextTheme.labelSmall?.copyWith(
        color: mutedText,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    );

    return MaterialApp(
      title: 'ElectroMart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: pageBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: navy,
          primary: navy,
          secondary: orange,
          error: dangerColor,
        ),
        textTheme: textTheme,
        splashFactory: InkRipple.splashFactory,
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: lineColor),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: lineColor,
          thickness: 1,
          space: 32,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: navyDeep,
          surfaceTintColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 1,
          shadowColor: Colors.black.withValues(alpha: 0.06),
          titleTextStyle: textTheme.titleLarge,
          iconTheme: const IconThemeData(color: navyDeep),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: orange,
            foregroundColor: Colors.white,
            disabledBackgroundColor: orange.withValues(alpha: 0.4),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: navyDeep,
            side: const BorderSide(color: lineColor, width: 1.4),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: navy,
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(foregroundColor: navyDeep),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          hintStyle: const TextStyle(color: mutedText),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: lineColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: lineColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: navy, width: 1.6),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: surfaceTint,
          selectedColor: navy,
          disabledColor: surfaceTint,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            color: navyDeep,
          ),
          secondaryLabelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          side: const BorderSide(color: lineColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: navyDeep,
          contentTextStyle: const TextStyle(color: Colors.white),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        listTileTheme: const ListTileThemeData(
          iconColor: navyDeep,
          textColor: navyDeep,
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: orange,
        ),
      ),
      home: HomePage(
        currentUser: currentUser,
        cart: cart,
        cartCount: cartCount,
        wishlist: wishlist,
        orders: orders,
        onLogin: setUser,
        onLogout: logout,
        onAddToCart: addToCart,
        onToggleWishlist: toggleWishlist,
        onUpdateQuantity: updateQuantity,
        onPlaceOrder: placeOrder,
      ),
    );
  }
}

class UserAccount {
  const UserAccount({
    required this.name,
    required this.email,
    required this.phone,
    required this.accessToken,
    required this.refreshToken,
  });
  factory UserAccount.fromStorage(Map<String, String> data) {
    return UserAccount(
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      accessToken: data['accessToken'] ?? '',
      refreshToken: data['refreshToken'] ?? '',
    );
  }

  final String name;
  final String email;
  final String phone;
  final String accessToken;
  final String refreshToken;
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.price,
    required this.rating,
    required this.stock,
    required this.image,
    required this.description,
    required this.details,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final category = json['category'];
    final description = json['description'] ?? '';

    return Product(
      id: json['id'],
      name: json['name'] ?? '',
      brand: json['brand'] ?? '',
      category: category is Map ? category['name'] ?? '' : '',
      price: double.parse('${json['price']}'),
      rating: double.parse('${json['rating']}'),
      stock: json['stock'] ?? 0,
      image: json['image'] ?? 'assets/images/logo_web.png',
      description: description,
      details: description
          .toString()
          .split('.')
          .where((String item) => item.trim().isNotEmpty)
          .map<String>((String item) => item.trim())
          .toList(),
    );
  }

  final int id;
  final String name;
  final String brand;
  final String category;
  final double price;
  final double rating;
  final int stock;
  final String image;
  final String description;
  final List<String> details;
}

class CartLine {
  CartLine({required this.product, this.quantity = 1});

  final Product product;
  int quantity;

  double get subtotal => product.price * quantity;
}

class OrderRecord {
  const OrderRecord({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.address,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    required this.items,
  });

  factory OrderRecord.fromJson(Map<String, dynamic> json) {
    final orderItems = (json['items'] as List? ?? []).map<CartLine>((item) {
      return CartLine(
        product: Product(
          id: item['product'] ?? 0,
          name: item['product_name'] ?? 'Product',
          brand: '',
          category: '',
          price: double.tryParse('${item['price']}') ?? 0,
          rating: 0,
          stock: 0,
          image: 'assets/images/logo_web.png',
          description: 'Purchased product',
          details: const ['Purchased product'],
        ),
        quantity: item['quantity'] ?? 1,
      );
    }).toList();

    return OrderRecord(
      id: 'EM-${json['id']}',
      fullName: json['full_name'] ?? '',
      phone: json['phone'] ?? '',
      email: '',
      address: json['address'] ?? '',
      paymentMethod: json['payment_method'] ?? 'Cash on Delivery',
      status: json['status'] ?? 'confirmed',
      createdAt: DateTime.tryParse('${json['ordered_at']}') ?? DateTime.now(),
      items: orderItems,
    );
  }

  final String id;
  final String fullName;
  final String phone;
  final String email;
  final String address;
  final String paymentMethod;
  final String status;
  final DateTime createdAt;
  final List<CartLine> items;

  double get total => items.fold(0, (sum, item) => sum + item.subtotal);
}

const categories = [
  'All',
  'Phones',
  'Laptops',
  'Tablets',
  'TVs',
  'Accessories',
];

final products = <Product>[
  product(
    1,
    'iPhone 17 Pro Max',
    'Apple',
    'Phones',
    245000,
    4.8,
    8,
    'assets/images/17promaxsilver.webp',
  ),
  product(
    2,
    'iPhone 16 Pro',
    'Apple',
    'Phones',
    119499,
    4.8,
    8,
    'assets/images/iphone_16_pro.jpg',
  ),
  product(
    3,
    'iPhone 15 Pro Max',
    'Apple',
    'Phones',
    145000,
    4.8,
    8,
    'assets/images/iPhone-15-Pro-Max.jpg',
  ),
  product(
    4,
    'Galaxy Z Fold 8',
    'Samsung',
    'Phones',
    189999,
    4.5,
    12,
    'assets/images/galaxyzfold8.png',
  ),
  product(
    5,
    'Galaxy A57 5G',
    'Samsung',
    'Phones',
    71999,
    4.5,
    12,
    'assets/images/galaxy a57.png',
  ),
  product(
    6,
    'Samsung Galaxy A73 5G',
    'Samsung',
    'Phones',
    52000,
    4.5,
    12,
    'assets/images/Samsung-Galaxy-A73-5G.webp',
  ),
  product(
    7,
    'Google Pixel 10 Pro',
    'Google',
    'Phones',
    130999,
    4.4,
    10,
    'assets/images/pixel10pro.png',
  ),
  product(
    8,
    'Google Pixel 9',
    'Google',
    'Phones',
    68499,
    4.4,
    10,
    'assets/images/pixel9.webp',
  ),
  product(
    9,
    'Google Pixel 8a',
    'Google',
    'Phones',
    48000,
    4.4,
    10,
    'assets/images/Google-Pixel-8a.webp',
  ),
  product(
    10,
    'iPad Pro M4',
    'Apple',
    'Tablets',
    125000,
    4.9,
    5,
    'assets/images/iPad-pro-m4.jpg',
  ),
  product(
    11,
    'OnePlus Pad 4',
    'OnePlus',
    'Tablets',
    89999,
    4.9,
    5,
    'assets/images/onepluspad4.webp',
  ),
  product(
    12,
    'Samsung Tab',
    'Samsung',
    'Tablets',
    42000,
    4.3,
    9,
    'assets/images/samsung_tab.webp',
  ),
  product(
    13,
    'Huawei MatePad',
    'Huawei',
    'Tablets',
    36000,
    4.2,
    7,
    'assets/images/Huawei-MatePad.webp',
  ),
  product(
    14,
    'Apple MacBook',
    'Apple',
    'Laptops',
    138000,
    4.7,
    4,
    'assets/images/apple_macbook.jpg',
  ),
  product(
    15,
    'Xiaomi Pad 8',
    'Xiaomi',
    'Tablets',
    49999,
    4.7,
    4,
    'assets/images/Xiomipad8.webp',
  ),
  product(
    16,
    'Lenovo Legion 5',
    'Lenovo',
    'Laptops',
    194999,
    4.3,
    6,
    'assets/images/lenovolegion5.webp',
  ),
  product(
    17,
    'Lenovo IdeaPad Slim 3',
    'Lenovo',
    'Laptops',
    99000,
    4.5,
    5,
    'assets/images/lenovo_ideapad_slim3.webp',
  ),
  product(
    18,
    'Asus Vivobook 14',
    'Asus',
    'Laptops',
    89000,
    4.5,
    5,
    'assets/images/asusvivobook14.webp',
  ),
  product(
    19,
    'Acer Nitro V15',
    'Acer',
    'Laptops',
    89000,
    4.5,
    5,
    'assets/images/Acernitrov15.jpeg',
  ),
  product(
    20,
    'AirPods Pro 3',
    'Apple',
    'Accessories',
    27500,
    4.6,
    15,
    'assets/images/airpodspro3.jpeg',
  ),
  product(
    21,
    'AirPods 4',
    'Apple',
    'Accessories',
    26500,
    4.6,
    15,
    'assets/images/airpods4.jpeg',
  ),
  product(
    22,
    'Apple AirPods Pro 2nd Gen',
    'Apple',
    'Accessories',
    25999,
    4.6,
    15,
    'assets/images/airpodspro3.jpeg',
  ),
  product(
    23,
    'Redmi Buds 8 Youth',
    'Redmi',
    'Accessories',
    3500,
    4.6,
    15,
    'assets/images/redmibuds8youth.webp',
  ),
  product(
    24,
    'Haylou Flowbuds N50 ANC',
    'Haylou',
    'Accessories',
    2699,
    4.6,
    15,
    'assets/images/haylouflowbudsn50.webp',
  ),
  product(
    25,
    'Anker Power Bank',
    'Anker',
    'Accessories',
    3900,
    4.4,
    20,
    'assets/images/anker.webp',
  ),
  product(
    26,
    'Foneng PX137',
    'Foneng',
    'Accessories',
    3800,
    4.4,
    20,
    'assets/images/foneng.webp',
  ),
  product(
    27,
    'Amazfit Bip Max Smart Watch',
    'Amazfit',
    'Accessories',
    11000,
    4.4,
    20,
    'assets/images/sm1.webp',
  ),
  product(
    28,
    'Imiki Muse 1',
    'Imiki',
    'Accessories',
    3800,
    4.4,
    20,
    'assets/images/sm2.webp',
  ),
  product(
    29,
    'Haier 43P7 Pro 43"',
    'Haier',
    'TVs',
    86000,
    4.2,
    5,
    'assets/images/tv1.webp',
  ),
  product(
    30,
    'Toshiba 55M450RP 55"',
    'Toshiba',
    'TVs',
    76000,
    4.2,
    5,
    'assets/images/tv2.jpeg',
  ),
];

Product product(
  int id,
  String name,
  String brand,
  String category,
  double price,
  double rating,
  int stock,
  String image,
) {
  return Product(
    id: id,
    name: name,
    brand: brand,
    category: category,
    price: price,
    rating: rating,
    stock: stock,
    image: image,
    description: descriptionFor(name, brand, category),
    details: detailsFor(name, category),
  );
}

String descriptionFor(String name, String brand, String category) {
  switch (category) {
    case 'Phones':
      return '$name is a $brand smartphone designed for fast performance, clear photos, smooth browsing, and reliable daily use.';
    case 'Tablets':
      return '$name is a portable tablet for online classes, entertainment, note-taking, browsing, and productivity.';
    case 'Laptops':
      return '$name is a dependable laptop for study, office work, multitasking, and creative projects.';
    case 'TVs':
      return '$name is a smart television built for movies, streaming, gaming, and home entertainment.';
    default:
      return '$name is a useful tech accessory for daily convenience, entertainment, and productivity.';
  }
}

List<String> detailsFor(String name, String category) {
  if (name.contains('Toshiba')) {
    return [
      'VIDAA Smart TV',
      '55-inch bezel-less 4K QLED panel',
      '24W speaker system',
      'HDR10, Dolby Vision, and Dolby Audio',
      'Dual Band Wi-Fi, HDMI, USB, and LAN ports',
    ];
  }
  if (category == 'Phones') {
    return [
      'AMOLED display',
      '5G connectivity',
      'High-resolution camera',
      'Fast charging support',
      'Long battery backup',
    ];
  }
  if (category == 'Tablets') {
    return [
      'Large touch display',
      'Wi-Fi and Bluetooth support',
      'Stereo speakers',
      'Long battery life',
      'Good for study and entertainment',
    ];
  }
  if (category == 'Laptops') {
    return [
      'Full HD display',
      'Fast SSD storage',
      'Wi-Fi and Bluetooth support',
      'Comfortable keyboard',
      'Good for study and work',
    ];
  }
  if (category == 'TVs') {
    return [
      'Smart TV features',
      '4K picture quality',
      'Built-in streaming apps',
      'HDMI and USB support',
      'Clear speaker system',
    ];
  }
  return [
    'Wireless connectivity',
    'Compact design',
    'Long battery support',
    'Easy to use',
    'Compatible with daily devices',
  ];
}

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.currentUser,
    required this.cart,
    required this.cartCount,
    required this.wishlist,
    required this.orders,
    required this.onLogin,
    required this.onLogout,
    required this.onAddToCart,
    required this.onToggleWishlist,
    required this.onUpdateQuantity,
    required this.onPlaceOrder,
  });

  final UserAccount? currentUser;
  final List<CartLine> cart;
  final int cartCount;
  final Set<Product> wishlist;
  final List<OrderRecord> orders;
  final Future<void> Function(UserAccount user) onLogin;
  final Future<void> Function() onLogout;
  final Future<void> Function(Product product) onAddToCart;
  final ValueChanged<Product> onToggleWishlist;
  final void Function(CartLine line, int quantity) onUpdateQuantity;
  final Future<OrderRecord?> Function({
    required String fullName,
    required String phone,
    required String email,
    required String address,
    required String paymentMethod,
  })
  onPlaceOrder;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final catalogKey = GlobalKey();

  List<Product> backendProducts = [];
  bool productsLoading = true;
  String productLoadError = '';

  String selectedCategory = 'All';
  String selectedBrand = 'All';
  String query = '';
  RangeValues priceRange = const RangeValues(0, 250000);
  double minimumRating = 0;

  bool get loggedIn => widget.currentUser != null;
  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  Future<void> loadProducts() async {
    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/products/'));

      print('PRODUCT STATUS: ${response.statusCode}');
      print('PRODUCT BODY: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final loadedProducts = (data as List)
            .map<Product>(
              (item) => Product.fromJson(item as Map<String, dynamic>),
            )
            .toList();

        setState(() {
          backendProducts = loadedProducts;
          productsLoading = false;
          productLoadError = '';

          selectedCategory = 'All';
          selectedBrand = 'All';
          query = '';
          minimumRating = 0;
          priceRange = const RangeValues(0, 250000);
        });
      } else {
        setState(() {
          productsLoading = false;
          productLoadError = 'Backend error: ${response.statusCode}';
        });
      }
    } catch (error) {
      print('PRODUCT LOAD ERROR: $error');

      setState(() {
        productsLoading = false;
        productLoadError = error.toString();
      });
    }
  }

  void scrollToCatalog() {
    setState(() => selectedCategory = 'All');
    final catalogContext = catalogKey.currentContext;
    if (catalogContext == null) return;
    Scrollable.ensureVisible(
      catalogContext,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
    );
  }

  List<String> get brands {
    final values = backendProducts.map((item) => item.brand).toSet().toList()
      ..sort();
    return ['All', ...values];
  }

  List<Product> get filtered {
    return backendProducts.where((item) {
      final text = '${item.name} ${item.brand} ${item.category}'.toLowerCase();

      return (selectedCategory == 'All' || item.category == selectedCategory) &&
          (selectedBrand == 'All' || item.brand == selectedBrand) &&
          item.price >= priceRange.start &&
          item.price <= priceRange.end &&
          item.rating >= minimumRating &&
          text.contains(query.toLowerCase());
    }).toList();
  }

  Future<UserAccount?> requireLogin(String message) async {
    if (widget.currentUser != null) return widget.currentUser;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    final user = await Navigator.push<UserAccount>(
      context,
      MaterialPageRoute(builder: (_) => const AuthPage()),
    );
    if (user != null) {
      await widget.onLogin(user);
      return user;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          hero(),
          const SizedBox(height: 18),
          searchBar(),
          const SizedBox(height: 12),
          filters(),
          const SizedBox(height: 28),
          Row(
            key: catalogKey,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Catalog', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(width: 10),
              if (!productsLoading)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    '${filtered.length} item${filtered.length == 1 ? '' : 's'}',
                    style: const TextStyle(color: mutedText, fontSize: 14),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          grid(),
        ],
      ),
    );
  }

  PreferredSizeWidget appBar() {
    return AppBar(
      titleSpacing: 20,
      title: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: navy,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Image.asset(
              'assets/images/logo_web.png',
              height: 22,
              width: 22,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'ElectroMart',
            style: TextStyle(
              color: navyDeep,
              fontWeight: FontWeight.w800,
              fontSize: 19,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
      actions: [
        if (MediaQuery.of(context).size.width > 640) ...[
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutPage()),
              );
            },
            child: const Text('About'),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ContactPage()),
              );
            },
            child: const Text('Contact'),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminLoginPage()),
              );
            },
            child: const Text('Admin'),
          ),
          const SizedBox(width: 4),
          Container(width: 1, height: 24, color: lineColor),
          const SizedBox(width: 4),
        ],
        IconButton(
          tooltip: 'Profile',
          icon: const Icon(Icons.person_outline),
          onPressed: openProfile,
        ),
        IconButton(
          tooltip: 'Wishlist',
          icon: Badge(
            backgroundColor: orange,
            isLabelVisible: widget.wishlist.isNotEmpty,
            label: Text('${widget.wishlist.length}'),
            child: const Icon(Icons.favorite_border),
          ),
          onPressed: openWishlist,
        ),
        IconButton(
          tooltip: 'Cart',
          icon: Badge(
            backgroundColor: orange,
            isLabelVisible: widget.cartCount > 0,
            label: Text('${widget.cartCount}'),
            child: const Icon(Icons.shopping_bag_outlined),
          ),
          onPressed: openCart,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget hero() {
    return Container(
      constraints: const BoxConstraints(minHeight: 280),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        image: const DecorationImage(
          image: AssetImage('assets/images/bg.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(30, 30, 30, 30),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              navyDeep.withValues(alpha: 0.94),
              navyDeep.withValues(alpha: 0.72),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'NEW ARRIVALS WEEKLY',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Technology that\nmoves with you.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                height: 1.08,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Discover the latest phones, laptops, gadgets, and accessories — all in one place.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.82),
                fontSize: 14.5,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: orange,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
              onPressed: scrollToCatalog,
              icon: const Icon(Icons.storefront_outlined, size: 19),
              label: const Text('Shop'),
            ),
          ],
        ),
      ),
    );
  }

  Widget searchBar() {
    return TextField(
      onChanged: (value) => setState(() => query = value),
      style: const TextStyle(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: 'Search products, brands, and categories',
        prefixIcon: const Icon(Icons.search, color: mutedText),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: lineColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: lineColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: navy, width: 1.6),
        ),
      ),
    );
  }

  Widget filters() {
    return Card(
      color: Colors.white,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CATEGORY',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((category) {
                final selected = selectedCategory == category;
                return ChoiceChip(
                  label: Text(category),
                  selected: selected,
                  showCheckmark: false,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : navyDeep,
                  ),
                  onSelected: (_) =>
                      setState(() => selectedCategory = category),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            const Divider(height: 1),
            const SizedBox(height: 18),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                DropdownMenu<String>(
                  label: const Text('Brand'),
                  initialSelection: selectedBrand,
                  dropdownMenuEntries: brands
                      .map(
                        (brand) =>
                            DropdownMenuEntry(value: brand, label: brand),
                      )
                      .toList(),
                  onSelected: (value) {
                    if (value != null) setState(() => selectedBrand = value);
                  },
                ),
                DropdownMenu<double>(
                  label: const Text('Rating'),
                  initialSelection: minimumRating,
                  dropdownMenuEntries: const [
                    DropdownMenuEntry(value: 0, label: 'Any'),
                    DropdownMenuEntry(value: 4.0, label: '4.0+'),
                    DropdownMenuEntry(value: 4.5, label: '4.5+'),
                    DropdownMenuEntry(value: 4.8, label: '4.8+'),
                  ],
                  onSelected: (value) {
                    if (value != null) setState(() => minimumRating = value);
                  },
                ),
                SizedBox(
                  width: 330,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PRICE RANGE',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      Text(
                        'BDT ${priceRange.start.toStringAsFixed(0)} — BDT ${priceRange.end.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: navyDeep,
                        ),
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: navy,
                          inactiveTrackColor: lineColor,
                          thumbColor: navy,
                          overlayColor: navy.withValues(alpha: 0.1),
                        ),
                        child: RangeSlider(
                          min: 0,
                          max: 250000,
                          divisions: 25,
                          values: priceRange,
                          onChanged: (value) =>
                              setState(() => priceRange = value),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget grid() {
    if (productsLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Center(
          child: Column(
            children: [
              Icon(
                productLoadError.isNotEmpty
                    ? Icons.wifi_off_rounded
                    : Icons.search_off_rounded,
                size: 44,
                color: mutedText.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 14),
              Text(
                productLoadError.isNotEmpty
                    ? 'Could not load products'
                    : 'No products found',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: navyDeep,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                productLoadError.isNotEmpty
                    ? productLoadError
                    : 'Clear your search or filters and try again.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: mutedText),
              ),
            ],
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 1000
            ? 4
            : constraints.maxWidth > 700
            ? 3
            : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filtered.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.58,
          ),
          itemBuilder: (_, index) {
            final item = filtered[index];
            return ProductCard(
              product: item,
              isWishlisted: widget.wishlist.contains(item),
              onOpen: () => openProduct(item),
              onAdd: () async {
                final user = await requireLogin(
                  'Please login or register to add items to cart.',
                );
                if (user != null) {
                  await widget.onAddToCart(item);
                  setState(() {});
                }
              },
              onFavorite: () async {
                final user = await requireLogin(
                  'Please login or register to use wishlist.',
                );
                if (user != null) {
                  widget.onToggleWishlist(item);
                  setState(() {});
                }
              },
            );
          },
        );
      },
    );
  }

  void openProduct(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailPage(
          product: product,
          currentUser: widget.currentUser,
          cart: widget.cart,
          cartCount: widget.cartCount,
          wishlist: widget.wishlist,
          orders: widget.orders,
          onLogin: widget.onLogin,
          onLogout: widget.onLogout,
          onAddToCart: widget.onAddToCart,
          onToggleWishlist: widget.onToggleWishlist,
          onUpdateQuantity: widget.onUpdateQuantity,
          onPlaceOrder: widget.onPlaceOrder,
        ),
      ),
    ).then((_) => setState(() {}));
  }

  Future<void> openProfile() async {
    final user = await requireLogin(
      'Please login or register to view your profile.',
    );
    if (user == null || !mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfilePage(
          user: user,
          orders: widget.orders,
          onLogout: widget.onLogout,
        ),
      ),
    );
  }

  Future<void> openWishlist() async {
    final user = await requireLogin(
      'Please login or register to view wishlist.',
    );
    if (user == null || !mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WishlistPage(
          wishlist: widget.wishlist,
          onAddToCart: widget.onAddToCart,
          onToggleWishlist: widget.onToggleWishlist,
        ),
      ),
    ).then((_) => setState(() {}));
  }

  Future<void> openCart() async {
    final user = await requireLogin('Please login or register to view cart.');
    if (user == null || !mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CartPage(
          cart: widget.cart,
          currentUser: user,
          onUpdateQuantity: widget.onUpdateQuantity,
          onPlaceOrder: widget.onPlaceOrder,
        ),
      ),
    ).then((_) => setState(() {}));
  }
}

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.isWishlisted,
    required this.onOpen,
    required this.onAdd,
    required this.onFavorite,
  });

  final Product product;
  final bool isWishlisted;
  final VoidCallback onOpen;
  final VoidCallback onAdd;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final outOfStock = product.stock <= 0;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: lineColor),
      ),
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 210,
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surfaceTint,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Opacity(
                        opacity: outOfStock ? 0.45 : 1,
                        child: productImage(
                          product.image,
                          height: 180,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    if (outOfStock)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: _tag('Out of stock', dangerColor, dangerSoft),
                      )
                    else if (product.stock <= 5)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: _tag('Only ${product.stock} left', orange, orangeSoft),
                      ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        elevation: 1,
                        shadowColor: Colors.black26,
                        child: IconButton(
                          onPressed: onFavorite,
                          icon: Icon(
                            isWishlisted
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: isWishlisted ? dangerColor : navyDeep,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      product.brand.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: mutedText,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  const Icon(Icons.star_rounded, color: Color(0xFFF5A524), size: 16),
                  const SizedBox(width: 2),
                  Text(
                    product.rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: navyDeep,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: navyDeep,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'BDT ${product.price.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: priceBlue,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: outOfStock ? null : onAdd,
                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 17),
                  label: Text(outOfStock ? 'Out of stock' : 'Add to cart'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tag(String label, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }
}

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({
    super.key,
    required this.product,
    required this.currentUser,
    required this.cart,
    required this.cartCount,
    required this.wishlist,
    required this.orders,
    required this.onLogin,
    required this.onLogout,
    required this.onAddToCart,
    required this.onToggleWishlist,
    required this.onUpdateQuantity,
    required this.onPlaceOrder,
  });

  final Product product;
  final UserAccount? currentUser;
  final List<CartLine> cart;
  final int cartCount;
  final Set<Product> wishlist;
  final List<OrderRecord> orders;
  final Future<void> Function(UserAccount user) onLogin;
  final Future<void> Function() onLogout;
  final Future<void> Function(Product product) onAddToCart;
  final ValueChanged<Product> onToggleWishlist;
  final void Function(CartLine line, int quantity) onUpdateQuantity;
  final Future<OrderRecord?> Function({
    required String fullName,
    required String phone,
    required String email,
    required String address,
    required String paymentMethod,
  })
  onPlaceOrder;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  Future<UserAccount?> requireLogin(String message) async {
    if (widget.currentUser != null) return widget.currentUser;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    final user = await Navigator.push<UserAccount>(
      context,
      MaterialPageRoute(builder: (_) => const AuthPage()),
    );
    if (user != null) {
      await widget.onLogin(user);
      return user;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final wishlisted = widget.wishlist.contains(widget.product);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () async {
              final user = await requireLogin(
                'Please login or register to view profile.',
              );
              if (user == null || !context.mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfilePage(
                    user: user,
                    orders: widget.orders,
                    onLogout: widget.onLogout,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: Badge(
              label: Text('${widget.wishlist.length}'),
              child: const Icon(Icons.favorite_border),
            ),
            onPressed: () async {
              final user = await requireLogin(
                'Please login or register to use wishlist.',
              );
              if (user != null) {
                widget.onToggleWishlist(widget.product);
                setState(() {});
              }
            },
          ),
          IconButton(
            icon: Badge(
              label: Text('${widget.cartCount}'),
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            onPressed: () async {
              final user = await requireLogin(
                'Please login or register to view cart.',
              );
              if (user == null || !context.mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CartPage(
                    cart: widget.cart,
                    currentUser: user,
                    onUpdateQuantity: widget.onUpdateQuantity,
                    onPlaceOrder: widget.onPlaceOrder,
                  ),
                ),
              ).then((_) => setState(() {}));
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final image = Container(
                    height: 340,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: surfaceTint,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: lineColor),
                    ),
                    child: productImage(
                      widget.product.image,
                      fit: BoxFit.contain,
                    ),
                  );
                  final details = productInfo(wishlisted);
                  if (constraints.maxWidth > 720) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: image),
                        const SizedBox(width: 24),
                        Expanded(child: details),
                      ],
                    );
                  }
                  return Column(
                    children: [image, const SizedBox(height: 20), details],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          specsCard(),
          const SizedBox(height: 18),
          returnHomeButton(context),
        ],
      ),
    );
  }

  Widget productInfo(bool wishlisted) {
    final outOfStock = widget.product.stock <= 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: orangeSoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.product.brand.toUpperCase(),
            style: const TextStyle(
              color: orange,
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 0.4,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          widget.product.name,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.star_rounded, color: Color(0xFFF5A524), size: 20),
            const SizedBox(width: 4),
            Text(
              '${widget.product.rating}',
              style: const TextStyle(fontWeight: FontWeight.w700, color: navyDeep),
            ),
            const SizedBox(width: 12),
            Container(width: 1, height: 14, color: lineColor),
            const SizedBox(width: 12),
            Icon(
              outOfStock ? Icons.error_outline : Icons.check_circle_outline,
              size: 16,
              color: outOfStock ? dangerColor : successColor,
            ),
            const SizedBox(width: 4),
            Text(
              outOfStock ? 'Out of stock' : '${widget.product.stock} in stock',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: outOfStock ? dangerColor : successColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          widget.product.description,
          style: const TextStyle(fontSize: 15.5, height: 1.6, color: mutedText),
        ),
        const SizedBox(height: 20),
        Text(
          'BDT ${widget.product.price.toStringAsFixed(0)}',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            color: priceBlue,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: outOfStock
                    ? null
                    : () async {
                        final user = await requireLogin(
                          'Please login or register to add items to cart.',
                        );
                        if (user != null) {
                          await widget.onAddToCart(widget.product);
                          setState(() {});
                        }
                      },
                icon: const Icon(Icons.shopping_bag_outlined),
                label: Text(outOfStock ? 'Out of stock' : 'Add to cart'),
              ),
            ),
            const SizedBox(width: 12),
            IconButton.filledTonal(
              style: IconButton.styleFrom(
                backgroundColor: wishlisted ? dangerSoft : surfaceTint,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () async {
                final user = await requireLogin(
                  'Please login or register to use wishlist.',
                );
                if (user != null) {
                  widget.onToggleWishlist(widget.product);
                  setState(() {});
                }
              },
              icon: Icon(
                wishlisted ? Icons.favorite : Icons.favorite_border,
                color: wishlisted ? dangerColor : navyDeep,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget specsCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Product details',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: navyDeep),
            ),
            const SizedBox(height: 4),
            const Divider(height: 24),
            ...widget.product.details.map(
              (detail) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 17,
                        color: successColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        detail,
                        style: const TextStyle(fontSize: 15.5, height: 1.4, color: Color(0xFF1F2937)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WishlistPage extends StatelessWidget {
  const WishlistPage({
    super.key,
    required this.wishlist,
    required this.onAddToCart,
    required this.onToggleWishlist,
  });

  final Set<Product> wishlist;
  final Future<void> Function(Product product) onAddToCart;
  final ValueChanged<Product> onToggleWishlist;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wishlist')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (wishlist.isEmpty)
            emptyState(
              icon: Icons.favorite_border,
              title: 'Your wishlist is empty',
              subtitle: 'Tap the heart on any product to save it here.',
            )
          else
            ...wishlist.map(
              (item) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: surfaceTint,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: productImage(
                          item.image,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700, color: navyDeep),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'BDT ${item.price.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.w800, color: priceBlue),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Add to cart',
                        icon: const Icon(Icons.add_shopping_cart_rounded),
                        onPressed: () async {
                          await onAddToCart(item);
                        },
                      ),
                      IconButton(
                        tooltip: 'Remove',
                        icon: const Icon(Icons.delete_outline, color: dangerColor),
                        onPressed: () => onToggleWishlist(item),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          returnHomeButton(context),
        ],
      ),
    );
  }
}

class CartPage extends StatefulWidget {
  const CartPage({
    super.key,
    required this.cart,
    required this.currentUser,
    required this.onUpdateQuantity,
    required this.onPlaceOrder,
  });

  final List<CartLine> cart;
  final UserAccount currentUser;
  final void Function(CartLine line, int quantity) onUpdateQuantity;
  final Future<OrderRecord?> Function({
    required String fullName,
    required String phone,
    required String email,
    required String address,
    required String paymentMethod,
  })
  onPlaceOrder;

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  double get total => widget.cart.fold(0, (sum, item) => sum + item.subtotal);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cart details')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (widget.cart.isEmpty)
                emptyState(
                  icon: Icons.shopping_bag_outlined,
                  title: 'Your cart is empty',
                  subtitle: 'Browse the catalog and add something you like.',
                )
              else ...[
                ...widget.cart.map(cartItem),
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  color: navyDeep,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const Text(
                          'Order total',
                          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Text(
                          'BDT ${total.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CheckoutPage(
                          cart: widget.cart,
                          currentUser: widget.currentUser,
                          total: total,
                          onPlaceOrder: widget.onPlaceOrder,
                        ),
                      ),
                    ).then((_) => setState(() {})),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text('Proceed to checkout'),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              returnHomeButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget cartItem(CartLine item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 64,
              height: 64,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: surfaceTint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: productImage(item.product.image, fit: BoxFit.contain),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, color: navyDeep),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.product.brand,
                    style: const TextStyle(fontSize: 12.5, color: mutedText),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      quantityStepper(item),
                      const Spacer(),
                      Text(
                        'BDT ${item.subtotal.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: priceBlue,
                          fontSize: 15.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget quantityStepper(CartLine item) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceTint,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepperButton(
            Icons.remove,
            () {
              widget.onUpdateQuantity(item, item.quantity - 1);
              setState(() {});
            },
          ),
          SizedBox(
            width: 26,
            child: Text(
              '${item.quantity}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, color: navyDeep),
            ),
          ),
          _stepperButton(
            Icons.add,
            () {
              widget.onUpdateQuantity(item, item.quantity + 1);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _stepperButton(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 16, color: navyDeep),
      ),
    );
  }
}

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({
    super.key,
    required this.cart,
    required this.currentUser,
    required this.total,
    required this.onPlaceOrder,
  });

  final List<CartLine> cart;
  final UserAccount currentUser;
  final double total;
  final Future<OrderRecord?> Function({
    required String fullName,
    required String phone,
    required String email,
    required String address,
    required String paymentMethod,
  })
  onPlaceOrder;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController fullName;
  late final TextEditingController phone;
  late final TextEditingController email;
  final address = TextEditingController();
  String paymentMethod = 'Cash on Delivery';

  @override
  void initState() {
    super.initState();
    fullName = TextEditingController(text: widget.currentUser.name);
    phone = TextEditingController(text: widget.currentUser.phone);
    email = TextEditingController(text: widget.currentUser.email);
  }

  @override
  void dispose() {
    fullName.dispose();
    phone.dispose();
    email.dispose();
    address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Form(
            key: formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Checkout information',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: priceBlueSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Order total',
                        style: TextStyle(fontWeight: FontWeight.w600, color: navyDeep),
                      ),
                      const Spacer(),
                      Text(
                        'BDT ${widget.total.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          color: priceBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('SHIPPING DETAILS', style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 12),
                field(fullName, 'Full name'),
                field(phone, 'Phone number'),
                field(email, 'Email'),
                TextFormField(
                  controller: address,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Shipping address',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'This field is required'
                      : null,
                ),
                const SizedBox(height: 16),
                Text('PAYMENT', style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: paymentMethod,
                  decoration: const InputDecoration(
                    labelText: 'Payment method',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Cash on Delivery',
                      child: Text('Cash on Delivery'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => paymentMethod = value);
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: placeOrder,
                    icon: const Icon(Icons.lock_outline_rounded, size: 18),
                    label: const Text('Place order'),
                  ),
                ),
                const SizedBox(height: 18),
                returnHomeButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget field(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        validator: (value) => value == null || value.trim().isEmpty
            ? 'This field is required'
            : null,
      ),
    );
  }

  String? requiredField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  Future<void> placeOrder() async {
    if (!formKey.currentState!.validate()) return;

    try {
      final order = await widget.onPlaceOrder(
        fullName: fullName.text.trim(),
        phone: phone.text.trim(),
        email: email.text.trim(),
        address: address.text.trim(),
        paymentMethod: paymentMethod,
      );

      if (order == null || !mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => InvoicePage(order: order)),
      );
    } catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

class InvoicePage extends StatelessWidget {
  const InvoicePage({super.key, required this.order});

  final OrderRecord order;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invoice')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: successSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: successColor, size: 44),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Order successfully placed',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: navyDeep),
              ),
              const SizedBox(height: 6),
              Text(
                'Invoice ${order.id}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: mutedText, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),
              Card(
                color: Colors.white,
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OrderTrackingBar(status: order.status),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 12),
                      Text('DELIVERY DETAILS', style: Theme.of(context).textTheme.labelSmall),
                      const SizedBox(height: 10),
                      invoiceRow('Customer', order.fullName),
                      invoiceRow('Phone', order.phone),
                      invoiceRow('Email', order.email),
                      invoiceRow('Address', order.address),
                      invoiceRow('Payment', order.paymentMethod),
                      const SizedBox(height: 8),
                      const Divider(height: 28),
                      Text('ITEMS', style: Theme.of(context).textTheme.labelSmall),
                      const SizedBox(height: 4),
                      ...order.items.map(
                        (item) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 46,
                            height: 46,
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: surfaceTint,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: productImage(
                              item.product.image,
                              fit: BoxFit.contain,
                            ),
                          ),
                          title: Text(
                            item.product.name,
                            style: const TextStyle(fontWeight: FontWeight.w700, color: navyDeep),
                          ),
                          subtitle: Text(
                            'Qty ${item.quantity} · BDT ${item.product.price.toStringAsFixed(0)}',
                          ),
                          trailing: Text(
                            'BDT ${item.subtotal.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.w700, color: navyDeep),
                          ),
                        ),
                      ),
                      const Divider(height: 28),
                      Row(
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(fontWeight: FontWeight.w600, color: mutedText),
                          ),
                          const Spacer(),
                          Text(
                            'BDT ${order.total.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              color: priceBlue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              returnHomeButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget invoiceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: const TextStyle(color: mutedText, fontSize: 13.5),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, color: navyDeep),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.user,
    required this.orders,
    required this.onLogout,
  });

  final UserAccount user;
  final List<OrderRecord> orders;
  final Future<void> Function() onLogout;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool loadingOrders = true;
  String orderError = '';
  List<OrderRecord> backendOrders = [];

  @override
  void initState() {
    super.initState();
    loadOrders();
  }

  Future<void> loadOrders() async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/orders/'),
        headers: {'Authorization': 'Bearer ${widget.user.accessToken}'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;

        setState(() {
          backendOrders = data
              .map((item) => OrderRecord.fromJson(item as Map<String, dynamic>))
              .toList();
          loadingOrders = false;
          orderError = '';
        });
      } else {
        setState(() {
          loadingOrders = false;
          orderError = 'Could not load orders.';
        });
      }
    } catch (error) {
      setState(() {
        loadingOrders = false;
        orderError = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayedOrders = backendOrders.isNotEmpty
        ? backendOrders
        : widget.orders;

    return Scaffold(
      appBar: AppBar(title: const Text('User profile')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: navy,
                        child: Text(
                          widget.user.name.isNotEmpty
                              ? widget.user.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.user.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                                color: navyDeep,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(widget.user.email, style: const TextStyle(color: mutedText)),
                            Text(widget.user.phone, style: const TextStyle(color: mutedText)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('PREVIOUS ORDERS', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 12),

              if (loadingOrders)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (orderError.isNotEmpty)
                Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Text(orderError, style: const TextStyle(color: dangerColor)),
                  ),
                )
              else if (displayedOrders.isEmpty)
                emptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No previous orders yet',
                  subtitle: 'Orders you place will show up here.',
                )
              else
                ...displayedOrders.map(
                  (order) => Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  order.id,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: navyDeep,
                                  ),
                                ),
                              ),
                              Text(
                                'BDT ${order.total.toStringAsFixed(0)}',
                                style: const TextStyle(fontWeight: FontWeight.w800, color: priceBlue),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${order.items.length} item(s)',
                            style: const TextStyle(color: mutedText, fontSize: 13.5),
                          ),
                          const SizedBox(height: 16),
                          OrderTrackingBar(status: order.status),
                        ],
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () async {
                  await widget.onLogout();
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: dangerColor,
                  side: const BorderSide(color: dangerSoft, width: 1.4),
                ),
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Logout'),
              ),
              const SizedBox(height: 12),
              returnHomeButton(context),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final emailOrPhone = TextEditingController();
  final phone = TextEditingController();
  final password = TextEditingController();
  bool register = false;

  @override
  void dispose() {
    name.dispose();
    emailOrPhone.dispose();
    phone.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(register ? 'Create account' : 'Login')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Form(
            key: formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Container(
                  height: 52,
                  width: 52,
                  decoration: BoxDecoration(
                    color: navy,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 18),
                Text(
                  register ? 'Create your account' : 'Welcome back',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  register
                      ? 'Join ElectroMart for wishlist, cart, and order tracking.'
                      : 'Log in to continue shopping.',
                  style: const TextStyle(color: mutedText),
                ),
                const SizedBox(height: 26),
                if (register) field(name, 'Full name'),
                field(emailOrPhone, register ? 'Email' : 'Email or phone'),
                if (register) field(phone, 'Phone number'),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextFormField(
                    controller: password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'This field is required'
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: submit,
                    child: Text(register ? 'Register' : 'Login'),
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => setState(() => register = !register),
                  child: Text(
                    register
                        ? 'Already have an account? Login'
                        : 'New customer? Create an account',
                  ),
                ),
                const SizedBox(height: 8),
                returnHomeButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget field(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        validator: (value) => value == null || value.trim().isEmpty
            ? 'This field is required'
            : null,
      ),
    );
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;

    final emailOrPhoneValue = emailOrPhone.text.trim();
    final passwordValue = password.text.trim();

    try {
      if (register) {
        final fullName = name.text.trim();
        final phoneValue = phone.text.trim();
        final emailValue = emailOrPhoneValue;

        final registerResponse = await http.post(
          Uri.parse('$apiBaseUrl/auth/register/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': phoneValue,
            'email': emailValue,
            'first_name': fullName,
            'last_name': '',
            'password': passwordValue,
            'password_confirm': passwordValue,
          }),
        );

        if (registerResponse.statusCode != 201) {
          throw Exception('Registration failed: ${registerResponse.body}');
        }

        final loginResponse = await http.post(
          Uri.parse('$apiBaseUrl/auth/login/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'username': phoneValue, 'password': passwordValue}),
        );

        if (loginResponse.statusCode != 200) {
          throw Exception(
            'Login after registration failed: ${loginResponse.body}',
          );
        }

        final tokenData = jsonDecode(loginResponse.body);

        if (!mounted) return;
        Navigator.pop(
          context,
          UserAccount(
            name: fullName,
            email: emailValue,
            phone: phoneValue,
            accessToken: tokenData['access'],
            refreshToken: tokenData['refresh'],
          ),
        );
      } else {
        final loginResponse = await http.post(
          Uri.parse('$apiBaseUrl/auth/login/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': emailOrPhoneValue,
            'password': passwordValue,
          }),
        );

        if (loginResponse.statusCode != 200) {
          throw Exception('Login failed: ${loginResponse.body}');
        }

        final tokenData = jsonDecode(loginResponse.body);

        final profileResponse = await http.get(
          Uri.parse('$apiBaseUrl/auth/profile/'),
          headers: {'Authorization': 'Bearer ${tokenData['access']}'},
        );

        if (profileResponse.statusCode != 200) {
          throw Exception('Profile loading failed: ${profileResponse.body}');
        }

        final profileData = jsonDecode(profileResponse.body);

        if (!mounted) return;
        Navigator.pop(
          context,
          UserAccount(
            name: profileData['first_name'] ?? 'ElectroMart Customer',
            email: profileData['email'] ?? '',
            phone: profileData['username'] ?? emailOrPhoneValue,
            accessToken: tokenData['access'],
            refreshToken: tokenData['refresh'],
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'About ElectroMart',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 14),
              const Text(
                'ElectroMart is an electronics e-commerce shop for phones, laptops, tablets, TVs, accessories, gaming products, audio devices, and smart gadgets. Guests can browse products freely, while registered customers can use wishlist, cart, checkout, invoices, and order tracking.',
                style: TextStyle(fontSize: 15.5, height: 1.6, color: mutedText),
              ),
              const SizedBox(height: 22),
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'What we offer',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: navyDeep),
                      ),
                      const SizedBox(height: 14),
                      featureRow(Icons.grid_view_rounded, 'Electronics catalog with search and filters'),
                      featureRow(Icons.shopping_bag_outlined, 'Cart, wishlist, checkout, and invoices'),
                      featureRow(Icons.payments_outlined, 'Cash on Delivery purchase flow'),
                      featureRow(Icons.local_shipping_outlined, 'Live order tracking and history'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              returnHomeButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget featureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: orangeSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: orange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(text, style: const TextStyle(fontSize: 14.5, color: Color(0xFF1F2937))),
            ),
          ),
        ],
      ),
    );
  }
}

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Contact us',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              const Text(
                "We're happy to help with orders, products, or anything else.",
                style: TextStyle(color: mutedText, fontSize: 15),
              ),
              const SizedBox(height: 22),
              contactTile(Icons.phone_outlined, '+880 1700-000000', 'Customer support'),
              contactTile(Icons.email_outlined, 'support@electromart.com', 'Email support'),
              contactTile(Icons.location_on_outlined, 'Dhaka, Bangladesh', 'ElectroMart office location'),
              const SizedBox(height: 12),
              returnHomeButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget contactTile(IconData icon, String title, String subtitle) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: priceBlueSoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: navy, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: navyDeep)),
        subtitle: Text(subtitle),
      ),
    );
  }
}

Widget productImage(
  String image, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.contain,
}) {
  final isNetworkImage =
      image.startsWith('http://') || image.startsWith('https://');

  if (isNetworkImage) {
    return Image.network(
      image,
      width: width,
      height: height,
      fit: fit,
      alignment: Alignment.center,
      errorBuilder: (_, _, _) =>
          const Icon(Icons.image_not_supported, size: 54),
    );
  }

  return Image.asset(
    image,
    width: width,
    height: height,
    fit: fit,
    alignment: Alignment.center,
    errorBuilder: (_, _, _) => const Icon(Icons.image_not_supported, size: 54),
  );
}

class OrderTrackingBar extends StatelessWidget {
  const OrderTrackingBar({super.key, required this.status});

  final String status;

  int get currentStep {
    switch (status) {
      case 'confirmed':
        return 0;
      case 'processing':
        return 1;
      case 'shipped':
        return 2;
      case 'in_transit':
        return 3;
      case 'delivered':
        return 4;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    const steps = [
      'Ordered',
      'Processing',
      'Shipped',
      'In Transit',
      'Delivered',
    ];

    return Row(
      children: List.generate(steps.length, (index) {
        final active = index <= currentStep;
        final current = index == currentStep;

        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  if (index != 0)
                    Expanded(
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: active ? successColor : lineColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  Container(
                    width: current ? 26 : 22,
                    height: current ? 26 : 22,
                    decoration: BoxDecoration(
                      color: active ? successColor : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: active ? successColor : lineColor,
                        width: 1.6,
                      ),
                      boxShadow: current
                          ? [
                              BoxShadow(
                                color: successColor.withValues(alpha: 0.25),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: active
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                  if (index != steps.length - 1)
                    Expanded(
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: index < currentStep ? successColor : lineColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                steps[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: current ? FontWeight.w800 : FontWeight.w600,
                  color: active ? navyDeep : mutedText,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

Widget emptyState({
  required IconData icon,
  required String title,
  required String subtitle,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 40),
    child: Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: surfaceTint,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: mutedText),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: navyDeep,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: mutedText),
          ),
        ],
      ),
    ),
  );
}

Widget returnHomeButton(BuildContext context) {
  return Center(
    child: OutlinedButton.icon(
      onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
      icon: const Icon(Icons.home_outlined, size: 18),
      label: const Text('Return to home'),
    ),
  );
}