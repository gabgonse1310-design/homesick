import 'package:flutter/material.dart';

/// Reusable widget that displays a person's botanical emblem.
///
/// Supports:
/// • Botanical asset paths
/// • Legacy emoji symbols (for backwards compatibility)
class BotanicalPersonIcon extends StatelessWidget {
  final String symbol;
  final double size;
  final EdgeInsetsGeometry padding;

  const BotanicalPersonIcon({
    super.key,
    required this.symbol,
    this.size = 56,
    this.padding = const EdgeInsets.all(6),
  });

  bool get _isAsset {
    return symbol.startsWith('assets/') &&
        (symbol.endsWith('.png') ||
            symbol.endsWith('.jpg') ||
            symbol.endsWith('.jpeg') ||
            symbol.endsWith('.webp'));
  }

  @override
  Widget build(BuildContext context) {
    if (_isAsset) {
      return SizedBox(
        width: size,
        height: size,
        child: Padding(
          padding: padding,
          child: Image.asset(
            symbol,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) {
              return Icon(
                Icons.local_florist,
                size: size * .55,
                color: const Color(0xFFB57A5A),
              );
            },
          ),
        ),
      );
    }

    // Backwards compatibility with emoji symbols
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Text(
          symbol,
          style: TextStyle(
            fontSize: size * .55,
          ),
        ),
      ),
    );
  }
}