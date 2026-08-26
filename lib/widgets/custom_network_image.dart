import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CustomNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const CustomNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    // Fallback if URL is empty or invalid
    if (imageUrl.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: Colors.orange.withValues(alpha: 0.05),
        child: Center(
          child: Icon(Icons.image_not_supported_outlined, color: Colors.orange.withValues(alpha: 0.5), size: 20),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      // 1. Loading Placeholder
      placeholder: (context, url) => Container(
        width: width,
        height: height,
        color: Colors.orange.withValues(alpha: 0.05),
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              color: Colors.orange,
              strokeWidth: 1.5,
            ),
          ),
        ),
      ),
      // 2. Error Widget if image fails to load
      errorWidget: (context, url, error) => Container(
        width: width,
        height: height,
        color: Colors.orange.withValues(alpha: 0.05),
        child: Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: Colors.orange.withValues(alpha: 0.5),
            size: 20,
          ),
        ),
      ),
    );
  }
}