import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';

class BannerCarousel extends StatefulWidget {
  final String? segmentId; // Null for general banners, or specific segment ID

  const BannerCarousel({super.key, this.segmentId});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _banners = [];
  bool _isLoading = true;

  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _autoPlayTimer;

  @override
  void initState() {
    super.initState();
    _fetchBanners();
  }

  Future<void> _fetchBanners() async {
    try {
      var query = _supabase
          .from('special_offers')
          .select()
          .eq('is_active', true);

      // Filter by segment if provided, else grab general ones or both
      if (widget.segmentId != null) {
        query = query.or('segment_id.eq.${widget.segmentId},segment_id.is.null');
      } else {
        query = query.isFilter('segment_id', null);
      }

      final response = await query.order('display_order', ascending: true);

      if (mounted) {
        setState(() {
          _banners = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });

        if (_banners.length > 1) {
          _startAutoPlay();
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startAutoPlay() {
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients && _banners.isNotEmpty) {
        int nextPageIndex = (_currentPage + 1) % _banners.length;
        _pageController.animateToPage(
          nextPageIndex,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator(color: Colors.orange)),
      );
    }

    if (_banners.isEmpty) {
      return const SizedBox.shrink(); // Hide if no banners available
    }

    final isDesktop = MediaQuery.of(context).size.width > 900;

    Widget carouselContent = SizedBox(
      height: 180,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _banners.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) {
                final banner = _banners[index];
                final mediaUrl = banner['image_url'] ?? '';
                final isVideo = mediaUrl.toLowerCase().endsWith('.mp4') ||
                    mediaUrl.toLowerCase().endsWith('.mov') ||
                    mediaUrl.toLowerCase().endsWith('.webm');

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.2), width: 1),
                    color: Colors.orange.withValues(alpha: 0.03),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        isVideo
                            ? VideoBannerPlayer(videoUrl: mediaUrl)
                            : Image.network(
                          mediaUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Icon(Icons.broken_image, color: Colors.orange.withValues(alpha: 0.5), size: 20),
                          ),
                        ),
                        // Dechoice Orange Gradient Overlay & Text
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.75),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          padding: const EdgeInsets.all(16),
                          alignment: Alignment.bottomLeft,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (banner['title'] ?? '').toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 2,
                                ),
                              ),
                              if (banner['subtitle'] != null &&
                                  banner['subtitle'].isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  banner['subtitle'],
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    letterSpacing: 0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // Page Indicators Dots (Dechoice Orange Theme)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_banners.length, (index) {
              return Container(
                width: _currentPage == index ? 16 : 4,
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: _currentPage == index ? Colors.orange : Colors.orange.withValues(alpha: 0.3),
                ),
              );
            }),
          ),
        ],
      ),
    );

    return isDesktop
        ? Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: carouselContent,
      ),
    )
        : carouselContent;
  }
}

// --- HELPER WIDGET FOR VIDEO BANNERS ---
class VideoBannerPlayer extends StatefulWidget {
  final String videoUrl;
  const VideoBannerPlayer({super.key, required this.videoUrl});

  @override
  State<VideoBannerPlayer> createState() => _VideoBannerPlayerState();
}

class _VideoBannerPlayerState extends State<VideoBannerPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _isInitialized = true);
          _controller.setLooping(true);
          _controller.setVolume(0.0); // Mute background promo video
          _controller.play();
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      );
    }
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _controller.value.size.width,
        height: _controller.value.size.height,
        child: VideoPlayer(_controller),
      ),
    );
  }
}