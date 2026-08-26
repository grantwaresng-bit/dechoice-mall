import 'package:flutter/material.dart';

class ResponsiveLayoutWrapper extends StatelessWidget {
  const ResponsiveLayoutWrapper({
    super.key,
    required this.child,
    this.maxWidth = 600, // Configurable max width for different screen types
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 600;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: isDesktop
                ? Border.symmetric(
              vertical: BorderSide(color: Colors.orange.withValues(alpha: 0.15), width: 1),
            )
                : null,
            boxShadow: isDesktop
                ? [
              BoxShadow(
                color: Colors.orange.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 2),
              ),
            ]
                : [],
          ),
          child: child,
        ),
      ),
    );
  }
}