import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/letter.dart';
import '../models/person.dart';
import '../theme/app_theme.dart';
import 'read_letter_screen.dart';

class EnvelopeOpeningScreen extends StatefulWidget {
  final Letter letter;
  final Person? person;
  final List<Person>? availablePeople;
  final bool isIncoming;
  final String? senderName;

  const EnvelopeOpeningScreen({
    super.key,
    required this.letter,
    this.person,
    this.availablePeople,
    this.isIncoming = false,
    this.senderName,
  });

  @override
  State<EnvelopeOpeningScreen> createState() =>
      _EnvelopeOpeningScreenState();
}

class _EnvelopeOpeningScreenState extends State<EnvelopeOpeningScreen>
    with TickerProviderStateMixin {
  late final AnimationController _arrivalController;
  late final AnimationController _openingController;
  late final Animation<double> _arrivalScale;
  late final Animation<double> _arrivalOpacity;

  bool _isOpening = false;

  String get _displayName {
    final sender = widget.senderName?.trim() ?? '';
    if (widget.isIncoming && sender.isNotEmpty) {
      return sender;
    }

    final recipient = widget.letter.recipientName.trim();
    if (recipient.isNotEmpty) {
      return recipient;
    }

    return 'Someone special';
  }

  @override
  void initState() {
    super.initState();

    _arrivalController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    _openingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2100),
    );

    _arrivalScale = CurvedAnimation(
      parent: _arrivalController,
      curve: Curves.easeOutBack,
    );

    _arrivalOpacity = CurvedAnimation(
      parent: _arrivalController,
      curve: const Interval(0, 0.7, curve: Curves.easeOut),
    );

    _arrivalController.forward();
  }

  @override
  void dispose() {
    _arrivalController.dispose();
    _openingController.dispose();
    super.dispose();
  }

  Future<void> _openLetter() async {
    if (_isOpening) return;

    setState(() => _isOpening = true);
    await _openingController.forward();

    if (!mounted) return;

    await Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 650),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
          child: ReadLetterScreen(
            letter: widget.letter,
            person: widget.person,
            availablePeople: widget.availablePeople,
            isIncoming: widget.isIncoming,
            senderName: widget.senderName,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final envelopeWidth = math.min(size.width - 48, 360.0);
    final envelopeHeight = envelopeWidth * 0.64;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _BotanicalBackgroundPainter(),
              ),
            ),
            Positioned(
              top: 6,
              left: 8,
              child: IconButton(
                tooltip: 'Back',
                onPressed: _isOpening
                    ? null
                    : () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.ink,
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 72, 24, 36),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FadeTransition(
                      opacity: _arrivalOpacity,
                      child: Text(
                        widget.isIncoming
                            ? 'Words from $_displayName'
                            : 'A letter for $_displayName',
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    const SizedBox(height: 10),
                    FadeTransition(
                      opacity: _arrivalOpacity,
                      child: Text(
                        widget.isIncoming
                            ? 'Someone took the time to write these words for you.'
                            : 'Take a quiet moment before opening it.',
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: AppColors.softGrey,
                                ),
                      ),
                    ),
                    const SizedBox(height: 46),
                    ScaleTransition(
                      scale: _arrivalScale,
                      child: AnimatedBuilder(
                        animation: _openingController,
                        builder: (context, _) {
                          return SizedBox(
                            width: envelopeWidth,
                            height: envelopeHeight + 170,
                            child: _AnimatedEnvelope(
                              width: envelopeWidth,
                              height: envelopeHeight,
                              progress: _openingController.value,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    AnimatedOpacity(
                      opacity: _isOpening ? 0 : 1,
                      duration: const Duration(milliseconds: 250),
                      child: IgnorePointer(
                        ignoring: _isOpening,
                        child: FilledButton.icon(
                          onPressed: _openLetter,
                          icon: const Icon(Icons.mail_outline_rounded),
                          label: const Text('Open Letter'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    AnimatedOpacity(
                      opacity: _isOpening ? 1 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Opening your letter…',
                          style:
                              Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedEnvelope extends StatelessWidget {
  final double width;
  final double height;
  final double progress;

  const _AnimatedEnvelope({
    required this.width,
    required this.height,
    required this.progress,
  });

  double _interval(
    double start,
    double end, {
    Curve curve = Curves.easeInOut,
  }) {
    final value = ((progress - start) / (end - start)).clamp(0.0, 1.0);
    return curve.transform(value);
  }

  @override
  Widget build(BuildContext context) {
    final flapOpen = _interval(0.08, 0.42, curve: Curves.easeInOutCubic);
    final sealFade = 1 - _interval(0.02, 0.25);
    final paperRise = _interval(0.34, 0.78, curve: Curves.easeOutCubic);
    final paperExpand = _interval(0.66, 1, curve: Curves.easeOutCubic);

    final paperTop =
        height * 0.34 - (paperRise * height * 0.62) - (paperExpand * 28);
    final paperWidth = width * (0.77 + paperExpand * 0.14);
    final paperHeight = height * (0.82 + paperExpand * 0.47);

    return Stack(
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: paperTop,
          child: Opacity(
            opacity: _interval(0.28, 0.52),
            child: Transform.scale(
              scale: 0.96 + paperExpand * 0.04,
              alignment: Alignment.bottomCenter,
              child: Container(
                width: paperWidth,
                height: paperHeight,
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: AppColors.border.withOpacity(0.85),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 20,
                      offset: Offset(0, 9),
                    ),
                  ],
                ),
                child: Opacity(
                  opacity: _interval(0.72, 1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: paperWidth * 0.35,
                        height: 7,
                        decoration: BoxDecoration(
                          color: AppColors.terracotta.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 18),
                      ...List.generate(
                        5,
                        (index) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          width: index == 4
                              ? paperWidth * 0.48
                              : double.infinity,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.softInk.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: height * 0.42,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: const Color(0xFFE9C7A8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFD7AA86),
                width: 1.2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: height * 0.42,
          child: CustomPaint(
            size: Size(width, height),
            painter: _EnvelopeFrontPainter(),
          ),
        ),
        Positioned(
          top: height * 0.42,
          child: Transform(
            alignment: Alignment.topCenter,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0015)
              ..rotateX(math.pi * flapOpen),
            child: ClipPath(
              clipper: _EnvelopeFlapClipper(),
              child: Container(
                width: width,
                height: height * 0.58,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1D4B8),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: height * 0.72,
          child: Opacity(
            opacity: sealFade,
            child: Transform.scale(
              scale: 1 - _interval(0.08, 0.28) * 0.22,
              child: Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  color: AppColors.terracotta,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_florist_rounded,
                  size: 28,
                  color: AppColors.paper,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EnvelopeFrontPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final leftPaint = Paint()..color = const Color(0xFFE3BC98);
    final rightPaint = Paint()..color = const Color(0xFFEDC9A8);
    final bottomPaint = Paint()..color = const Color(0xFFF3D5B9);

    final left = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.53, size.height * 0.54)
      ..lineTo(0, size.height)
      ..close();

    final right = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width * 0.47, size.height * 0.54)
      ..lineTo(size.width, size.height)
      ..close();

    final bottom = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width * 0.5, size.height * 0.48)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(left, leftPaint);
    canvas.drawPath(right, rightPaint);
    canvas.drawPath(bottom, bottomPaint);

    final linePaint = Paint()
      ..color = const Color(0xFFD6A985)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    canvas.drawLine(
      Offset(0, 0),
      Offset(size.width * 0.53, size.height * 0.54),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width * 0.47, size.height * 0.54),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EnvelopeFlapClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width * 0.5, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _BotanicalBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final leafPaint = Paint()
      ..color = AppColors.olive.withOpacity(0.08)
      ..style = PaintingStyle.fill;

    final flowerPaint = Paint()
      ..color = AppColors.terracotta.withOpacity(0.07)
      ..style = PaintingStyle.fill;

    void leaf(Offset center, double rotation, double scale) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(rotation);
      canvas.scale(scale);

      final path = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(24, -20, 48, 0)
        ..quadraticBezierTo(24, 20, 0, 0)
        ..close();

      canvas.drawPath(path, leafPaint);
      canvas.restore();
    }

    void flower(Offset center, double scale) {
      for (var i = 0; i < 5; i++) {
        final angle = (math.pi * 2 / 5) * i;
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(angle);
        canvas.scale(scale);
        canvas.drawOval(
          const Rect.fromLTWH(-7, -28, 14, 26),
          flowerPaint,
        );
        canvas.restore();
      }
    }

    leaf(Offset(size.width * 0.04, size.height * 0.22), -0.7, 1.1);
    leaf(Offset(size.width * 0.88, size.height * 0.18), 2.6, 0.9);
    leaf(Offset(size.width * 0.02, size.height * 0.78), -0.4, 1.3);
    leaf(Offset(size.width * 0.87, size.height * 0.82), 2.8, 1.15);

    flower(Offset(size.width * 0.12, size.height * 0.1), 0.75);
    flower(Offset(size.width * 0.9, size.height * 0.7), 0.9);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
