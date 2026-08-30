import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/cart_provider.dart';
import '../services/supabase_service.dart';
import '../widgets/custom_network_image.dart';
import '../widgets/responsive_wrapper.dart';
import 'cart_screen.dart';
import 'special_offers_page.dart';

class SegmentDetailScreen extends StatefulWidget {
  final String segmentId;
  final String segmentName;

  const SegmentDetailScreen({
    super.key,
    required this.segmentId,
    required this.segmentName,
  });

  @override
  State<SegmentDetailScreen> createState() => _SegmentDetailScreenState();
}

class _SegmentDetailScreenState extends State<SegmentDetailScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _itemSearchResults = [];
  bool _isSearchingItems = false;

  bool _isSegmentActive = true;
  String? _segmentAvailabilityNote;
  bool _isLoadingSegment = true;

  @override
  void initState() {
    super.initState();
    _fetchSegmentStatus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchSegmentStatus() async {
    try {
      final response = await Supabase.instance.client
          .from('segments')
          .select('is_active, availability_note')
          .eq('id', widget.segmentId)
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _isSegmentActive = response['is_active'] ?? true;
          _segmentAvailabilityNote = response['availability_note'];
          _isLoadingSegment = false;
        });
      } else {
        setState(() => _isLoadingSegment = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingSegment = false);
      debugPrint('Error fetching segment status: $e');
    }
  }

  Future<void> _performItemSearch(String query) async {
    final trimmed = query.toLowerCase().trim();
    setState(() {
      _searchQuery = trimmed;
    });

    if (trimmed.isEmpty) {
      setState(() {
        _itemSearchResults = [];
        _isSearchingItems = false;
      });
      return;
    }

    setState(() => _isSearchingItems = true);

    try {
      final response = await Supabase.instance.client
          .from('items')
          .select('*, categories!inner(segment_id, is_active)')
          .eq('categories.segment_id', widget.segmentId)
          .ilike('name', '%$trimmed%')
          .limit(30);

      if (!mounted) return;
      setState(() {
        _itemSearchResults = List<Map<String, dynamic>>.from(response);
        _isSearchingItems = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSearchingItems = false);
      debugPrint('Error searching segment items: $e');
    }
  }

  void _showAddToCartDialog(BuildContext context, Map<String, dynamic> item, bool canOrder) {
    if (!canOrder) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This item is currently closed/unavailable for orders.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    int quantity = 1;
    final double price = (item['price'] as num? ?? 0).toDouble();
    final String itemId = item['id'].toString();
    final String itemName = item['name'] ?? '';
    final String itemImage = item['image_url'] ?? '';
    final String? sizesOrAges = item['sizes_or_ages'];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              title: Text(
                itemName,
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
                  if (itemImage.isNotEmpty)
                    Container(
                      height: 140,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 14),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: CustomNetworkImage(imageUrl: itemImage, fit: BoxFit.cover),
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Price:', style: TextStyle(color: Color(0xFF666666), fontSize: 13)),
                      Text(
                        '₦${price.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1E1E1E)),
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
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E1E1E)),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Quantity:', style: TextStyle(fontSize: 13, color: Color(0xFF666666), fontWeight: FontWeight.w500)),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, size: 22, color: Color(0xFF555555)),
                            onPressed: () {
                              if (quantity > 1) {
                                setDialogState(() => quantity--);
                              }
                            },
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '$quantity',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E1E1E)),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, size: 22, color: Color(0xFF555555)),
                            onPressed: () {
                              setDialogState(() => quantity++);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFFDDDDDD), thickness: 1, height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E1E1E))),
                      Text(
                        '₦${(price * quantity).toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF28C00), fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF666666), fontSize: 13, fontWeight: FontWeight.w600)),
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
                      cart.addItem(itemId, itemName, price, itemImage);
                    }

                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Added $quantity x $itemName to cart!'),
                        backgroundColor: const Color(0xFF1E1E1E),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: const Text('Add to Cart', style: TextStyle(fontSize: 12, letterSpacing: 0.5, fontWeight: FontWeight.bold)),
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
    final supabase = Supabase.instance.client;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Color(0xFF1E1E1E)),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.segmentName.toUpperCase(),
              style: const TextStyle(
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
              decoration: BoxDecoration(
                color: _isSegmentActive ? const Color(0xFFF28C00) : Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF1E1E1E), size: 20),
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
                      : Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF28C00),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${cart.itemCount}',
                      style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoadingSegment
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF28C00)))
          : ResponsiveLayoutWrapper(
        maxWidth: 900,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            if (!_isSegmentActive)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.red, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'SECTION CURRENTLY CLOSED',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
                        ),
                      ],
                    ),
                    if (_segmentAvailabilityNote != null && _segmentAvailabilityNote!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        _segmentAvailabilityNote!,
                        style: const TextStyle(color: Color(0xFF333333), fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),

            SpecialOffersBanner(segmentId: widget.segmentId),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 13, color: Color(0xFF1E1E1E)),
                decoration: InputDecoration(
                  hintText: 'Search items within ${widget.segmentName}...',
                  hintStyle: const TextStyle(color: Color(0xFF666666), fontSize: 12),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF666666), size: 18),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear, color: Color(0xFF666666), size: 16),
                    onPressed: () {
                      _searchController.clear();
                      _performItemSearch('');
                    },
                  )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(2),
                    borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(2),
                    borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(2)),
                    borderSide: BorderSide(color: Color(0xFFF28C00), width: 1.5),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: _performItemSearch,
              ),
            ),

            if (_searchQuery.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
                child: Row(
                  children: [
                    Container(width: 12, height: 2, color: const Color(0xFFF28C00)),
                    const SizedBox(width: 8),
                    Text(
                      'SEARCH RESULTS FOR "$_searchQuery"',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2, color: Color(0xFF1E1E1E)),
                    ),
                  ],
                ),
              ),
              _isSearchingItems
                  ? const Padding(
                padding: EdgeInsets.all(40.0),
                child: Center(child: CircularProgressIndicator(color: Color(0xFFF28C00))),
              )
                  : _itemSearchResults.isEmpty
                  ? const Padding(
                padding: EdgeInsets.all(40.0),
                child: Center(
                  child: Text(
                    'No items match your search in this store.',
                    style: TextStyle(color: Color(0xFF666666), fontSize: 13),
                  ),
                ),
              )
                  : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.7,
                ),
                itemCount: _itemSearchResults.length,
                itemBuilder: (context, index) {
                  final item = _itemSearchResults[index];
                  final itemName = item['name'] ?? '';
                  final itemPrice = (item['price'] as num? ?? 0).toDouble();
                  final itemImage = item['image_url'] ?? '';
                  final String? sizesOrAges = item['sizes_or_ages'];
                  final categoryData = item['categories'];
                  final bool isItemCategoryActive = categoryData == null || categoryData['is_active'] != false;
                  final bool canOrder = _isSegmentActive && isItemCategoryActive;

                  return GestureDetector(
                    onTap: () => _showAddToCartDialog(context, item, canOrder),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFDDDDDD), width: 1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                  child: CustomNetworkImage(
                                    imageUrl: itemImage,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                if (!canOrder)
                                  Container(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    alignment: Alignment.center,
                                    child: const Text(
                                      'UNAVAILABLE',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.5),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  itemName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF1E1E1E)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '₦$itemPrice',
                                  style: const TextStyle(color: Color(0xFFF28C00), fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                if (sizesOrAges != null && sizesOrAges.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Size/Age: $sizesOrAges',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w500),
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Consumer<CartProvider>(
                                  builder: (context, cart, child) {
                                    if (!canOrder) {
                                      return SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.grey,
                                            side: const BorderSide(color: Colors.grey),
                                            padding: const EdgeInsets.symmetric(vertical: 6),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                                          ),
                                          onPressed: () => _showAddToCartDialog(context, item, canOrder),
                                          child: const Text('CLOSED', style: TextStyle(fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                                        ),
                                      );
                                    }

                                    return SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFF28C00),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 6),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                                          elevation: 0,
                                        ),
                                        onPressed: () => _showAddToCartDialog(context, item, canOrder),
                                        child: const Text('ADD', style: TextStyle(fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ] else ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 12.0),
                child: Text(
                  'CATEGORIES',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2, color: Color(0xFF1E1E1E)),
                ),
              ),

              FutureBuilder<List<Map<String, dynamic>>>(
                future: supabase
                    .from('categories')
                    .select()
                    .eq('segment_id', widget.segmentId)
                    .isFilter('parent_id', null)
                    .order('name', ascending: true),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Center(child: CircularProgressIndicator(color: Color(0xFFF28C00))),
                    );
                  }
                  if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Center(
                        child: Text(
                          'No categories available for this segment yet.',
                          style: TextStyle(color: Color(0xFF666666), fontSize: 13),
                        ),
                      ),
                    );
                  }

                  final categories = snapshot.data!;

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final bool isCategoryActive = category['is_active'] ?? true;
                      final String? catAvailabilityNote = category['availability_note'];

                      return GestureDetector(
                        onTap: () async {
                          final subCategories = await supabase
                              .from('categories')
                              .select()
                              .eq('parent_id', category['id']);

                          if (!context.mounted) return;

                          if (subCategories.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SubCategoriesScreen(
                                  parentCategoryId: category['id'],
                                  parentCategoryName: category['name'],
                                ),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CategoryProductsScreen(
                                  categoryId: category['id'],
                                  categoryName: category['name'],
                                ),
                              ),
                            );
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFDDDDDD), width: 1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CustomNetworkImage(
                                  imageUrl: category['image_url'] ?? '',
                                  fit: BoxFit.cover,
                                ),
                                Container(
                                  color: Colors.black.withValues(alpha: isCategoryActive ? 0.3 : 0.6),
                                ),
                                if (!isCategoryActive)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                      child: const Text(
                                        'CLOSED',
                                        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          category['name'].toString().toUpperCase(),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: isCategoryActive ? Colors.white : Colors.white70,
                                            fontSize: 12,
                                            letterSpacing: 1.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (!isCategoryActive && catAvailabilityNote != null && catAvailabilityNote.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            catAvailabilityNote,
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// --- SPECIAL OFFERS BANNER WIDGET ---
class SpecialOffersBanner extends StatefulWidget {
  final String segmentId;

  const SpecialOffersBanner({super.key, required this.segmentId});

  @override
  State<SpecialOffersBanner> createState() => _SpecialOffersBannerState();
}

class _SpecialOffersBannerState extends State<SpecialOffersBanner> {
  final PageController _pageController = PageController();
  Timer? _autoScrollTimer;
  int _currentPage = 0;
  bool _isPaused = false;

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll(int offerCount) {
    if (offerCount <= 1) return;

    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_isPaused || !mounted) return;

      if (_pageController.hasClients) {
        _currentPage = (_currentPage + 1) % offerCount;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final supabaseService = SupabaseService();

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: supabaseService.getSpecialOffers(widget.segmentId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            height: 140,
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFDDDDDD), width: 1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Center(
              child: Text(
                'CURATED OFFERS',
                style: TextStyle(color: Color(0xFF666666), fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold),
              ),
            ),
          );
        }

        final offers = snapshot.data!;

        if (_autoScrollTimer == null && offers.length > 1) {
          _startAutoScroll(offers.length);
        }

        return Listener(
          onPointerDown: (_) => setState(() => _isPaused = true),
          onPointerUp: (_) => setState(() => _isPaused = false),
          onPointerCancel: (_) => setState(() => _isPaused = false),
          child: SizedBox(
            height: 160,
            child: PageView.builder(
              controller: _pageController,
              itemCount: offers.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SpecialOffersPage(),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFDDDDDD), width: 1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: CustomNetworkImage(
                        imageUrl: offers[index]['image_url'] ?? '',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

// --- SUB-CATEGORIES SCREEN ---
class SubCategoriesScreen extends StatelessWidget {
  final String parentCategoryId;
  final String parentCategoryName;

  const SubCategoriesScreen({
    super.key,
    required this.parentCategoryId,
    required this.parentCategoryName,
  });

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          parentCategoryName.toUpperCase(),
          style: const TextStyle(color: Color(0xFF1E1E1E), letterSpacing: 2, fontWeight: FontWeight.bold, fontSize: 14),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Color(0xFF1E1E1E)),
      ),
      body: ResponsiveLayoutWrapper(
        maxWidth: 900,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: supabase
              .from('categories')
              .select()
              .eq('parent_id', parentCategoryId)
              .order('name', ascending: true),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFFF28C00)));
            }
            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No sub-categories available.', style: TextStyle(color: Color(0xFF666666), fontSize: 13)));
            }

            final subCategories = snapshot.data!;
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemCount: subCategories.length,
              itemBuilder: (context, index) {
                final subCat = subCategories[index];
                final bool isSubActive = subCat['is_active'] ?? true;
                final String? subNote = subCat['availability_note'];

                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CategoryProductsScreen(
                        categoryId: subCat['id'],
                        categoryName: subCat['name'],
                      ),
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFDDDDDD), width: 1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CustomNetworkImage(
                            imageUrl: subCat['image_url'] ?? '',
                            fit: BoxFit.cover,
                          ),
                          Container(
                            color: Colors.black.withValues(alpha: isSubActive ? 0.3 : 0.6),
                          ),
                          if (!isSubActive)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: const Text(
                                  'CLOSED',
                                  style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    subCat['name'].toString().toUpperCase(),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: isSubActive ? Colors.white : Colors.white70,
                                      fontSize: 12,
                                      letterSpacing: 1.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (!isSubActive && subNote != null && subNote.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      subNote,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
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

// --- PRODUCTS SCREEN FOR A SPECIFIC CATEGORY ---
class CategoryProductsScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const CategoryProductsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  bool _isCategoryActive = true;
  String? _categoryAvailabilityNote;
  bool _isLoadingCategory = true;

  @override
  void initState() {
    super.initState();
    _fetchCategoryStatus();
  }

  Future<void> _fetchCategoryStatus() async {
    try {
      final response = await Supabase.instance.client
          .from('categories')
          .select('is_active, availability_note')
          .eq('id', widget.categoryId)
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _isCategoryActive = response['is_active'] ?? true;
          _categoryAvailabilityNote = response['availability_note'];
          _isLoadingCategory = false;
        });
      } else {
        setState(() => _isLoadingCategory = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingCategory = false);
      debugPrint('Error checking category status: $e');
    }
  }

  void _showAddToCartDialog(BuildContext context, Map<String, dynamic> item) {
    if (!_isCategoryActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This category is currently closed for orders.'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    int quantity = 1;
    final double price = (item['price'] as num? ?? 0).toDouble();
    final String itemName = item['name'] ?? '';
    final String itemImage = item['image_url'] ?? '';
    final String? sizesOrAges = item['sizes_or_ages'];
    final String itemId = item['id'].toString();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              title: Text(
                itemName,
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
                  if (itemImage.isNotEmpty)
                    Container(
                      height: 140,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 14),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: CustomNetworkImage(imageUrl: itemImage, fit: BoxFit.cover),
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Price:', style: TextStyle(color: Color(0xFF666666), fontSize: 13)),
                      Text(
                        '₦${price.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1E1E1E)),
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
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E1E1E)),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Quantity:', style: TextStyle(fontSize: 13, color: Color(0xFF666666), fontWeight: FontWeight.w500)),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, size: 22, color: Color(0xFF555555)),
                            onPressed: () {
                              if (quantity > 1) {
                                setDialogState(() => quantity--);
                              }
                            },
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '$quantity',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E1E1E)),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, size: 22, color: Color(0xFF555555)),
                            onPressed: () {
                              setDialogState(() => quantity++);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFFDDDDDD), thickness: 1, height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E1E1E))),
                      Text(
                        '₦${(price * quantity).toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF28C00), fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF666666), fontSize: 13, fontWeight: FontWeight.w600)),
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
                      cart.addItem(itemId, itemName, price, itemImage);
                    }

                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Added $quantity x $itemName to cart!'),
                        backgroundColor: const Color(0xFF1E1E1E),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: const Text('Add to Cart', style: TextStyle(fontSize: 12, letterSpacing: 0.5, fontWeight: FontWeight.bold)),
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
    final supabase = Supabase.instance.client;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.categoryName.toUpperCase(),
          style: const TextStyle(color: Color(0xFF1E1E1E), letterSpacing: 2, fontWeight: FontWeight.bold, fontSize: 14),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Color(0xFF1E1E1E)),
      ),
      body: _isLoadingCategory
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF28C00)))
          : ResponsiveLayoutWrapper(
        maxWidth: 900,
        child: Column(
          children: [
            if (!_isCategoryActive)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.red, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'CATEGORY CURRENTLY CLOSED',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
                        ),
                      ],
                    ),
                    if (_categoryAvailabilityNote != null && _categoryAvailabilityNote!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        _categoryAvailabilityNote!,
                        style: const TextStyle(color: Color(0xFF333333), fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: supabase
                    .from('items')
                    .select()
                    .eq('category_id', widget.categoryId)
                    .order('name', ascending: true),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFFF28C00)));
                  }
                  if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('No items available in this category yet.', style: TextStyle(color: Color(0xFF666666), fontSize: 13)),
                    );
                  }

                  final items = snapshot.data!;
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final itemName = item['name'] ?? '';
                      final itemPrice = (item['price'] as num? ?? 0).toDouble();
                      final itemImage = item['image_url'] ?? '';
                      final String? sizesOrAges = item['sizes_or_ages'];

                      return GestureDetector(
                        onTap: () => _showAddToCartDialog(context, item),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFFDDDDDD), width: 1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                      child: CustomNetworkImage(
                                        imageUrl: itemImage,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    if (!_isCategoryActive)
                                      Container(
                                        color: Colors.black.withValues(alpha: 0.4),
                                        alignment: Alignment.center,
                                        child: const Text(
                                          'UNAVAILABLE',
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.5),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      itemName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF1E1E1E)),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₦$itemPrice',
                                      style: const TextStyle(color: Color(0xFFF28C00), fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                    if (sizesOrAges != null && sizesOrAges.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Size/Age: $sizesOrAges',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                    const SizedBox(height: 6),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFF28C00),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 6),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                                          elevation: 0,
                                        ),
                                        onPressed: () => _showAddToCartDialog(context, item),
                                        child: Text(
                                          _isCategoryActive ? 'ADD' : 'CLOSED',
                                          style: const TextStyle(fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold),
                                        ),
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
          ],
        ),
      ),
    );
  }
}