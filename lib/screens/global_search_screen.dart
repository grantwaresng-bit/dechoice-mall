// lib/screens/global_search_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/cart_provider.dart';
import '../widgets/custom_network_image.dart';
import '../widgets/responsive_wrapper.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Simple & safe query – no joins, no broken columns
      final response = await Supabase.instance.client
          .from('items')
          .select('*')
          .ilike('name', '%${query.trim()}%')
          .order('name')
          .limit(40);

      if (!mounted) return;

      setState(() {
        _searchResults = List<Map<String, dynamic>>.from(response);
      });
    } catch (e, stack) {
      debugPrint('Search error: $e\n$stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isItemAvailable(Map<String, dynamic> item) {
    return item['is_available'] == true;
  }

  void _showAddToCartDialog(BuildContext context, Map<String, dynamic> item) {
    final bool available = _isItemAvailable(item);

    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This item is currently closed/unavailable for orders.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    int quantity = 1;
    final double price = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
    final String? sizesOrAges = item['sizes_or_ages']?.toString();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              title: Text(
                item['name'] ?? 'Item',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                  color: Color(0xFF1E1E1E),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item['image_url'] != null)
                    Container(
                      height: 140,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 14),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: CustomNetworkImage(
                          imageUrl: item['image_url'],
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Price:', style: TextStyle(color: Color(0xFF666666), fontSize: 13)),
                      Text(
                        '₦${price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF1E1E1E),
                        ),
                      ),
                    ],
                  ),
                  if (sizesOrAges != null && sizesOrAges.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Size/Age:', style: TextStyle(color: Color(0xFF666666), fontSize: 13)),
                        Text(
                          sizesOrAges,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Color(0xFF1E1E1E),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Quantity:',
                        style: TextStyle(fontSize: 13, color: Color(0xFF666666), fontWeight: FontWeight.w500),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, size: 22, color: Color(0xFF555555)),
                            onPressed: () {
                              if (quantity > 1) setDialogState(() => quantity--);
                            },
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '$quantity',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E1E1E),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, size: 22, color: Color(0xFF555555)),
                            onPressed: () => setDialogState(() => quantity++),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFFDDDDDD), thickness: 1, height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E1E1E)),
                      ),
                      Text(
                        '₦${(price * quantity).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF28C00),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Color(0xFF666666), fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF28C00),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onPressed: () {
                    final cart = Provider.of<CartProvider>(context, listen: false);

                    for (int i = 0; i < quantity; i++) {
                      cart.addItem(
                        item['id'].toString(),
                        item['name'] ?? '',
                        price,
                        item['image_url'] ?? '',
                      );
                    }

                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Added $quantity x ${item['name']} to cart!'),
                        backgroundColor: const Color(0xFF1E1E1E),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: const Text(
                    'Add to Cart',
                    style: TextStyle(fontSize: 12, letterSpacing: 0.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final queryText = _searchController.text.trim();
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Color(0xFFF28C00)),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Color(0xFF1E1E1E), fontSize: 14, letterSpacing: 0.3),
          decoration: const InputDecoration(
            hintText: 'Search items (e.g. milk, rice, cola)...',
            hintStyle: TextStyle(color: Color(0xFF888888), fontSize: 14),
            border: InputBorder.none,
          ),
          onChanged: (val) {
            setState(() {});
            _performSearch(val);
          },
        ),
        actions: [
          if (queryText.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Color(0xFF666666), size: 18),
              onPressed: () {
                _searchController.clear();
                _performSearch('');
              },
            ),
        ],
      ),
      body: ResponsiveLayoutWrapper(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFF28C00)))
            : queryText.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_outlined, size: 40, color: const Color(0xFFF28C00).withValues(alpha: 0.3)),
              const SizedBox(height: 12),
              const Text(
                'DISCOVER COLLECTIONS',
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        )
            : _searchResults.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sentiment_dissatisfied, size: 40, color: const Color(0xFFF28C00).withValues(alpha: 0.3)),
              const SizedBox(height: 12),
              Text(
                'No items found for "$queryText"',
                style: const TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 12,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        )
            : isDesktop
            ? Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) => _buildResultTile(context, _searchResults[index]),
            ),
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: _searchResults.length,
          itemBuilder: (context, index) => _buildResultTile(context, _searchResults[index]),
        ),
      ),
    );
  }

  Widget _buildResultTile(BuildContext context, Map<String, dynamic> item) {
    final bool available = _isItemAvailable(item);
    final String? sizesOrAges = item['sizes_or_ages']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDDDDDD), width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: Stack(
            children: [
              item['image_url'] != null
                  ? CustomNetworkImage(
                imageUrl: item['image_url'],
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              )
                  : Container(
                width: 50,
                height: 50,
                color: const Color(0xFFF28C00).withValues(alpha: 0.1),
                child: const Icon(Icons.shopping_bag_outlined, size: 20, color: Color(0xFFF28C00)),
              ),
              if (!available)
                Container(
                  width: 50,
                  height: 50,
                  color: Colors.black.withValues(alpha: 0.5),
                  alignment: Alignment.center,
                  child: const Text(
                    'CLOSED',
                    style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
        title: Text(
          item['name'] ?? '',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            letterSpacing: 0.2,
            color: available ? const Color(0xFF1E1E1E) : Colors.grey,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                available ? '₦${item['price'] ?? '0.00'}' : 'Currently Unavailable',
                style: TextStyle(
                  color: available ? const Color(0xFF666666) : Colors.red,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (sizesOrAges != null && sizesOrAges.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  'Size/Age: $sizesOrAges',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing: Icon(
          available ? Icons.add_shopping_cart : Icons.block,
          size: 18,
          color: available ? const Color(0xFFF28C00) : Colors.grey,
        ),
        onTap: () => _showAddToCartDialog(context, item),
      ),
    );
  }
}