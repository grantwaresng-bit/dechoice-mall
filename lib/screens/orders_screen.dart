import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/responsive_wrapper.dart'; // Import ResponsiveLayoutWrapper

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final TextEditingController _phoneController = TextEditingController();
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = false;
  bool _searched = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    if (_phoneController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _searched = true;
    });

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('orders')
          .select()
          .eq('phone_number', _phoneController.text.trim())
          .order('created_at', ascending: false);

      setState(() {
        _orders = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error fetching orders: $e'), backgroundColor: const Color(0xFF1E1E1E)),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    Widget content = Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'TRACK YOUR ORDER',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2, color: Color(0xFF1E1E1E)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Enter your phone number to check status',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w300, letterSpacing: 0.5, color: Color(0xFF1E1E1E)),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF1E1E1E)),
                  decoration: InputDecoration(
                    labelText: 'PHONE NUMBER',
                    labelStyle: const TextStyle(color: Color(0xFF666666), fontSize: 10, letterSpacing: 1.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                      borderSide: BorderSide(color: Color(0xFFF28C00), width: 1.5),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF28C00),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  elevation: 0,
                ),
                onPressed: _fetchOrders,
                child: const Text('SEARCH', style: TextStyle(fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFF28C00)))
                : _searched && _orders.isEmpty
                ? const Center(
              child: Text(
                'No orders found for this phone number.',
                style: TextStyle(color: Color(0xFF666666), fontSize: 13),
              ),
            )
                : ListView.builder(
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final order = _orders[index];
                final items = order['items_json'] as List<dynamic>? ?? [];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFDDDDDD), width: 1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'TYPE: ${order['delivery_type'].toString().toUpperCase()}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.5, color: Color(0xFF1E1E1E)),
                            ),
                            Text(
                              '₦${order['total_amount']}',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFFF28C00)),
                            ),
                          ],
                        ),
                        const Divider(color: Color(0xFFDDDDDD), height: 20, thickness: 1),
                        ...items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: Text(
                            '${item['quantity']}x ${item['name']} - ₦${item['price']} (${item['segment_name'] ?? 'Mall'})',
                            style: const TextStyle(fontSize: 13, color: Color(0xFF333333)),
                          ),
                        )),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Status: ${order['order_status'] ?? 'Received'}',
                              style: const TextStyle(color: Color(0xFFF28C00), fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'ORDERS & HISTORY',
              style: TextStyle(
                color: Color(0xFF1E1E1E),
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: Color(0xFFF28C00),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Color(0xFF1E1E1E)),
      ),
      body: ResponsiveLayoutWrapper(
        child: isDesktop
            ? Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: content,
          ),
        )
            : content,
      ),
    );
  }
}