import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HomesickLoading extends StatefulWidget {
  const HomesickLoading({super.key});

  @override
  State<HomesickLoading> createState() => _HomesickLoadingState();
}

class _HomesickLoadingState extends State<HomesickLoading> {
  Timer? _timer;
  int _active = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 420), (_) {
      if (mounted) setState(() => _active = (_active + 1) % 3);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final active = index == _active;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 7,
          height: 7,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          transform: Matrix4.translationValues(0, active ? -3 : 0, 0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? AppColors.terracotta
                : AppColors.mutedRose.withValues(alpha: 0.45),
          ),
        );
      }),
    );
  }
}
