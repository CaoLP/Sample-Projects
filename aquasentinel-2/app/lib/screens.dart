import 'dart:math';
import 'package:flutter/material.dart';
import 'i18n.dart';
import 'main.dart';
import 'state.dart';
import 'widgets.dart';

String ago(DateTime t) {
  final d = DateTime.now().difference(t);
  final v = d.inMinutes < 1 ? '${d.inSeconds}s' : d.inHours < 1 ? '${d.inMinutes}m' : d.inDays < 1 ? '${d.inHours}h' : '${d.inDays}d';
  return '$v ${tr('ago')}';
}

void toast(BuildContext c, String m, [Color? col]) => ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m), behavior: SnackBarBehavior.floating, backgroundColor: col));

// ───────────────────────── Tổng quan ─────────────────────────
class Dashboard extends StatelessWidget {
  const Dashboard({super.key});
  @override
  Widget build(BuildContext context) {
    final s = Scope.of(context);
    final ai = s.ai, risk = s.risk;
    final aiColor = {'normal': kGreen, 'runoff': kBlue, 'watch': kAmber, 'suspect': kRed}[ai]!;
    final metrics = [
      ('temp', Icons.thermostat_rounded, s.temp, '°C', 1, s.hist['temp']!, Colors.orange),
      ('tds', Icons.science_rounded, s.tds, 'ppm', 0, s.hist['tds']!, s.tds > 600 ? kRed : kPurple),
      ('turb', Icons.blur_on_rounded, s.turb, 'NTU', 0, s.hist['turb']!, s.turb > 80 ? kAmber : kTeal),
      ('depth', Icons.waves_rounded, s.depth, 'cm', 0, s.hist['depth']!, kBlue),
      ('flow', Icons.speed_rounded, s.flow, 'L/min', 1, <double>[], Colors.indigo),
      ('rain', Icons.thunderstorm_rounded, s.rain, 'mm/h', 0, <double>[], Colors.blueGrey),
      ('ph', Icons.opacity_rounded, s.ph, '', 1, <double>[], s.ph < 6.5 ? kRed : kGreen),
    ];
    return CustomScrollView(slivers: [
      SliverToBoxAdapter(child: _Header(s)),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        sliver: SliverToBoxAdapter(
          child: Row(children: [
            Expanded(child: FadeIn(0, Glass(child: Column(children: [
              Text(tr('floodRisk'), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              Gauge(value: (risk + 1) / 3, color: levelColor(risk), center: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(risk == 2 ? Icons.warning_rounded : Icons.shield_rounded, color: levelColor(risk), size: 28),
                Text(tr('risk$risk'), style: TextStyle(fontWeight: FontWeight.w800, color: levelColor(risk))),
              ])),
              Text('☔ ${s.rain3h.toStringAsFixed(0)}mm · 🌊 ${s.tide.toStringAsFixed(0)}cm', style: Theme.of(context).textTheme.bodySmall),
            ])))),
            const SizedBox(width: 12),
            Expanded(child: FadeIn(1, Glass(
              gradient: LinearGradient(colors: [aiColor.withValues(alpha: .9), aiColor.withValues(alpha: .65)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              child: SizedBox(height: 172, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [const Icon(Icons.auto_awesome, color: Colors.white, size: 18), const SizedBox(width: 6), Expanded(child: Text(tr('aiSource'), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)))]),
                const Spacer(),
                AnimatedSwitcher(duration: const Duration(milliseconds: 400), child: Text(tr(ai), key: ValueKey(ai), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800))),
                const SizedBox(height: 6),
                Text(tr('${ai}D'), style: const TextStyle(color: Colors.white, fontSize: 12)),
              ])),
            ))),
          ]),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid.count(
          crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.45,
          children: [
            for (final (i, m) in metrics.indexed)
              FadeIn(i + 2, Glass(pad: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: m.$7.withValues(alpha: .14), borderRadius: BorderRadius.circular(10)), child: Icon(m.$2, color: m.$7, size: 18)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(tr(m.$1), overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                ]),
                const Spacer(),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  AnimNum(m.$3, digits: m.$5, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                  Padding(padding: const EdgeInsets.only(left: 4, bottom: 4), child: Text(m.$4, style: Theme.of(context).textTheme.bodySmall)),
                ]),
                if (m.$6.isNotEmpty) Spark(m.$6, m.$7, height: 22),
              ]))),
            FadeIn(9, _FirstFlush(s)),
          ],
        ),
      ),
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16, 20, 16, 8), child: Text(tr('beacons'), style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w800)))),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 118,
          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), children: [
            for (final b in s.beacons) Padding(padding: const EdgeInsets.only(right: 12), child: SizedBox(width: 150, child: _BeaconCard(b))),
          ]),
        ),
      ),
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(16), child: _TrapCard(s))),
      const SliverToBoxAdapter(child: SizedBox(height: 16)),
    ]);
  }
}

class _Header extends StatelessWidget {
  final AppState s;
  const _Header(this.s);
  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0C4A6E), kBlue, kTeal], begin: Alignment.topLeft, end: Alignment.bottomRight)),
        child: Stack(children: [
          const Positioned(left: 0, right: 0, bottom: 0, child: Waves(height: 46)),
          SafeArea(bottom: false, child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${tr('hello')}, ${s.officer ? tr('officer') : tr('citizen')} 👋', style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 4),
                Text(tr('station'), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
              ])),
              Container(
                padding: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: .16), borderRadius: BorderRadius.circular(30)),
                child: Row(children: [Pulse(s.live ? kGreen : kAmber, size: 8), Text(s.live ? tr('live') : tr('demo'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))]),
              ),
            ]),
          )),
        ]),
      );
}

class _FirstFlush extends StatelessWidget {
  final AppState s;
  const _FirstFlush(this.s);
  @override
  Widget build(BuildContext context) => Glass(pad: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          AnimatedRotation(turns: s.valveOpen ? .25 : 0, duration: const Duration(milliseconds: 500), child: Icon(Icons.settings_input_component_rounded, color: s.valveOpen ? kTeal : Colors.grey)),
          const SizedBox(width: 8),
          Expanded(child: Text(tr('firstFlush'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        ]),
        const Spacer(),
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: (s.valveOpen ? kTeal : Colors.grey).withValues(alpha: .15), borderRadius: BorderRadius.circular(10)),
          child: Text(s.valveOpen ? tr('valveOpen') : tr('valveClosed'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: s.valveOpen ? kTeal : Colors.grey)),
        ),
      ]));
}

class _BeaconCard extends StatelessWidget {
  final Beacon b;
  const _BeaconCard(this.b);
  @override
  Widget build(BuildContext context) {
    final c = levelColor(b.level);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: c.withValues(alpha: .12), border: Border.all(color: c.withValues(alpha: .5), width: 1.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Pulse(c, size: 8), Text(b.id, style: TextStyle(fontWeight: FontWeight.w800, color: c)), if (b.sos) const Text('  🆘')]),
        Text(b.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
        const Spacer(),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          AnimNum(b.depth, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c)),
          const Text(' cm  '),
          Text(tr(['safe', 'warn', 'danger'][b.level]), style: TextStyle(fontSize: 12, color: c, fontWeight: FontWeight.w700)),
        ]),
      ]),
    );
  }
}

class _TrapCard extends StatelessWidget {
  final AppState s;
  const _TrapCard(this.s);
  @override
  Widget build(BuildContext context) {
    final p = s.trapPct / 100, c = p > .6 ? kRed : p > .4 ? kAmber : kGreen;
    return Glass(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.delete_sweep_rounded, color: kAmber),
        const SizedBox(width: 8),
        Expanded(child: Text('${tr('trash')} · Lê Duẩn', style: const TextStyle(fontWeight: FontWeight.w700))),
        Text('${s.trapPct.toStringAsFixed(0)}% ${tr('full')}', style: TextStyle(fontWeight: FontWeight.w800, color: c)),
      ]),
      const SizedBox(height: 10),
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: TweenAnimationBuilder<double>(tween: Tween(end: p), duration: const Duration(milliseconds: 700), builder: (_, v, _) => LinearProgressIndicator(value: v, minHeight: 10, color: c)),
      ),
      const SizedBox(height: 12),
      Row(children: [
        Text('🏅 ${tr('greenPoints')}: ${s.greenPoints}', style: Theme.of(context).textTheme.bodySmall),
        const Spacer(),
        if (s.officer)
          FilledButton.tonalIcon(icon: const Icon(Icons.cleaning_services_rounded, size: 18), label: Text(tr('dispatch')), onPressed: () { s.dispatchCleanup(); toast(context, tr('dispatched'), kGreen); }),
      ]),
    ]));
  }
}

// ───────────────────────── Bản đồ ─────────────────────────
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = Scope.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: Text(tr('map'), style: const TextStyle(fontWeight: FontWeight.w800)), actions: [
        if (s.officer) IconButton(tooltip: tr('broadcast'), icon: const Icon(Icons.cell_tower_rounded), onPressed: () { s.broadcast(); toast(context, tr('broadcasted'), kAmber); }),
      ]),
      body: LayoutBuilder(builder: (context, box) {
        final z = Size(box.maxWidth, box.maxHeight);
        Widget pin(Offset p, Widget w, VoidCallback onTap) => Positioned(left: p.dx * z.width - 21, top: p.dy * z.height - 21, child: GestureDetector(onTap: onTap, child: w));
        return InteractiveViewer(
          maxScale: 3,
          child: Stack(children: [
            Positioned.fill(child: CustomPaint(painter: AreaMapPainter(s, dark))),
            pin(const Offset(.55, .5), Stack(alignment: Alignment.center, children: [const Pulse(kPurple, size: 14), Icon(Icons.sensors, size: 12, color: Colors.white.withValues(alpha: .9))]), () => _stationSheet(context, s)),
            for (final b in s.beacons) pin(b.pos, Pulse(levelColor(b.level), size: 14), () => _beaconSheet(context, s, b)),
            Positioned(left: 12, bottom: 12, child: Glass(pad: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (final (i, k) in ['safe', 'warn', 'danger'].indexed) Row(children: [Container(width: 10, height: 10, decoration: BoxDecoration(color: levelColor(i), shape: BoxShape.circle)), const SizedBox(width: 6), Text(tr(k), style: const TextStyle(fontSize: 12))]),
              Row(children: [Container(width: 10, height: 10, decoration: const BoxDecoration(color: kPurple, shape: BoxShape.circle)), const SizedBox(width: 6), Text(tr('station'), style: const TextStyle(fontSize: 12))]),
            ]))),
          ]),
        );
      }),
    );
  }

  void _stationSheet(BuildContext context, AppState s) => showModalBottomSheet(context: context, showDragHandle: true, builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tr('station'), style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('${tr(s.ai)} · ${tr('${s.ai}D')}'),
          const SizedBox(height: 14),
          Text(tr('history'), style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          _Stats('TDS (ppm)', s.hist['tds']!, kPurple),
          _Stats('${tr('turb')} (NTU)', s.hist['turb']!, kTeal),
          _Stats('${tr('depth')} (cm)', s.hist['depth']!, kBlue),
        ]),
      ));

  void _beaconSheet(BuildContext context, AppState s, Beacon b) => showModalBottomSheet(context: context, showDragHandle: true, builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${b.id} · ${b.name}', style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Row(children: [
            Gauge(value: b.depth / 60, color: levelColor(b.level), size: 110, center: Text('${b.depth.toStringAsFixed(0)}cm', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18))),
            const SizedBox(width: 16),
            Expanded(child: Text(tr(['safe', 'warn', 'danger'][b.level]), style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: levelColor(b.level)))),
          ]),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: kRed, padding: const EdgeInsets.all(14)),
            icon: const Icon(Icons.sos_rounded), label: Text(tr('sos')),
            onPressed: () { s.sos(b); Navigator.pop(context); toast(context, 'SOS ${b.name}', kRed); },
          )),
        ]),
      ));
}

class _Stats extends StatelessWidget {
  final String label;
  final List<double> d;
  final Color c;
  const _Stats(this.label, this.d, this.c);
  @override
  Widget build(BuildContext context) {
    final avg = d.reduce((a, b) => a + b) / d.length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 12))),
        Expanded(child: Spark(d, c, height: 30)),
        const SizedBox(width: 10),
        Text('${d.reduce(min).toStringAsFixed(0)} / ${avg.toStringAsFixed(0)} / ${d.reduce(max).toStringAsFixed(0)}', style: const TextStyle(fontSize: 11)),
      ]),
    );
  }
}

// ───────────────────────── Cảnh báo ─────────────────────────
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});
  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  String f = 'all';
  static const icons = {'flood': Icons.flood_rounded, 'pollution': Icons.science_rounded, 'cleanup': Icons.cleaning_services_rounded, 'sos': Icons.sos_rounded};
  @override
  Widget build(BuildContext context) {
    final s = Scope.of(context);
    final list = s.alerts.where((a) => f == 'all' || a.kind == f).toList();
    return Scaffold(
      appBar: AppBar(title: Text(tr('alerts'), style: const TextStyle(fontWeight: FontWeight.w800))),
      body: Column(children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            for (final k in ['all', 'flood', 'pollution', 'cleanup', 'sos'])
              Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(tr(k)), selected: f == k, onSelected: (_) => setState(() => f = k))),
          ]),
        ),
        Expanded(
          child: list.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.check_circle_outline, size: 64, color: kGreen), Text(tr('noAlerts'))]))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final a = list[i], c = levelColor(a.sev);
                    return FadeIn(min(i, 6), Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Glass(pad: const EdgeInsets.all(12), child: Row(children: [
                        Container(width: 44, height: 44, decoration: BoxDecoration(color: c.withValues(alpha: .15), borderRadius: BorderRadius.circular(14)), child: Icon(icons[a.kind], color: c)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(a.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text('${tr(a.kind)} · ${ago(a.at)}', style: Theme.of(context).textTheme.bodySmall),
                        ])),
                        Container(width: 6, height: 36, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
                      ])),
                    ));
                  },
                ),
        ),
      ]),
    );
  }
}

// ───────────────────────── Phản ánh ─────────────────────────
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(), phone = TextEditingController(), desc = TextEditingController();
  String type = 'tColor';
  double sev = 1;
  bool gps = true, sending = false;
  int photos = 0;

  Future<void> _submit() async {
    if (!form.currentState!.validate()) return;
    setState(() => sending = true);
    // shortcut: giả lập gửi; bản thật gửi multipart tới POST /api/reports của server FastAPI cũ.
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => sending = false);
    final code = 'AQ-${DateTime.now().millisecondsSinceEpoch % 1000000}';
    await showDialog(context: context, builder: (_) => AlertDialog(
          icon: TweenAnimationBuilder<double>(tween: Tween(begin: 0, end: 1), duration: const Duration(milliseconds: 700), curve: Curves.elasticOut, builder: (_, v, _) => Transform.scale(scale: v, child: const Icon(Icons.check_circle_rounded, color: kGreen, size: 72))),
          title: Text(tr('sent')),
          content: Text('${tr('trackCode')}: $code', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          actions: [FilledButton(onPressed: () => Navigator.pop(context), child: Text(tr('done')))],
        ));
    form.currentState!.reset();
    name.clear(); phone.clear(); desc.clear();
    setState(() => photos = 0);
  }

  @override
  Widget build(BuildContext context) {
    String? req(String? v) => (v ?? '').trim().isEmpty ? tr('required') : null;
    return Scaffold(
      appBar: AppBar(title: Text(tr('sendReport'), style: const TextStyle(fontWeight: FontWeight.w800))),
      body: Form(
        key: form,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          TextFormField(controller: name, validator: req, decoration: InputDecoration(labelText: tr('name'), prefixIcon: const Icon(Icons.person_outline))),
          const SizedBox(height: 12),
          TextFormField(controller: phone, keyboardType: TextInputType.phone,
              validator: (v) => RegExp(r'^0\d{9}$').hasMatch((v ?? '').trim()) ? null : '0xxxxxxxxx',
              decoration: InputDecoration(labelText: tr('phone'), prefixIcon: const Icon(Icons.phone_outlined))),
          const SizedBox(height: 16),
          Text(tr('type'), style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final (k, e) in [('tColor', '🎨'), ('tSmell', '👃'), ('tFish', '🐟'), ('tFlood', '🌊'), ('tTrash', '🧹')])
              ChoiceChip(label: Text('$e ${tr(k)}'), selected: type == k, onSelected: (_) => setState(() => type = k)),
          ]),
          const SizedBox(height: 16),
          Text('${tr('severity')}: ${tr('sev${sev.round()}')}', style: const TextStyle(fontWeight: FontWeight.w700)),
          Slider(value: sev, max: 2, divisions: 2, activeColor: levelColor(sev.round()), onChanged: (v) => setState(() => sev = v)),
          TextFormField(controller: desc, validator: req, maxLines: 4, decoration: InputDecoration(labelText: tr('desc'), alignLabelWithHint: true)),
          const SizedBox(height: 12),
          SwitchListTile(contentPadding: EdgeInsets.zero, secondary: const Icon(Icons.my_location_rounded), title: Text(tr('gps')), subtitle: gps ? const Text('15.5302, 108.5104') : null, value: gps, onChanged: (v) => setState(() => gps = v)),
          // shortcut: chỉ đếm số ảnh; bản thật dùng image_picker như app cũ.
          OutlinedButton.icon(icon: const Icon(Icons.add_a_photo_outlined), label: Text('${tr('photo')}${photos > 0 ? ' ($photos)' : ''}'), onPressed: () => setState(() => photos++)),
          const SizedBox(height: 20),
          SizedBox(height: 54, child: FilledButton(
            onPressed: sending ? null : _submit,
            child: AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: sending
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.send_rounded), const SizedBox(width: 8), Text(tr('submit'))])),
          )),
        ]),
      ),
    );
  }
}

// ───────────────────────── Thêm: AI, học tập, cài đặt ─────────────────────────
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = Scope.of(context);
    final tips = [
      ('💧', 'TDS', lang == 'vi' ? 'Tổng chất rắn hoà tan. Nước sông sạch thường < 500 ppm.' : 'Total dissolved solids. Clean river water is usually < 500 ppm.'),
      ('🌧️', 'First-flush', lang == 'vi' ? 'Nước mưa 15–20 phút đầu cuốn theo bụi, dầu, rác nên bẩn nhất.' : 'The first 15–20 min of rain carry dust, oil and trash.'),
      ('🗑️', lang == 'vi' ? 'Rác & ngập' : 'Trash & floods', lang == 'vi' ? 'Cống tắc rác là nguyên nhân hàng đầu gây ngập cục bộ trong đô thị.' : 'Blocked drains are a top cause of local urban flooding.'),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(tr('more'), style: const TextStyle(fontWeight: FontWeight.w800))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        FadeIn(0, Glass(
          gradient: const LinearGradient(colors: [kPurple, kBlue]),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.smart_toy_rounded, color: kPurple)),
            title: Text(tr('askAI'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            subtitle: Text(tr('askHint'), style: const TextStyle(color: Colors.white70)),
            trailing: const Icon(Icons.chevron_right, color: Colors.white),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen())),
          ),
        )),
        const SizedBox(height: 20),
        Text(tr('learn'), style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        for (final (i, t) in tips.indexed)
          FadeIn(i + 1, Padding(padding: const EdgeInsets.only(bottom: 10), child: Glass(pad: const EdgeInsets.all(14), child: Row(children: [
            Text(t.$1, style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t.$2, style: const TextStyle(fontWeight: FontWeight.w700)), Text(t.$3, style: const TextStyle(fontSize: 13))])),
          ])))),
        const SizedBox(height: 12),
        Text(tr('settings'), style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Glass(pad: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), child: Column(children: [
          ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.translate_rounded), title: Text(tr('language')), trailing: LangSwitch(s: s)),
          SwitchListTile(contentPadding: EdgeInsets.zero, secondary: const Icon(Icons.dark_mode_rounded), title: Text(tr('dark')), value: s.dark, onChanged: (_) => s.toggleDark()),
          ListTile(
            contentPadding: EdgeInsets.zero, leading: const Icon(Icons.hub_rounded), title: Text(tr('mqtt')),
            subtitle: Text('${s.mqttHost} · ${s.mqttTopic}'),
            trailing: FilledButton.tonal(onPressed: () async {
              final e = await s.connect();
              if (context.mounted) toast(context, e ?? '${tr('live')} ✓', e == null ? kGreen : kRed);
            }, child: Text(tr('connect'))),
          ),
          ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.logout_rounded, color: kRed), title: Text(tr('logout'), style: const TextStyle(color: kRed)),
              onTap: () => Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const Splash()), (_) => false)),
        ])),
        const SizedBox(height: 16),
        Center(child: Text('AquaSentinel AI 2.0 · v2.0.0', style: Theme.of(context).textTheme.bodySmall)),
      ]),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final msgs = <(bool, String)>[];
  final ctl = TextEditingController();
  bool typing = false;

  // shortcut: trả lời theo từ khoá + số liệu trạm; bản thật gọi API LLM qua server FastAPI.
  String _answer(String q, AppState s) {
    final t = q.toLowerCase(), vi = lang == 'vi';
    if (t.contains('tds')) return vi ? 'TDS hiện tại ${s.tds.toStringAsFixed(0)} ppm. Dưới 500 ppm là bình thường với nước sông; tăng vọt khi không mưa là dấu hiệu nghi xả thải.' : 'TDS is ${s.tds.toStringAsFixed(0)} ppm. Under 500 ppm is normal; a spike without rain suggests discharge.';
    if (t.contains('ngập') || t.contains('flood')) return vi ? 'Nguy cơ ngập 3 giờ tới: ${tr('risk${s.risk}')}. Hộp cột sâu nhất: ${s.beacons.reduce((a, b) => a.depth > b.depth ? a : b).name}.' : 'Flood risk next 3h: ${tr('risk${s.risk}')}.';
    if (t.contains('first') || t.contains('lọc')) return vi ? 'First-flush là nước mưa đầu cơn, bẩn nhất. Hệ thống mở van dẫn qua bể lọc cát–sỏi–than hoạt tính trước khi ra kênh.' : 'First-flush is the dirtiest early rainwater; we divert it through a sand–gravel–carbon filter.';
    if (t.contains('đục') || t.contains('turb')) return vi ? 'Độ đục ${s.turb.toStringAsFixed(0)} NTU. AI kết luận: ${tr(s.ai)} — ${tr('${s.ai}D')}' : 'Turbidity ${s.turb.toStringAsFixed(0)} NTU. AI: ${tr(s.ai)}.';
    return vi ? 'Tình trạng trạm: ${tr(s.ai)}. Bạn có thể hỏi về TDS, độ đục, ngập hoặc first-flush.' : 'Station status: ${tr(s.ai)}. Ask about TDS, turbidity, flooding or first-flush.';
  }

  void _send(AppState s) async {
    final q = ctl.text.trim();
    if (q.isEmpty) return;
    ctl.clear();
    setState(() { msgs.add((true, q)); typing = true; });
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) setState(() { typing = false; msgs.add((false, _answer(q, s))); });
  }

  @override
  Widget build(BuildContext context) {
    final s = Scope.of(context), cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(tr('askAI'))),
      body: Column(children: [
        Expanded(child: ListView(padding: const EdgeInsets.all(12), children: [
          for (final m in msgs)
            FadeIn(0, Align(
              alignment: m.$1 ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
                constraints: const BoxConstraints(maxWidth: 300),
                decoration: BoxDecoration(color: m.$1 ? kBlue : cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(16)),
                child: Text(m.$2, style: TextStyle(color: m.$1 ? Colors.white : null)),
              ),
            )),
          if (typing) const Align(alignment: Alignment.centerLeft, child: Padding(padding: EdgeInsets.all(8), child: SizedBox(width: 40, child: LinearProgressIndicator()))),
        ])),
        SafeArea(child: Padding(padding: const EdgeInsets.all(8), child: Row(children: [
          Expanded(child: TextField(controller: ctl, onSubmitted: (_) => _send(s), decoration: InputDecoration(hintText: tr('askHint'), isDense: true))),
          const SizedBox(width: 8),
          IconButton.filled(onPressed: () => _send(s), icon: const Icon(Icons.send_rounded)),
        ]))),
      ]),
    );
  }
}
