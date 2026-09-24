import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/localization/star_dust_strings.dart';

class StarDustScreen extends StatefulWidget {
  const StarDustScreen({super.key});

  @override
  State<StarDustScreen> createState() => _StarDustScreenState();
}

class _StarDustScreenState extends State<StarDustScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _untilReset(int milliseconds, StarDustStrings copy) {
    final duration = Duration(milliseconds: milliseconds.clamp(0, 604800000));
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    if (copy.isPortuguese) return '${copy['sunday']} • ${days}d ${hours}h';
    return '${copy['sunday']} • ${days}d ${hours}h';
  }

  @override
  Widget build(BuildContext context) {
    final service = AppScope.of(context).online!;
    final copy = StarDustStrings.of(context);
    final balance = service.starDustBalance;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF020D27),
      appBar: AppBar(
        title: Text(copy['title']),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _SpaceBackground(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 62, 20, 32),
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF392C55), Color(0xFF18242C)],
                    ),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: const Color(0xFFDBC37A).withValues(alpha: .55),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x443C2D72),
                        blurRadius: 24,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const StarDustJar(size: 104),
                      const SizedBox(height: 12),
                      Text(
                        '$balance / 100',
                        key: const Key('star_dust_balance'),
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFFFDF85),
                        ),
                      ),
                      const SizedBox(height: 13),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: LinearProgressIndicator(
                          value: balance / 100,
                          minHeight: 13,
                          backgroundColor: Colors.black26,
                          valueColor: const AlwaysStoppedAnimation(
                            Color(0xFFFFD66B),
                          ),
                        ),
                      ),
                      if (balance >= 100) ...[
                        const SizedBox(height: 10),
                        Text(
                          copy['full'],
                          style: const TextStyle(
                            color: Color(0xFFFFDF85),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  copy['explanation'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFC8D8F5),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  copy['weeklyProgress'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                _WeeklyMetric(
                  icon: Icons.auto_awesome_rounded,
                  label: copy['starsThisWeek'],
                  value: copy.stars(service.weeklyStarsCollected),
                ),
                const SizedBox(height: 8),
                _WeeklyMetric(
                  icon: Icons.extension_rounded,
                  label: copy['stagesThisWeek'],
                  value: copy.stages(service.weeklyStagesCompleted),
                ),
                const SizedBox(height: 8),
                _WeeklyMetric(
                  icon: Icons.event_repeat_rounded,
                  label: copy['nextReset'],
                  value: _untilReset(
                    service.weeklyResetsAt - service.serverNow,
                    copy,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  copy.isPortuguese
                      ? 'O saldo de Pó Estelar permanece após o reset. Apenas os recordes semanais das fases são renovados.'
                      : 'Your Star Dust balance remains after the reset. Only weekly stage records are renewed.',
                  style: const TextStyle(
                    color: Color(0xFFB8C9E8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpaceBackground extends StatelessWidget {
  const _SpaceBackground();

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('star_dust_space_background'),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF06193D), Color(0xFF03102D), Color(0xFF01081C)],
      ),
    ),
    child: const CustomPaint(painter: _ConstellationPainter()),
  );
}

class _ConstellationPainter extends CustomPainter {
  const _ConstellationPainter();

  static const _constellations = <List<Offset>>[
    [Offset(.05, .13), Offset(.15, .09), Offset(.21, .16), Offset(.13, .22)],
    [Offset(.58, .11), Offset(.66, .17), Offset(.74, .12), Offset(.82, .19)],
    [Offset(.19, .39), Offset(.28, .34), Offset(.36, .42), Offset(.45, .36)],
    [Offset(.62, .55), Offset(.70, .49), Offset(.80, .57), Offset(.91, .49)],
    [Offset(.10, .75), Offset(.19, .68), Offset(.28, .76), Offset(.37, .70)],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final starPaint = Paint()..color = const Color(0xDDF7F2D0);
    for (var i = 0; i < 76; i++) {
      final x = ((i * 83 + 17) % 997) / 997 * size.width;
      final y = ((i * 151 + 29) % 991) / 991 * size.height;
      final radius = i % 11 == 0 ? 1.7 : (i % 4 == 0 ? 1.05 : .62);
      canvas.drawCircle(Offset(x, y), radius, starPaint);
      if (i % 17 == 0) {
        canvas.drawLine(Offset(x - 4, y), Offset(x + 4, y), starPaint);
        canvas.drawLine(Offset(x, y - 4), Offset(x, y + 4), starPaint);
      }
    }

    final linePaint = Paint()
      ..color = const Color(0x99F7F2D0)
      ..strokeWidth = .9
      ..style = PaintingStyle.stroke;
    for (final constellation in _constellations) {
      final points = [
        for (final point in constellation)
          Offset(point.dx * size.width, point.dy * size.height),
      ];
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, linePaint);
      for (final point in points) {
        canvas.drawCircle(point, 2.2, starPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_ConstellationPainter oldDelegate) => false;
}

class _WeeklyMetric extends StatelessWidget {
  const _WeeklyMetric({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: const Color(0xAA10274A),
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: const Color(0x445E80B7)),
    ),
    child: Row(
      children: [
        Icon(icon, color: const Color(0xFFFFD66B)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFFFDF85),
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class StarDustJar extends StatelessWidget {
  const StarDustJar({this.size = 74, this.glowing = false, super.key});
  final double size;
  final bool glowing;

  @override
  Widget build(BuildContext context) => AnimatedScale(
    scale: glowing ? 1.1 : 1,
    duration: const Duration(milliseconds: 220),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: glowing
            ? const [
                BoxShadow(
                  color: Color(0xAAFFD76A),
                  blurRadius: 28,
                  spreadRadius: 5,
                ),
              ]
            : const [],
      ),
      child: Image.asset(
        'assets/images/home/star_dust_vial.png',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    ),
  );
}

class StarDustHomeIcon extends StatelessWidget {
  const StarDustHomeIcon({super.key});
  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/images/home/star_dust_vial.png',
    width: 64,
    height: 64,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.high,
    cacheWidth: 192,
    excludeFromSemantics: true,
  );
}
