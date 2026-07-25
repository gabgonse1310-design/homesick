import 'package:flutter/material.dart';

class HomesickBackground extends StatelessWidget {
  const HomesickBackground({
    super.key,
    required this.asset,
    required this.child,
  });

  final String asset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          asset,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
        ),
        child,
      ],
    );
  }
}
