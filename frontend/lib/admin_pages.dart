import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

final adminApiBaseUrl = kIsWeb
    ? 'http://127.0.0.1:8000/api'
    : 'http://10.0.2.2:8000/api';
const adminNavy = Color(0xFF0E2A5E);
const adminNavyDeep = Color(0xFF081A3D);
const adminOrange = Color(0xFFFF5A1F);
const adminBg = Color(0xFFF5F7FB);
const adminLine = Color(0xFFE6E9F2);
const adminMuted = Color(0xFF667085);
const adminSurfaceTint = Color(0xFFF1F4FA);

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final username = TextEditingController();
  final password = TextEditingController();
  bool loading = false;

  Future<void> login() async {
    setState(() => loading = true);
    try {
      final response = await http.post(
        Uri.parse('$adminApiBaseUrl/auth/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username.text.trim(),
          'password': password.text.trim(),
        }),
      );

      if (response.statusCode != 200) {
        showMessage('Invalid username or password.');
        return;
      }

      final tokenData = jsonDecode(response.body);
      final accessToken = tokenData['access'];
      final dashboardData = await fetchDashboard(accessToken);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AdminDashboardPage(
            accessToken: accessToken,
            initialData: dashboardData,
          ),
        ),
      );
    } catch (error) {
      showMessage('Could not connect to backend. Make sure Django is running.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<Map<String, dynamic>> fetchDashboard(String accessToken) async {
    final response = await http.get(
      Uri.parse('$adminApiBaseUrl/admin/dashboard/'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode != 200) {
      throw Exception('This account is not an admin.');
    }

    return jsonDecode(response.body);
  }

  void showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: adminBg,
      appBar: AppBar(title: const Text('Admin login')),
      body: Center(
        child: SizedBox(
          width: 420,
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: adminLine),
            ),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 46,
                    width: 46,
                    decoration: BoxDecoration(
                      color: adminNavy,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.shield_outlined, color: Colors.white, size: 24),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'ElectroMart Admin',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: adminNavyDeep, letterSpacing: -0.3),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Only staff/admin accounts can enter this dashboard.',
                    style: TextStyle(color: adminMuted),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: username,
                    decoration: const InputDecoration(
                      labelText: 'Admin username',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: adminNavy),
                      onPressed: loading ? null : login,
                      child: Text(loading ? 'Logging in…' : 'Login as admin'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({
    super.key,
    required this.accessToken,
    required this.initialData,
  });

  final String accessToken;
  final Map<String, dynamic> initialData;

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  late Map<String, dynamic> data = widget.initialData;
  int selectedIndex = 0;
  bool loading = false;

  List get products => data['products'] ?? [];
  List get users => data['users'] ?? [];
  List get admins => users.where((user) => user['is_staff'] == true).toList();
  List get customers => users.where((user) => user['is_staff'] != true).toList();
  List get orders => data['orders'] ?? [];
  List get newOrders => orders.where((order) => order['status'] == 'confirmed').toList();

  Future<void> refreshDashboard() async {
    setState(() => loading = true);
    final response = await http.get(
      Uri.parse('$adminApiBaseUrl/admin/dashboard/'),
      headers: {'Authorization': 'Bearer ${widget.accessToken}'},
    );

    if (response.statusCode == 200) {
      setState(() => data = jsonDecode(response.body));
    } else {
      showMessage('Could not refresh dashboard.');
    }
    setState(() => loading = false);
  }

  Future<void> updateOrderStatus(int orderId, String status) async {
    final response = await http.patch(
      Uri.parse('$adminApiBaseUrl/admin/orders/$orderId/status/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.accessToken}',
      },
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode == 200) {
      showMessage('Order updated to $status.');
      await refreshDashboard();
    } else {
      showMessage('Could not update order.');
    }
  }

  void showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      overviewPage(),
      stockPage(),
      ordersPage(),
      usersPage(),
    ];

    return Scaffold(
      backgroundColor: adminBg,
      appBar: AppBar(
        title: const Text('Admin dashboard'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: refreshDashboard,
            icon: loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: Colors.white,
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) => setState(() => selectedIndex = index),
            labelType: NavigationRailLabelType.all,
            useIndicator: true,
            indicatorColor: adminNavy.withValues(alpha: 0.1),
            selectedIconTheme: const IconThemeData(color: adminNavy),
            selectedLabelTextStyle: const TextStyle(color: adminNavy, fontWeight: FontWeight.w700, fontSize: 12.5),
            unselectedLabelTextStyle: const TextStyle(color: adminMuted, fontSize: 12.5),
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Overview')),
              NavigationRailDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: Text('Stock')),
              NavigationRailDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: Text('Orders')),
              NavigationRailDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: Text('Users')),
            ],
          ),
          const VerticalDivider(width: 1, color: adminLine),
          Expanded(child: pages[selectedIndex]),
        ],
      ),
    );
  }

  Widget overviewPage() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        title('Overview'),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            statCard('Total Products', data['total_products'], Icons.inventory_2_outlined),
            statCard('Available Products', data['available_products'], Icons.check_circle_outline),
            statCard('Low Stock', data['low_stock_products'], Icons.warning_amber_outlined),
            statCard('Total Orders', data['total_orders'], Icons.receipt_long_outlined),
            statCard('Confirmed Orders', data['confirmed_orders'], Icons.check_circle_outline),
statCard('Processing', data['processing_orders'], Icons.sync),
statCard('Shipped', data['shipped_orders'], Icons.local_shipping_outlined),
statCard('In Transit', data['in_transit_orders'], Icons.route_outlined),
statCard('Delivered', data['delivered_orders'], Icons.done_all_outlined),
            statCard('Registered Users', data['registered_users'], Icons.people_outline),
            statCard('Revenue', 'BDT ${data['total_revenue']}', Icons.payments_outlined),
          ],
        ),
        const SizedBox(height: 24),
        section('New Orders'),
        newOrders.isEmpty ? emptyText('No new pending orders.') : orderList(newOrders),
      ],
    );
  }

  Widget stockPage() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        title('Products and Stock'),
        dataTable(
          columns: const ['ID', 'Product', 'Brand', 'Category', 'Price', 'Stock', 'Available'],
          rows: products.map((item) => [
            '${item['id']}',
            '${item['name']}',
            '${item['brand']}',
            '${item['category__name']}',
            'BDT ${item['price']}',
            '${item['stock']}',
            item['is_available'] == true ? 'Yes' : 'No',
          ]).toList(),
        ),
      ],
    );
  }

  Widget ordersPage() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        title('Orders'),
        orders.isEmpty ? emptyText('No orders yet.') : orderList(orders),
      ],
    );
  }

  Widget usersPage() {
  return ListView(
    padding: const EdgeInsets.all(20),
    children: [
      title('Users'),
      section('Admins'),
      adminTable(admins),
      const SizedBox(height: 24),
      section('Customers'),
      customerTable(customers),
    ],
  );
}

  Widget orderList(List orderItems) {
    return Column(
      children: orderItems.map((order) {
        final items = order['items'] as List? ?? [];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: adminLine),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Order #${order['id']} — ${order['full_name']}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: adminNavyDeep),
                      ),
                    ),
                    statusChip('${order['status']}'),
                  ],
                ),
                const SizedBox(height: 10),
                Text('Phone: ${order['phone']}', style: const TextStyle(color: adminMuted, fontSize: 13.5)),
                Text('Address: ${order['address']}', style: const TextStyle(color: adminMuted, fontSize: 13.5)),
                Text('Total: BDT ${order['total_amount']}', style: const TextStyle(fontWeight: FontWeight.w700, color: adminNavyDeep, fontSize: 13.5)),
                const SizedBox(height: 6),
                Text(
                  'Items: ${items.map((item) => '${item['product_name']} x ${item['quantity']}').join(', ')}',
                  style: const TextStyle(color: adminMuted, fontSize: 13.5),
                ),
                const SizedBox(height: 14),
                Wrap(
  spacing: 8,
  runSpacing: 8,
  children: [
    OutlinedButton.icon(
      onPressed: () => updateOrderStatus(order['id'], 'confirmed'),
      icon: const Icon(Icons.check_circle_outline),
      label: const Text('Confirmed'),
    ),
    OutlinedButton.icon(
      onPressed: () => updateOrderStatus(order['id'], 'processing'),
      icon: const Icon(Icons.sync),
      label: const Text('Processing'),
    ),
    OutlinedButton.icon(
      onPressed: () => updateOrderStatus(order['id'], 'shipped'),
      icon: const Icon(Icons.local_shipping_outlined),
      label: const Text('Shipped'),
    ),
    OutlinedButton.icon(
      onPressed: () => updateOrderStatus(order['id'], 'in_transit'),
      icon: const Icon(Icons.route_outlined),
      label: const Text('In Transit'),
    ),
    FilledButton.icon(
      onPressed: () => updateOrderStatus(order['id'], 'delivered'),
      icon: const Icon(Icons.done_all),
      label: const Text('Delivered'),
    ),
  ],
),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget adminTable(List adminItems) {
  return dataTable(
    columns: const ['ID', 'Username', 'Email'],
    rows: adminItems.map((item) => [
      '${item['id']}',
      '${item['username']}',
      '${item['email']}',
    ]).toList(),
  );
}
Widget customerTable(List customerItems) {
  return dataTable(
    columns: const ['ID', 'Username', 'Email', 'Name', 'Orders'],
    rows: customerItems.map((item) => [
      '${item['id']}',
      '${item['username']}',
      '${item['email']}',
      '${item['first_name']} ${item['last_name']}',
      '${item['order_count']}',
    ]).toList(),
  );
}

  Widget statCard(String label, dynamic value, IconData icon) {
    return SizedBox(
      width: 220,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: adminLine),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: adminSurfaceTint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: adminNavy, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(color: adminMuted, fontSize: 12.5, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('$value', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: adminNavyDeep)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget dataTable({required List<String> columns, required List<List<String>> rows}) {
    if (rows.isEmpty) return emptyText('No data available.');
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: adminLine),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(adminSurfaceTint),
          columns: columns
              .map((column) => DataColumn(
                    label: Text(
                      column,
                      style: const TextStyle(fontWeight: FontWeight.w700, color: adminNavyDeep, fontSize: 12.5),
                    ),
                  ))
              .toList(),
          rows: rows
              .map((row) => DataRow(
                    cells: row
                        .map((cell) => DataCell(Text(cell, style: const TextStyle(fontSize: 13.5))))
                        .toList(),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget title(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Text(text, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: adminNavyDeep, letterSpacing: -0.4)),
      );

  Widget section(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: adminNavyDeep)),
      );

  Widget emptyText(String text) => Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: adminLine),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(text, style: const TextStyle(color: adminMuted)),
        ),
      );

  Widget statusChip(String status) {
    final color = switch (status) {
      'confirmed' => const Color(0xFFB45309),
      'processing' => const Color(0xFF2557D6),
      'shipped' => const Color(0xFF7C3AED),
      'in_transit' => const Color(0xFF0D9488),
      'delivered' => const Color(0xFF17A34A),
      _ => adminMuted,
    };

    final label = status.replaceAll('_', ' ').toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.3),
      ),
    );
  }
}