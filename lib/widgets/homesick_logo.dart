import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class HomesickLogo extends StatelessWidget {
  const HomesickLogo({
    super.key,
    this.showTagline = true,
    this.logoSize = 48,
    this.alignment = CrossAxisAlignment.center,
  });

  final bool showTagline;
  final double logoSize;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignment,
      children: [
        Text(
          'Homesick',
          textAlign: alignment == CrossAxisAlignment.start
              ? TextAlign.left
              : alignment == CrossAxisAlignment.end
                  ? TextAlign.right
                  : TextAlign.center,
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: logoSize,
                height: 1,
              ),
        ),
        if (showTagline) ...[
          const SizedBox(height: 8),
          Text(
            'Everlasting words.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.terracotta,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.5,
                ),
          ),
        ],
      ],
    );
  }
}
