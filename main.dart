import 'package:flutter/material.dart';

const navy = Color(0xFF071D49);
const orange = Color(0xFFFF6B18);

void main() => runApp(const ElectroMartApp());

class ElectroMartApp extends StatefulWidget {
  const ElectroMartApp({super.key});

  @override
  State<ElectroMartApp> createState() => _ElectroMartAppState();
}

class _ElectroMartAppState extends State<ElectroMartApp> {
  final cart = <CartLine>[];
  final wishlist = <Product>{};

  void addToCart(Product product) {
    final lineIndex = cart.indexWhere((line) => line.product.id == product.id);
    setState(() {
      if (lineIndex == -1) {
        cart.add(CartLine(product: product));
      } else {
        cart[lineIndex].quantity++;
      }
    });
  }

  void toggleWishlist(Product product) => setState(() {
    wishlist.contains(product)
        ? wishlist.remove(product)
        : wishlist.add(product);
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ElectroMart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF155EEF)),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        useMaterial3: true,
      ),
      home: HomePage(
        cart: cart,
        wishlist: wishlist,
        addToCart: addToCart,
        toggleWishlist: toggleWishlist,
      ),
    );
  }
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.description,
    required this.price,
    required this.rating,
    required this.stock,
    required this.icon,
    required this.color,
  });

  final int id;
  final String name, brand, category, description;
  final double price, rating;
  final int stock;
  final IconData icon;
  final Color color;

  String get image => _productImage(id);
}

String _productImage(int id) {
  const images = [
    'assets/images/iphone.webp',
    'assets/images/iPhone-15-Pro-Max.jpg',
    'assets/images/Samsung-Galaxy-A73-5G.webp',
    'assets/images/Google-Pixel-8a.webp',
    'assets/images/iphone.webp',
    'assets/images/iPad-pro-m4.jpg',
    'assets/images/samsung tab.webp',
    'assets/images/Huawei-MatePad.webp',
    'assets/images/tablet.jpg',
    'assets/images/iPad-pro-m4.jpg',
    'assets/images/apple macbook.jpg',
    'assets/images/lenovo.webp',
    'assets/images/lenovo-pro-5.webp',
    'assets/images/laptop.jpg',
    'assets/images/apple macbook.jpg',
    'assets/images/background.jpg',
    'assets/images/bg.jpg',
    'assets/images/bgimg.jpg',
    'assets/images/background.jpg',
    'assets/images/bg.jpg',
    'assets/images/airpod1.webp',
    'assets/images/airpods.jpg',
    'assets/images/airpod2.webp',
    'assets/images/anker.webp',
    'assets/images/Baseus.webp',
    'assets/images/pb1.png',
    'assets/images/pb2.jpg',
    'assets/images/pb3.webp',
    'assets/images/bg.jpg',
    'assets/images/background.jpg',
    'assets/images/background.jpg',
    'assets/images/bg.jpg',
    'assets/images/bgimg.jpg',
    'assets/images/background.jpg',
    'assets/images/bg.jpg',
    'assets/images/bgimg.jpg',
    'assets/images/background.jpg',
    'assets/images/bg.jpg',
    'assets/images/bgimg.jpg',
    'assets/images/background.jpg',
    'assets/images/airpod1.webp',
    'assets/images/airpods.jpg',
    'assets/images/airpod2.webp',
    'assets/images/anker.webp',
    'assets/images/Samsung-Galaxy-Buds.png',
    'assets/images/pb1.png',
    'assets/images/pb3.webp',
    'assets/images/bg.jpg',
    'assets/images/bgimg.jpg',
    'assets/images/background.jpg',
  ];
  return images[(id - 1) % images.length];
}

class CartLine {
  CartLine({required this.product, this.quantity = 1});
  final Product product;
  int quantity;
}

final List<Product> products = _buildProducts();

List<Product> _buildProducts() {
  const catalog = [
    _CatalogGroup(
      'Phones',
      'Samsung',
      Icons.phone_android_rounded,
      Color(0xFFE8F1FF),
      'A capable smartphone with a sharp display and reliable battery.',
      [
        'Galaxy S24 Ultra',
        'Galaxy S24+',
        'Galaxy A55',
        'Galaxy Z Fold6',
        'Galaxy Z Flip6',
        'Galaxy S23 FE',
        'Galaxy A35',
        'Galaxy M55',
        'Galaxy A25',
        'Galaxy S24',
      ],
      299,
    ),
    _CatalogGroup(
      'Tablets',
      'Apple',
      Icons.tablet_mac_rounded,
      Color(0xFFFFF4D8),
      'A versatile tablet for notes, entertainment, and creative work.',
      [
        'iPad Air',
        'iPad Pro 11',
        'iPad Pro 13',
        'iPad 10th Gen',
        'iPad Mini',
        'Galaxy Tab S9',
        'Galaxy Tab A9+',
        'Lenovo Tab P12',
        'Xiaomi Pad 6',
        'OnePlus Pad',
      ],
      249,
    ),
    _CatalogGroup(
      'Laptops',
      'Dell',
      Icons.laptop_mac_rounded,
      Color(0xFFFFEDE4),
      'A dependable laptop for study, work, and creativity.',
      [
        'MacBook Air M3',
        'Dell XPS 13',
        'HP Pavilion 15',
        'Lenovo IdeaPad Slim',
        'ASUS Zenbook 14',
        'Acer Aspire 5',
        'MacBook Pro 14',
        'MSI Modern 15',
        'HP Envy x360',
        'Lenovo ThinkPad E14',
      ],
      549,
    ),
    _CatalogGroup(
      'TVs',
      'LG',
      Icons.tv_rounded,
      Color(0xFFE5F8EE),
      'A smart television with a bright 4K picture and streaming apps.',
      [
        'LG OLED Smart TV',
        'Samsung QLED Q80',
        'Sony Bravia X90L',
        'TCL C755',
        'Hisense U7K',
        'LG NanoCell 4K',
        'Samsung Crystal UHD',
        'Xiaomi TV A Pro',
        'Sony Bravia X75K',
        'TCL P635',
      ],
      399,
    ),
    _CatalogGroup(
      'Accessories',
      'Logitech',
      Icons.headphones_rounded,
      Color(0xFFF0E8FF),
      'A quality accessory that makes your technology easier to use.',
      [
        'AirPods 3rd Generation',
        'AirPods Pro',
        'Baseus Wireless Earbuds',
        'Soundcore Earbuds',
        'Samsung Galaxy Buds',
        'JBL Power Bank',
        'Anker PowerCore',
        'Gaming Keyboard',
        'Gaming Controller & Mousepad',
        'Logitech Wireless Mouse',
      ],
      29,
    ),
  ];
  var id = 1;
  return [
    for (final group in catalog)
      for (var index = 0; index < group.names.length; index++)
        Product(
          id: id++,
          name: group.names[index],
          brand: group.brand,
          category: group.category,
          description: group.description,
          price: group.basePrice + (index * 75.0),
          rating: 4.1 + ((index % 5) * 0.2),
          stock: 5 + (index * 3),
          icon: group.icon,
          color: group.color,
        ),
  ];
}

class _CatalogGroup {
  const _CatalogGroup(
    this.category,
    this.brand,
    this.icon,
    this.color,
    this.description,
    this.names,
    this.basePrice,
  );
  final String category, brand, description;
  final IconData icon;
  final Color color;
  final List<String> names;
  final double basePrice;
}

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.cart,
    required this.wishlist,
    required this.addToCart,
    required this.toggleWishlist,
  });
  final List<CartLine> cart;
  final Set<Product> wishlist;
  final ValueChanged<Product> addToCart, toggleWishlist;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String category = 'All';
  String query = '';

  List<Product> get filtered => products.where((product) {
    final matchesCategory = category == 'All' || product.category == category;
    final text = '${product.name} ${product.brand} ${product.category}'
        .toLowerCase();
    return matchesCategory && text.contains(query.toLowerCase());
  }).toList();

  @override
  Widget build(BuildContext context) {
    const categories = [
      'All',
      'Phones',
      'Laptops',
      'Accessories',
      'TVs',
      'Tablets',
    ];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Image.asset('assets/images/logo web.png', height: 34, width: 34),
            const SizedBox(width: 8),
            const Text(
              'ElectroMart',
              style: TextStyle(color: navy, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Sign in',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AuthPage()),
            ),
          ),
          IconButton(
            icon: Badge(
              label: Text('${widget.wishlist.length}'),
              child: const Icon(Icons.favorite_border),
            ),
            tooltip: 'Wishlist',
            onPressed: () => _showWishlist(),
          ),
          IconButton(
            icon: Badge(
              label: Text(
                '${widget.cart.fold<int>(0, (sum, line) => sum + line.quantity)}',
              ),
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            tooltip: 'Cart',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    CartPage(cart: widget.cart, refresh: () => setState(() {})),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            height: 290,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              image: const DecorationImage(
                image: AssetImage('assets/images/bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: navy.withValues(alpha: .78),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Technology that\nmoves with you.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      height: 1.08,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Discover phones, tablets, laptops, TVs and accessories.',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: () => setState(() => category = 'Phones'),
                    style: FilledButton.styleFrom(backgroundColor: orange),
                    child: const Text('Shop phones'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          TextField(
            onChanged: (value) => setState(() => query = value),
            decoration: InputDecoration(
              hintText: 'Search products, brands, and categories',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, index) => ChoiceChip(
                label: Text(categories[index]),
                selected: category == categories[index],
                onSelected: (_) => setState(() => category = categories[index]),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Catalog',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 950
                  ? 4
                  : constraints.maxWidth > 620
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
                  childAspectRatio: .61,
                ),
                itemBuilder: (_, index) => ProductCard(
                  product: filtered[index],
                  isWishlisted: widget.wishlist.contains(filtered[index]),
                  onAdd: widget.addToCart,
                  onFavorite: widget.toggleWishlist,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showWishlist() => showModalBottomSheet(
    context: context,
    builder: (_) => SizedBox(
      height: 260,
      child: widget.wishlist.isEmpty
          ? const Center(child: Text('Your wishlist is empty.'))
          : ListView(
              children: widget.wishlist
                  .map(
                    (p) => ListTile(
                      leading: Image.asset(
                        p.image,
                        width: 42,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Icon(p.icon),
                      ),
                      title: Text(p.name),
                      subtitle: Text('\$${p.price.toStringAsFixed(2)}'),
                    ),
                  )
                  .toList(),
            ),
    ),
  );
}

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.isWishlisted,
    required this.onAdd,
    required this.onFavorite,
  });
  final Product product;
  final bool isWishlisted;
  final ValueChanged<Product> onAdd, onFavorite;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    child: InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailPage(
            product: product,
            isWishlisted: isWishlisted,
            onAdd: onAdd,
            onFavorite: onFavorite,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: product.color,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Image.asset(
                      product.image,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Icon(product.icon, size: 58),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      onPressed: () => onFavorite(product),
                      icon: Icon(
                        isWishlisted ? Icons.favorite : Icons.favorite_border,
                        color: isWishlisted ? Colors.red : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              product.brand,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 17),
                Text(' ${product.rating}'),
              ],
            ),
            Text(
              '\$${product.price.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Color(0xFF155EEF),
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  onAdd(product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${product.name} added to cart')),
                  );
                },
                child: const Text('Add to cart'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({
    super.key,
    required this.product,
    required this.isWishlisted,
    required this.onAdd,
    required this.onFavorite,
  });
  final Product product;
  final bool isWishlisted;
  final ValueChanged<Product> onAdd, onFavorite;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Product details')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Container(
              height: 260,
              decoration: BoxDecoration(
                color: product.color,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Image.asset(
                product.image,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Icon(product.icon, size: 120),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              product.brand.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF155EEF),
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              product.name,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber),
                Text(' ${product.rating}   •   ${product.stock} in stock'),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              product.description,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 18),
            Text(
              '\$${product.price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Color(0xFF155EEF),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      onAdd(product);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Added to cart.')),
                      );
                    },
                    icon: const Icon(Icons.shopping_bag_outlined),
                    label: const Text('Add to cart'),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filledTonal(
                  onPressed: () => onFavorite(product),
                  icon: Icon(
                    isWishlisted ? Icons.favorite : Icons.favorite_border,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            const Text(
              'Reviews',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const ListTile(
              leading: CircleAvatar(child: Text('S')),
              title: Text('Great product'),
              subtitle: Text('Fast delivery and exactly as described.'),
            ),
          ],
        ),
      ),
    ),
  );
}

class CartPage extends StatefulWidget {
  const CartPage({super.key, required this.cart, required this.refresh});
  final List<CartLine> cart;
  final VoidCallback refresh;

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  double get total => widget.cart.fold(
    0,
    (sum, line) => sum + line.product.price * line.quantity,
  );

  @override
  Widget build(BuildContext context) {
    if (widget.cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Your cart')),
        body: const Center(child: Text('Your cart is empty.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Your cart')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ...widget.cart.map(_cartItem),
          const SizedBox(height: 18),
          Text(
            'Total: \$${total.toStringAsFixed(2)}',
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CheckoutPage(total: total)),
            ),
            child: const Text('Proceed to checkout'),
          ),
        ],
      ),
    );
  }

  Widget _cartItem(CartLine line) => Card(
    child: ListTile(
      leading: Image.asset(
        line.product.image,
        width: 44,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Icon(line.product.icon),
      ),
      title: Text(line.product.name),
      subtitle: Text('\$${line.product.price.toStringAsFixed(2)}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: () => setState(() {
              if (line.quantity > 1) {
                line.quantity--;
              } else {
                widget.cart.remove(line);
              }
              widget.refresh();
            }),
          ),
          Text('${line.quantity}'),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => setState(() {
              line.quantity++;
              widget.refresh();
            }),
          ),
        ],
      ),
    ),
  );
}

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key, required this.total});
  final double total;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final formKey = GlobalKey<FormState>();
  final address = TextEditingController();

  @override
  void dispose() {
    address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Checkout')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Cash on Delivery',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text('Order total: \$${widget.total.toStringAsFixed(2)}'),
              const SizedBox(height: 20),
              TextFormField(
                controller: address,
                maxLines: 3,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a shipping address'
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Shipping address',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OrderConfirmationPage(),
                      ),
                    );
                  }
                },
                child: const Text('Confirm order'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class OrderConfirmationPage extends StatelessWidget {
  const OrderConfirmationPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 16),
            const Text(
              'Order confirmed!',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your order ID is EM-1001. An invoice has been generated.',
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
              child: const Text('Continue shopping'),
            ),
          ],
        ),
      ),
    ),
  );
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool register = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(register ? 'Create account' : 'Sign in')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              register ? 'Create your ElectroMart account' : 'Welcome back',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),
            if (register)
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Full name',
                  border: OutlineInputBorder(),
                ),
              ),
            if (register) const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(register ? 'Register' : 'Login'),
            ),
            TextButton(
              onPressed: () => setState(() => register = !register),
              child: Text(
                register
                    ? 'Already have an account? Login'
                    : 'New customer? Create an account',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
