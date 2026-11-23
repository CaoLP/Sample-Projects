import 'dart:math';
import 'package:flutter/material.dart';
import 'state.dart';

const kBlue = Color(0xFF0369A1), kTeal = Color(0xFF0D9488), kPurple = Color(0xFF7C3AED);
const kGreen = Color(0xFF16A34A), kAmber = Color(0xFFF59E0B), kRed = Color(0xFFDC2626);
Color levelColor(int l) => l == 2 ? kRed : l == 1 ? kAmber : kGreen;

/// Sóng nước chuyển động liên tục (header, splash).
class Waves extends StatefulWidget {
  final double height;
  final List<Color> colors;
  const Waves({super.key, this.height = 60, this.colors = const [Color(0x55FFFFFF), Color(0x33FFFFFF)]});
  @override
  State<Waves> createState() => _WavesState();
}

class _WavesState extends State<Waves> with SingleTickerProviderStateMixin {
  late final c = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  @override
  void dispose() { c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => SizedBox(
        height: widget.height,
        child: AnimatedBuilder(animation: c, builder: (_, _) => CustomPaint(painter: _WavePainter(c.value, widget.colors), size: Size.infinite)),
      );
}

class _WavePainter extends CustomPainter {
  final double t;
  final List<Color> colors;
  _WavePainter(this.t, this.colors);
  @override
  void paint(Canvas canvas, Size s) {
    for (var i = 0; i < colors.length; i++) {
      final p = Path()..moveTo(0, s.height);
      for (double x = 0; x <= s.width; x += 4) {
        p.lineTo(x, s.height * .45 + sin(x / s.width * 2 * pi * (1.2 + i * .4) + t * 2 * pi * (i.isEven ? 1 : -1)) * s.height * .22);
      }
      p..lineTo(s.width, s.height)..close();
      canvas.drawPath(p, Paint()..color = colors[i]);
    }
  }
  @override
  bool shouldRepaint(_WavePainter o) => o.t != t;
}

/// Đồng hồ vòng cung có animation khi giá trị đổi.
class Gauge extends StatelessWidget {
  final double value; // 0..1
  final Color color;
  final Widget center;
  final double size;
  const Gauge({super.key, required this.value, required this.color, required this.center, this.size = 120});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(end: value.clamp(0, 1)),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (_, v, _) => SizedBox(
          width: size, height: size,
          child: CustomPaint(
            painter: _GaugePainter(v, color, Theme.of(context).colorScheme.surfaceContainerHighest),
            child: Center(child: center),
          ),
        ),
      );
}

class _GaugePainter extends CustomPainter {
  final double v;
  final Color c, bg;
  _GaugePainter(this.v, this.c, this.bg);
  @override
  void paint(Canvas canvas, Size s) {
    final r = Rect.fromLTWH(8, 8, s.width - 16, s.height - 16);
    final p = Paint()..style = PaintingStyle.stroke..strokeWidth = 11..strokeCap = StrokeCap.round;
    canvas.drawArc(r, pi * .75, pi * 1.5, false, p..color = bg);
    canvas.drawArc(r, pi * .75, pi * 1.5 * v, false, p..shader = SweepGradient(colors: [c.withValues(alpha: .5), c], startAngle: pi * .75, endAngle: pi * 2.25, transform: const GradientRotation(0)).createShader(r));
  }
  @override
  bool shouldRepaint(_GaugePainter o) => o.v != v || o.c != c;
}

/// Biểu đồ đường + vùng tô gradient.
class Spark extends StatelessWidget {
  final List<double> data;
  final Color color;
  final double height;
  const Spark(this.data, this.color, {super.key, this.height = 36});
  @override
  Widget build(BuildContext context) => SizedBox(height: height, child: CustomPaint(painter: _SparkPainter(data, color), size: Size.infinite));
}

class _SparkPainter extends CustomPainter {
  final List<double> d;
  final Color c;
  _SparkPainter(this.d, this.c);
  @override
  void paint(Canvas canvas, Size s) {
    if (d.length < 2) return;
    final lo = d.reduce(min), hi = d.reduce(max), span = max(hi - lo, 1e-6);
    Offset pt(int i) => Offset(i / (d.length - 1) * s.width, s.height - (d[i] - lo) / span * (s.height - 4) - 2);
    final line = Path()..moveTo(pt(0).dx, pt(0).dy);
    for (var i = 1; i < d.length; i++) {
      final a = pt(i - 1), b = pt(i);
      line.cubicTo((a.dx + b.dx) / 2, a.dy, (a.dx + b.dx) / 2, b.dy, b.dx, b.dy);
    }
    final area = Path.from(line)..lineTo(s.width, s.height)..lineTo(0, s.height)..close();
    canvas.drawPath(area, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [c.withValues(alpha: .35), c.withValues(alpha: 0)]).createShader(Offset.zero & s));
    canvas.drawPath(line, Paint()..color = c..style = PaintingStyle.stroke..strokeWidth = 2.2);
    canvas.drawCircle(pt(d.length - 1), 3.5, Paint()..color = c);
  }
  @override
  bool shouldRepaint(_SparkPainter o) => true;
}

/// Chấm nhấp nháy dạng sóng radar (trạm, hộp cột, trạng thái live).
class Pulse extends StatefulWidget {
  final Color color;
  final double size;
  const Pulse(this.color, {super.key, this.size = 14});
  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();
  @override
  void dispose() { c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => SizedBox(
        width: widget.size * 3, height: widget.size * 3,
        child: AnimatedBuilder(
          animation: c,
          builder: (_, _) => Stack(alignment: Alignment.center, children: [
            Container(
              width: widget.size * (1 + c.value * 2), height: widget.size * (1 + c.value * 2),
              decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color.withValues(alpha: .45 * (1 - c.value))),
            ),
            Container(width: widget.size, height: widget.size, decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color, border: Border.all(color: Colors.white, width: 2))),
          ]),
        ),
      );
}

/// Số chạy mượt khi giá trị thay đổi.
class AnimNum extends StatelessWidget {
  final double value;
  final int digits;
  final TextStyle? style;
  const AnimNum(this.value, {super.key, this.digits = 0, this.style});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(end: value), duration: const Duration(milliseconds: 700),
        builder: (_, v, _) => Text(v.toStringAsFixed(digits), style: style),
      );
}

/// Vào màn hình: trượt lên + hiện dần theo thứ tự.
class FadeIn extends StatelessWidget {
  final int index;
  final Widget child;
  const FadeIn(this.index, this.child, {super.key});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1), duration: Duration(milliseconds: 450 + index * 90), curve: Curves.easeOutCubic,
        builder: (_, v, ch) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, (1 - v) * 24), child: ch)),
        child: child,
      );
}

/// Bản đồ khu vực vẽ tay: sông, đường, vùng ngập nội suy, trạm + hộp cột.
class AreaMapPainter extends CustomPainter {
  final AppState s;
  final bool darkMode;
  AreaMapPainter(this.s, this.darkMode);
  @override
  void paint(Canvas canvas, Size z) {
    canvas.drawRect(Offset.zero & z, Paint()..color = darkMode ? const Color(0xFF1E293B) : const Color(0xFFEFF6EE));
    final blocks = Paint()..color = darkMode ? const Color(0xFF273449) : const Color(0xFFE2E8F0);
    final rnd = Random(3);
    for (var i = 0; i < 26; i++) {
      final x = rnd.nextDouble() * z.width, y = rnd.nextDouble() * z.height;
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, 30 + rnd.nextDouble() * 50, 22 + rnd.nextDouble() * 40), const Radius.circular(6)), blocks);
    }
    // vùng ngập: mỗi hộp cột phát ra vùng màu theo độ sâu
    for (final b in s.beacons) {
      if (b.depth < 3) continue;
      final c = Offset(b.pos.dx * z.width, b.pos.dy * z.height), r = 30 + b.depth * 2.2;
      canvas.drawCircle(c, r, Paint()..shader = RadialGradient(colors: [levelColor(b.level).withValues(alpha: .45), levelColor(b.level).withValues(alpha: 0)]).createShader(Rect.fromCircle(center: c, radius: r)));
    }
    final river = Path()..moveTo(0, z.height * .15);
    river.cubicTo(z.width * .35, z.height * .05, z.width * .25, z.height * .55, z.width * .55, z.height * .5);
    river.cubicTo(z.width * .85, z.height * .45, z.width * .75, z.height * .9, z.width, z.height * .95);
    canvas.drawPath(river, Paint()..color = const Color(0xFF38BDF8).withValues(alpha: .7)..style = PaintingStyle.stroke..strokeWidth = 22..strokeCap = StrokeCap.round);
    final road = Paint()..color = darkMode ? const Color(0xFF64748B) : Colors.white..strokeWidth = 9..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, z.height * .42), Offset(z.width, z.height * .36), road);
    canvas.drawLine(Offset(z.width * .48, 0), Offset(z.width * .5, z.height), road);
    canvas.drawLine(Offset(z.width * .1, z.height * .8), Offset(z.width * .9, z.height * .6), road);
  }
  @override
  bool shouldRepaint(AreaMapPainter o) => true;
}

class Glass extends StatelessWidget {
  final Widget child;
  final EdgeInsets pad;
  final Gradient? gradient;
  const Glass({super.key, required this.child, this.pad = const EdgeInsets.all(16), this.gradient});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: pad,
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? cs.surfaceContainerLow : null,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .06), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: child,
    );
  }
}
