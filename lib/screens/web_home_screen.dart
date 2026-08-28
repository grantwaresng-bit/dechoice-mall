import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/cart_provider.dart';
import 'segment_detail_screen.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';
import 'info_screens.dart';
import 'global_search_screen.dart';
import 'special_offers_page.dart';

class WebHomeScreen extends StatefulWidget {
  const WebHomeScreen({super.key});

  @override
  State<WebHomeScreen> createState() => _WebHomeScreenState();
}

class _WebHomeScreenState extends State<WebHomeScreen> {
  final _supabase = Supabase.instance.client;
  String? _selectedSegmentId; // null means "ALL"
  String? _selectedSegmentName;

  // Slider controllers & timer
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _sliderTimer;

  @override
  void dispose() {
    _sliderTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide(int slideCount) {
    if (slideCount <= 1) return;
    _sliderTimer?.cancel();
    _sliderTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) return;
      if (_pageController.hasClients) {
        _currentPage = (_currentPage + 1) % slideCount;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  bool _isItemAvailable(Map<String, dynamic> item) {
    final category = item['categories'];
    final segment = category != null ? category['segments'] : null;
    final bool isCategoryActive = category == null || category['is_active'] != false;
    final bool isSegmentActive = segment == null || segment['is_active'] != false;
    return isCategoryActive && isSegmentActive;
  }

  void _incrementCart(Map<String, dynamic> item) {
    if (!_isItemAvailable(item)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This item or section is currently closed for orders.'),
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
      const SnackBar(content: Text('Added item to cart'), duration: Duration(milliseconds: 500)),
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          // Hamburger Menu Icon on the left
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.black, size: 22),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'DECHOICE MALL',
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
          actions: [
            // Search Icon navigates to GlobalSearchScreen
            IconButton(
              icon: const Icon(Icons.search, color: Colors.black, size: 20),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GlobalSearchScreen()),
              ),
            ),
            // Cart Icon with Live Badge
            IconButton(
              icon: Badge(
                isLabelVisible: cart.itemCount > 0,
                label: Text('${cart.itemCount}'),
                child: const Icon(Icons.shopping_bag_outlined, color: Colors.black, size: 20),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
      // Sidebar Drawer
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Dynamic Slider Hero Banner Section (Queries web_hero_content)
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _supabase
                  .from('web_hero_content')
                  .select()
                  .eq('is_active', true)
                  .order('display_order', ascending: true),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 420,
                    child: Center(child: CircularProgressIndicator(color: Colors.orange)),
                  );
                }

                final slides = snapshot.data ?? [];

                // Fallback default slide if table is empty
                if (slides.isEmpty) {
                  slides.add({
                    'tagline': 'CRAFTED FOR THE EXTRAORDINARY',
                    'headline': 'Discover Timeless Elegance.',
                    'button_text': 'EXPLORE COLLECTION',
                    'background_image_url': 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?q=80&w=1600&auto=format&fit=crop',
                  });
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _startAutoSlide(slides.length);
                });

                return MouseRegion(
                  onEnter: (_) => _sliderTimer?.cancel(),
                  onExit: (_) => _startAutoSlide(slides.length),
                  child: SizedBox(
                    height: 420,
                    child: Stack(
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          itemCount: slides.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentPage = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            final slide = slides[index];
                            final tagline = slide['tagline'] ?? '';
                            final headline = slide['headline'] ?? '';
                            final buttonText = slide['button_text'] ?? 'EXPLORE COLLECTION';
                            final imageUrl = slide['background_image_url'] ?? '';

                            return Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF111111),
                                image: DecorationImage(
                                  image: NetworkImage(imageUrl),
                                  fit: BoxFit.cover,
                                  opacity: 0.6,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (tagline.isNotEmpty) ...[
                                      Row(
                                        children: [
                                          Container(width: 20, height: 2, color: Colors.orange),
                                          const SizedBox(width: 8),
                                          Text(
                                            tagline,
                                            style: const TextStyle(color: Colors.orangeAccent, letterSpacing: 2, fontSize: 11, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                    Text(
                                      headline,
                                      style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w300, letterSpacing: 0.5),
                                    ),
                                    const SizedBox(height: 24),
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        side: const BorderSide(color: Colors.orange, width: 1.5),
                                        backgroundColor: Colors.orange.withValues(alpha: 0.1),
                                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => const SpecialOffersPage()),
                                        );
                                      },
                                      child: Text(buttonText, style: const TextStyle(letterSpacing: 2, fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        if (slides.length > 1)
                          Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(slides.length, (dotIndex) {
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  width: _currentPage == dotIndex ? 24 : 8,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(3),
                                    color: _currentPage == dotIndex ? Colors.orange : Colors.white.withValues(alpha: 0.5),
                                  ),
                                );
                              }),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // 2. Instagram-Style Stories / Segments Bar
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MALL SEGMENTS',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.orange),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 110,
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _supabase.from('segments').select().eq('is_active', true).order('display_order', ascending: true),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator(color: Colors.orange));
                        }
                        final segments = snapshot.data!;

                        return ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            // "ALL" Story Bubble
                            Padding(
                              padding: const EdgeInsets.only(right: 16.0),
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  _selectedSegmentId = null;
                                  _selectedSegmentName = null;
                                }),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _selectedSegmentId == null ? Colors.orange : Colors.transparent,
                                          width: 2.5,
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        radius: 32,
                                        backgroundColor: Colors.orange,
                                        child: const Text('ALL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text('All Items', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                            ),
                            // Dynamic Segment Story Bubbles
                            ...segments.map((segment) {
                              final segId = segment['id'];
                              final segName = segment['name'] ?? '';
                              final isSelected = _selectedSegmentId == segId;
                              return Padding(
                                padding: const EdgeInsets.only(right: 16.0),
                                child: GestureDetector(
                                  onTap: () => setState(() {
                                    _selectedSegmentId = segId;
                                    _selectedSegmentName = segName;
                                  }),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSelected ? Colors.orange : Colors.grey.shade300,
                                            width: 2.5,
                                          ),
                                        ),
                                        child: CircleAvatar(
                                          radius: 32,
                                          backgroundImage: segment['image_url'] != null ? NetworkImage(segment['image_url']) : null,
                                          child: segment['image_url'] == null ? const Icon(Icons.store, color: Colors.white) : null,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      SizedBox(
                                        width: 70,
                                        child: Text(
                                          segName,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // 3. Rich Categorized Content Section
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedSegmentName != null ? _selectedSegmentName!.toUpperCase() : 'ALL STORE ITEMS',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.orange),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _selectedSegmentName != null
                                    ? 'Explore categories & items under $_selectedSegmentName'
                                    : 'Explore all available store items below',
                                style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w400),
                              ),
                            ],
                          ),
                        ),
                        if (_selectedSegmentId != null)
                          ElevatedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SegmentDetailScreen(
                                  segmentId: _selectedSegmentId!,
                                  segmentName: _selectedSegmentName!,
                                ),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            icon: const Icon(Icons.open_in_new, size: 14),
                            label: const Text('Open Store Page', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Fixed "ALL" vs Segment / Category Handling with Active Filtering Joins
                  _selectedSegmentId == null
                      ? FutureBuilder<List<Map<String, dynamic>>>(
                    future: _supabase
                        .from('items')
                        .select('*, categories!inner(id, name, is_active, segment_id, segments!inner(id, name, is_active))')
                        .limit(50),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: Colors.orange)));
                      }
                      final allItems = snapshot.data ?? [];
                      if (allItems.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: Text('No items available in the store yet.', style: TextStyle(color: Colors.grey, fontSize: 13))),
                        );
                      }

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isDesktop ? 5 : 2,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 20,
                        ),
                        itemCount: allItems.length,
                        itemBuilder: (context, index) {
                          return _buildProductCard(allItems[index]);
                        },
                      );
                    },
                  )
                      : FutureBuilder<List<Map<String, dynamic>>>(
                    future: _supabase
                        .from('categories')
                        .select('*, segments!inner(id, name, is_active)')
                        .eq('segment_id', _selectedSegmentId!)
                        .eq('is_active', true),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: Colors.orange)));
                      }

                      final categories = snapshot.data ?? [];
                      if (categories.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: Text('No active categories available in this selection yet.', style: TextStyle(color: Colors.grey, fontSize: 13))),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: categories.length,
                        itemBuilder: (context, catIndex) {
                          final category = categories[catIndex];
                          final catId = category['id'];
                          final catName = category['name'] ?? 'Category';

                          return FutureBuilder<List<Map<String, dynamic>>>(
                            future: _supabase
                                .from('items')
                                .select('*, categories!inner(id, name, is_active, segment_id, segments!inner(id, name, is_active))')
                                .eq('category_id', catId),
                            builder: (context, catItemSnapshot) {
                              final catItems = catItemSnapshot.data ?? [];
                              if (catItems.isEmpty) return const SizedBox.shrink();

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    catName.toUpperCase(),
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.orange),
                                  ),
                                  const SizedBox(height: 12),
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: isDesktop ? 5 : 2,
                                      childAspectRatio: 0.7,
                                      crossAxisSpacing: 14,
                                      mainAxisSpacing: 20,
                                    ),
                                    itemCount: catItems.length,
                                    itemBuilder: (context, index) {
                                      return _buildProductCard(catItems[index]);
                                    },
                                  ),
                                  const SizedBox(height: 40),
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

            // 4. Clean Footer
            Container(
              color: const Color(0xFF111111),
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
              child: const Center(
                child: Text(
                  '© 2026 Dechoice Mall. All rights reserved.',
                  style: TextStyle(color: Colors.grey, fontSize: 11, letterSpacing: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> item) {
    final cart = Provider.of<CartProvider>(context);
    final itemId = item['id'].toString();
    final count = cart.getQuantity(itemId);
    final bool available = _isItemAvailable(item);
    final double price = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;

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
                    child: item['image_url'] != null
                        ? Image.network(item['image_url'], fit: BoxFit.cover)
                        : const Center(child: Icon(Icons.image, color: Colors.grey, size: 20)),
                  ),
                  if (!available)
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
                  item['name'] ?? 'Item',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: available ? Colors.black87 : Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  available ? '₦${price.toStringAsFixed(0)}' : 'Unavailable',
                  style: TextStyle(color: available ? Colors.orange : Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                !available
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
                    onPressed: () => _incrementCart(item),
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
                        child: const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Text('-', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange))),
                      ),
                      Text('$count', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                      InkWell(
                        onTap: () => _incrementCart(item),
                        child: const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Text('+', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange))),
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
  }
}