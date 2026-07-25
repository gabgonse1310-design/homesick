import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HomesickPaperBackground extends StatelessWidget {
  const HomesickPaperBackground({
    super.key,
    required this.child,
    this.backgroundAsset,
    this.padding = EdgeInsets.zero,
    this.useSafeArea = true,
  });

  final Widget child;
  final String? backgroundAsset;
  final EdgeInsetsGeometry padding;
  final bool useSafeArea;

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(
      padding: padding,
      child: child,
    );

    if (useSafeArea) {
      content = SafeArea(child: content);
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.cream,
        image: backgroundAsset == null
            ? null
            : DecorationImage(
                image: AssetImage(backgroundAsset!),
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const _PaperWash(),
          content,
        ],
      ),
    );
  }
}

class _PaperWash extends StatelessWidget {
  const _PaperWash();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.cream.withValues(alpha: 0.06),
              AppColors.warmPaper.withValues(alpha: 0.13),
            ],
          ),
        ),
      ),
    );
  }
}
