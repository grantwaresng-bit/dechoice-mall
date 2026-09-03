import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/cart_provider.dart';

class SpecialOffersPage extends StatefulWidget {
  final String? segmentId; // Optional segment filter if opened from a specific segment

  const SpecialOffersPage({super.key, this.segmentId});

  @override
  State<SpecialOffersPage> createState() => _SpecialOffersPageState();
}

class _SpecialOffersPageState extends State<SpecialOffersPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _specialItems = [];

  @override
  void initState() {
    super.initState();
    _fetchSpecialOffers();
  }

  Future<void> _fetchSpecialOffers() async {
    try {
      final supabase = Supabase.instance.client;

      // Query special/promo items directly from the items table using is_available
      var query = supabase
          .from('items')
          .select('*')
          .eq('is_special_offer', true);

      final response = await query;

      if (!mounted) return;

      setState(() {
        _specialItems = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading special offers: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading special offers: $e')),
      );
    }
  }

  bool _isItemAvailable(Map<String, dynamic> item) {
    // Check the actual 'is_available' column from your items table schema
    return item['is_available'] == true;
  }

  void _addItemToCart(Map<String, dynamic> item) {
    final bool isAvailable = _isItemAvailable(item);

    if (!isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This special offer item is currently closed/unavailable.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    final cart = Provider.of<CartProvider>(context, listen: false);
    final itemId = item['id'].toString();
    final name = item['name'] ?? 'Item';
    final price = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
    final imageUrl = item['image_url'] ?? '';

    cart.addItem(itemId, name, price, imageUrl);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added $name to cart'),
        duration: const Duration(milliseconds: 800),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _decrementCart(String itemId) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    cart.removeSingleItem(itemId);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'SPECIAL OFFERS',
              style: TextStyle(
                color: Colors.black,
                letterSpacing: 3,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : _specialItems.isEmpty
          ? const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'No special offers available right now. Check back soon!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.15)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.local_offer_outlined, color: Colors.orange, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Explore handpicked discounts and promotions available for a limited time.',
                      style: TextStyle(color: Colors.black87, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isDesktop ? 5 : 2,
                childAspectRatio: 0.65,
                crossAxisSpacing: 14,
                mainAxisSpacing: 20,
              ),
              itemCount: _specialItems.length,
              itemBuilder: (context, index) {
                final item = _specialItems[index];
                final itemId = item['id'].toString();
                final count = cart.getQuantity(itemId);
                final double price = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
                final String? description = item['description'];

                // Check active/available state from items table toggle
                final bool isAvailable = _isItemAvailable(item);

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade200, width: 1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Container(
                                color: Colors.grey.shade50,
                                width: double.infinity,
                                child: Image.network(
                                  item['image_url'] ?? '',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                    child: Icon(Icons.broken_image, size: 30, color: Colors.grey),
                                  ),
                                ),
                              ),
                              if (!isAvailable)
                                Container(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'CLOSED',
                                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'] ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '₦${price.toStringAsFixed(0)}',
                              style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            if (description != null && description.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Description: $description',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
                              ),
                            ],
                            const SizedBox(height: 8),
                            !isAvailable
                                ? SizedBox(
                              height: 28,
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('This section is currently closed for orders.'),
                                      duration: Duration(seconds: 1),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.grey),
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                ),
                                child: const Text('CLOSED', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            )
                                : count == 0
                                ? SizedBox(
                              height: 28,
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () => _addItemToCart(item),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.orange),
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                ),
                                child: const Text('Add to Cart', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            )
                                : Container(
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  InkWell(
                                    onTap: () => _decrementCart(itemId),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 6),
                                      child: Text('-', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                                    ),
                                  ),
                                  Text('$count', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                                  InkWell(
                                    onTap: () => _addItemToCart(item),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 6),
                                      child: Text('+', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}