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

  // ---------- FIXED: only use real columns ----------
  bool _isItemAvailable(Map<String, dynamic> item) {
    // Item-level flag (the main one you control from the management app)
    final bool isItemAvailableFlag = item['is_available'] == true;

    // If the item has a category → segments join, we can also check the segment
    final category = item['categories'];
    final segment = category != null ? category['segments'] : null;

    // segments table uses is_available (not is_active)
    final bool isSegmentActive = segment == null || segment['is_available'] != false;

    return isItemAvailableFlag && isSegmentActive;
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
            IconButton(
              icon: const Icon(Icons.search, color: Colors.black, size: 20),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GlobalSearchScreen()),
              ),
            ),
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
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Dynamic Slider Hero Banner
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

                    if (slides.isEmpty) {
                      slides.add({
                        'tagline': 'CRAFTED FOR THE EXTRAORDINARY',
                        'headline': 'Discover Timeless Elegance.',
                        'button_text': 'EXPLORE COLLECTION',
                        'background_image_url':
                        'https://images.unsplash.com/photo-1441986300917-64674bd600d8?q=80&w=1600&auto=format&fit=crop',
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
                                setState(() => _currentPage = index);
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
                                                style: const TextStyle(
                                                  color: Colors.orangeAccent,
                                                  letterSpacing: 2,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                        ],
                                        Text(
                                          headline,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 36,
                                            fontWeight: FontWeight.w300,
                                            letterSpacing: 0.5,
                                          ),
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
                                          child: Text(
                                            buttonText,
                                            style: const TextStyle(
                                              letterSpacing: 2,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
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
                                        color: _currentPage == dotIndex
                                            ? Colors.orange
                                            : Colors.white.withValues(alpha: 0.5),
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

                // 2. Segments Bar
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
                          // FIXED: is_available instead of is_active
                          future: _supabase
                              .from('segments')
                              .select()
                              .eq('is_available', true)
                              .order('display_order', ascending: true),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(child: CircularProgressIndicator(color: Colors.orange));
                            }
                            final segments = snapshot.data!;

                            return ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
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
                                          child: const CircleAvatar(
                                            radius: 32,
                                            backgroundColor: Colors.orange,
                                            child: Text('ALL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        const Text('All Items', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                  ),
                                ),
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
                                              backgroundImage: segment['image_url'] != null
                                                  ? NetworkImage(segment['image_url'])
                                                  : null,
                                              child: segment['image_url'] == null
                                                  ? const Icon(Icons.store, color: Colors.white)
                                                  : null,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          SizedBox(
                                            width: 70,
                                            child: Text(
                                              segName,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                              ),
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

                // 3. Products Section
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
                                    _selectedSegmentName != null
                                        ? _selectedSegmentName!.toUpperCase()
                                        : 'ALL STORE ITEMS',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                      color: Colors.orange,
                                    ),
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

                      // ========== ALL ITEMS (no segment selected) ==========
                      _selectedSegmentId == null
                          ? FutureBuilder<List<Map<String, dynamic>>>(
                        future: _supabase
                            .from('items')
                            .select('*, categories(id, name, segment_id, segments(id, name, is_available))')
                            .limit(60),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(40),
                                child: CircularProgressIndicator(color: Colors.orange),
                              ),
                            );
                          }
                          final allItems = snapshot.data ?? [];
                          if (allItems.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: Text(
                                  'No items available in the store yet.',
                                  style: TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                              ),
                            );
                          }

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: isDesktop ? 5 : 2,
                              childAspectRatio: 0.65,
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
                      // ========== SPECIFIC SEGMENT ==========
                          : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Direct items (no category)
                          FutureBuilder<List<Map<String, dynamic>>>(
                            future: _supabase
                                .from('items')
                                .select('*, categories(id, name, segment_id, segments(id, name, is_available))')
                                .eq('segment_id', _selectedSegmentId!)
                                .filter('category_id', 'is', null),
                            builder: (context, directItemSnapshot) {
                              final directItems = directItemSnapshot.data ?? [];
                              if (directItems.isEmpty) return const SizedBox.shrink();

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedSegmentName != null
                                        ? _selectedSegmentName!.toUpperCase()
                                        : 'ITEMS',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: isDesktop ? 5 : 2,
                                      childAspectRatio: 0.65,
                                      crossAxisSpacing: 14,
                                      mainAxisSpacing: 20,
                                    ),
                                    itemCount: directItems.length,
                                    itemBuilder: (context, index) {
                                      return _buildProductCard(directItems[index]);
                                    },
                                  ),
                                  const SizedBox(height: 30),
                                ],
                              );
                            },
                          ),

                          // Categories of this segment
                          FutureBuilder<List<Map<String, dynamic>>>(
                            future: _supabase
                                .from('categories')
                                .select('*, segments(id, name, is_available)')
                                .eq('segment_id', _selectedSegmentId!)
                                .filter('parent_id', 'is', null)
                                .order('name'),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(20),
                                    child: CircularProgressIndicator(color: Colors.orange),
                                  ),
                                );
                              }

                              final categories = snapshot.data ?? [];
                              if (categories.isEmpty) return const SizedBox.shrink();

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
                                        .select('*, categories(id, name, segment_id, segments(id, name, is_available))')
                                        .eq('category_id', catId),
                                    builder: (context, catItemSnapshot) {
                                      final catItems = catItemSnapshot.data ?? [];
                                      if (catItems.isEmpty) return const SizedBox.shrink();

                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            catName.toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.5,
                                              color: Colors.orange,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          GridView.builder(
                                            shrinkWrap: true,
                                            physics: const NeverScrollableScrollPhysics(),
                                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: isDesktop ? 5 : 2,
                                              childAspectRatio: 0.65,
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
                    ],
                  ),
                ),

                // Footer
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
    final String? sizesOrAges = item['sizes_or_ages']?.toString();

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
                    child: item['image_url'] != null && item['image_url'].toString().isNotEmpty
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
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.black87, height: 1.2),
                ),
                const SizedBox(height: 4),
                Text(
                  '₦${price.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.orange),
                ),
                if (sizesOrAges != null && sizesOrAges.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Size/Age: $sizesOrAges',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                ],
                const SizedBox(height: 8),
                available
                    ? (count == 0
                    ? SizedBox(
                  width: double.infinity,
                  height: 28,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange, width: 1),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    onPressed: () => _incrementCart(item),
                    child: const Text('Add to Cart', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                )
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.remove_circle_outline, size: 18, color: Colors.orange),
                      onPressed: () => _decrementCart(itemId),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('$count', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.add_circle_outline, size: 18, color: Colors.orange),
                      onPressed: () => _incrementCart(item),
                    ),
                  ],
                ))
                    : const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      'Unavailable',
                      style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
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