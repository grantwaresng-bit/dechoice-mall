import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/cart_provider.dart';
import '../widgets/custom_network_image.dart';
import '../widgets/responsive_wrapper.dart';
import '../widgets/banner_carousel.dart';
import 'segment_detail_screen.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';
import 'info_screens.dart';

// --- GLOBAL SEARCH SCREEN ---
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
      // Fetch matching items and join categories/segments to check active status if needed
      final response = await Supabase.instance.client
          .from('items')
          .select('*, categories(id, name, is_active, availability_note)')
          .ilike('name', '%$query%')
          .limit(20);

      if (!mounted) return;
      setState(() {
        _searchResults = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint('Search error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddToCartDialog(BuildContext context, Map<String, dynamic> item) {
    // Check if category/segment is active if data exists
    final category = item['categories'];
    final bool isCategoryActive = category == null || category['is_active'] != false;
    final String availabilityNote = category != null ? (category['availability_note'] ?? '') : '';

    if (!isCategoryActive) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Store Section Closed', style: TextStyle(color: Colors.red, fontSize: 16)),
          content: Text(
            availabilityNote.isNotEmpty
                ? 'This item is currently unavailable.\n\nNote: $availabilityNote'
                : 'This section of the store is currently closed and not accepting orders.',
            style: const TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK', style: TextStyle(color: Colors.orange)),
            ),
          ],
        ),
      );
      return;
    }

    int quantity = 1;
    final double price = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              title: Text(
                item['name'] ?? 'Item',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.orange),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item['image_url'] != null)
                    Container(
                      height: 140,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: CustomNetworkImage(imageUrl: item['image_url'], fit: BoxFit.cover),
                      ),
                    ),
                  Text('Price: ₦${price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.orange)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Quantity:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, size: 20, color: Colors.orange),
                            onPressed: () {
                              if (quantity > 1) {
                                setDialogState(() => quantity--);
                              }
                            },
                          ),
                          Text('$quantity', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, size: 20, color: Colors.orange),
                            onPressed: () {
                              setDialogState(() => quantity++);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(color: Colors.orange, thickness: 0.5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.orange)),
                      Text('₦${(price * quantity).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 14)),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    elevation: 0,
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
                        backgroundColor: Colors.orange,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: const Text('Add to Cart', style: TextStyle(fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.bold)),
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
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Search any and everything...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          onChanged: _performSearch,
        ),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                _performSearch('');
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : _searchResults.isEmpty
          ? const Center(
        child: Text(
          'Type to search items across the store',
          style: TextStyle(color: Colors.grey),
        ),
      )
          : ListView.builder(
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final item = _searchResults[index];
          final category = item['categories'];
          final bool isCategoryActive = category == null || category['is_active'] != false;

          return ListTile(
            leading: item['image_url'] != null
                ? CustomNetworkImage(
              imageUrl: item['image_url'],
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            )
                : const Icon(Icons.store, size: 50, color: Colors.orange),
            title: Text(item['name'] ?? 'Dechoice Mall'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('₦${item['price'] ?? 0}'),
                if (!isCategoryActive)
                  const Text('CLOSED / UNAVAILABLE', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
            trailing: Icon(Icons.add_shopping_cart, size: 20, color: isCategoryActive ? Colors.orange : Colors.grey),
            onTap: () => _showAddToCartDialog(context, item),
          );
        },
      ),
    );
  }
}

// --- HOME SCREEN ---
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF28C00),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'DECHOICE MALL',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 2.5,
          ),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          // Global Search Icon Button
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GlobalSearchScreen()),
            ),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Consumer<CartProvider>(
                  builder: (_, cart, __) => cart.itemCount == 0
                      ? const SizedBox.shrink()
                      : CircleAvatar(
                    radius: 8,
                    backgroundColor: Colors.red,
                    child: Text(
                      '${cart.itemCount}',
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.orange),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('Dechoice Mall', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Welcome Customer', style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.card_giftcard, color: Colors.orange),
              title: const Text('Invite Friends'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const InviteFriendsScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.info, color: Colors.orange),
              title: const Text('About'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.orange),
              title: const Text('Social Media Handles'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SocialMediaScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long, color: Colors.orange),
              title: const Text('Orders & Payment'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.help, color: Colors.orange),
              title: const Text('Help'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen()));
              },
            ),
          ],
        ),
      ),
      body: ResponsiveLayoutWrapper(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: supabase.from('segments').select().order('display_order', ascending: true),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.orange));
            }
            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No segments configured yet.'));
            }

            final segments = snapshot.data!;

            return ListView.builder(
              itemCount: segments.length + 1,
              padding: const EdgeInsets.all(12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 16.0),
                    child: BannerCarousel(),
                  );
                }

                final segment = segments[index - 1];
                final bool isActive = segment['is_active'] ?? true;
                final String? availabilityNote = segment['availability_note'];
                final subtitleText = segment['subtitle'] ?? 'Tap to explore store & menu items';

                return GestureDetector(
                  onTap: () {
                    // Navigate anyway or show closed modal?
                    // Usually, letting them view the segment detail handles items display restrictions,
                    // but we can also block it right here or show a warning. Let's pass through
                    // so they can see the closed/availability note on the detail screen too.
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SegmentDetailScreen(
                          segmentId: segment['id'],
                          segmentName: segment['name'],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    height: 140,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CustomNetworkImage(
                          imageUrl: segment['image_url'] ?? '',
                          fit: BoxFit.cover,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: isActive ? 0.65 : 0.8),
                              ],
                            ),
                          ),
                        ),
                        // Closed Overlay Banner if inactive
                        if (!isActive)
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'CLOSED',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.5),
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                segment['name'],
                                style: TextStyle(
                                  color: isActive ? Colors.white : Colors.white70,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                !isActive && availabilityNote != null && availabilityNote.isNotEmpty
                                    ? availabilityNote
                                    : subtitleText,
                                style: TextStyle(
                                  color: !isActive ? Colors.redAccent.shade100 : Colors.white70,
                                  fontSize: 12,
                                  fontWeight: !isActive ? FontWeight.w500 : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}