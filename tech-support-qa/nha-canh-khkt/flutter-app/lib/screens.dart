import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'i18n.dart';
import 'main.dart';
import 'state.dart';
import 'widgets.dart';

String ago(DateTime t) {
  final d = DateTime.now().difference(t);
  final v = d.inMinutes < 1 ? '${d.inSeconds}s' : d.inHours < 1 ? '${d.inMinutes}m' : d.inDays < 1 ? '${d.inHours}h' : '${d.inDays}d';
  return '$v ${tr('ago')}';
}

String f1(double v) => v.isNaN ? '--' : v.toStringAsFixed(1);
TextStyle h2(BuildContext c) => Theme.of(c).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w800);

/// Header gradient + sóng nước dùng chung cho các tab.
class Header extends StatelessWidget {
  final String title, sub;
  final Widget? trailing;
  const Header(this.title, this.sub, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF312E81), kBlue, kTeal], begin: Alignment.topLeft, end: Alignment.bottomRight)),
        child: Stack(children: [
          const Positioned(left: 0, right: 0, bottom: 0, child: Waves(height: 40)),
          SafeArea(bottom: false, child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 12, 36),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(sub, style: const TextStyle(color: Colors.white70)),
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
              ])),
              ?trailing,
              IconButton(icon: const Icon(Icons.settings_rounded, color: Colors.white), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
            ]),
          )),
        ]),
      );
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key});
  @override
  Widget build(BuildContext context) {
    final s = Scope.of(context);
    final (c, t) = s.demo ? (kAmber, tr('demo')) : s.online ? (kGreen, tr('online')) : (kRed, tr('offline'));
    return Container(
      padding: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .16), borderRadius: BorderRadius.circular(30)),
      child: Row(children: [Pulse(c, size: 8), Text(t, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12))]),
    );
  }
}

class Tile extends StatelessWidget {
  final IconData icon;
  final String label, value, unit;
  final Color color;
  final List<double> data;
  final bool alarm;
  const Tile(this.icon, this.label, this.value, this.unit, this.color, {super.key, this.data = const [], this.alarm = false});
  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: alarm ? kRed : Colors.transparent, width: 2)),
        child: Glass(pad: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withValues(alpha: .14), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 18)),
            const SizedBox(width: 8),
            Expanded(child: Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
            if (alarm) const Pulse(kRed, size: 7),
          ]),
          const Spacer(),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: alarm ? kRed : null)),
            Padding(padding: const EdgeInsets.only(left: 4, bottom: 4), child: Text(unit, style: Theme.of(context).textTheme.bodySmall)),
          ]),
          if (data.length > 1) Spark(data, color, height: 22),
        ])),
      );
}

class ChartCard extends StatelessWidget {
  final String title;
  final List<double> d;
  final Color c;
  final double? limit;
  const ChartCard(this.title, this.d, this.c, {super.key, this.limit});
  @override
  Widget build(BuildContext context) {
    final v = d.where((x) => !x.isNaN).toList();
    return Glass(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700))), Text(tr('chart'), style: Theme.of(context).textTheme.bodySmall)]),
      const SizedBox(height: 10),
      Spark(v, c, height: 90),
      const SizedBox(height: 8),
      if (v.isNotEmpty)
        Text('min ${v.reduce(min).toStringAsFixed(1)} · max ${v.reduce(max).toStringAsFixed(1)}${limit != null ? ' · ${tr('threshold')} ${limit!.toStringAsFixed(0)}' : ''}', style: Theme.of(context).textTheme.bodySmall),
    ]));
  }
}

// ───────── Tổng quan ─────────
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = Scope.of(context), r = s.r;
    final ok = s.alerts.isEmpty, c = ok ? kGreen : kRed;
    return ListView(padding: EdgeInsets.zero, children: [
      Header(tr('myHome'), tr('app'), trailing: const StatusPill()),
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          FadeIn(0, AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: LinearGradient(colors: [c, c.withValues(alpha: .7)])),
            child: Row(children: [
              Pulse(Colors.white, size: 16),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: Text(ok ? tr('safe') : tr('danger'), key: ValueKey(ok), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800))),
                Text(ok ? tr('safeSub') : s.alerts.map(tr).join(' · '), style: const TextStyle(color: Colors.white)),
              ])),
              Icon(ok ? Icons.verified_user_rounded : Icons.warning_amber_rounded, color: Colors.white, size: 40),
            ]),
          )),
          if (!ok && s.alerts.contains('aGas')) Padding(padding: const EdgeInsets.only(top: 10), child: Text('⚠ ${tr('gasSafety')}', style: const TextStyle(color: kRed, fontWeight: FontWeight.w600))),
          const SizedBox(height: 14),
          FadeIn(1, Glass(pad: const EdgeInsets.symmetric(horizontal: 14, vertical: 4), child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: AnimatedContainer(duration: const Duration(milliseconds: 300), padding: const EdgeInsets.all(8), decoration: BoxDecoration(shape: BoxShape.circle, color: (s.away ? kPurple : Colors.grey).withValues(alpha: .15)), child: Icon(s.away ? Icons.lock_rounded : Icons.lock_open_rounded, color: s.away ? kPurple : Colors.grey)),
            title: Text(tr('away'), style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(s.away ? tr('awayOn') : tr('awayOff')),
            value: s.away, onChanged: s.setAway,
          ))),
          const SizedBox(height: 18),
          Text(tr('rooms'), style: h2(context)),
          const SizedBox(height: 10),
          if (r != null)
            GridView.count(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.35,
              children: [
                FadeIn(2, Tile(Icons.thermostat_rounded, tr('temp'), f1(r.t), '°C', Colors.orange, data: s.hist.map((e) => e.t).toList(), alarm: s.alerts.contains('aTemp'))),
                FadeIn(3, Tile(Icons.opacity_rounded, tr('hum'), f1(r.h), '%', kTeal, data: s.hist.map((e) => e.h).toList(), alarm: s.alerts.contains('aHum'))),
                FadeIn(4, Tile(Icons.local_fire_department_rounded, tr('gasShort'), '${r.mq}', 'ADC', kRed, data: s.hist.map((e) => e.mq.toDouble()).toList(), alarm: s.alerts.contains('aGas'))),
                FadeIn(5, Tile(Icons.water_rounded, tr('waterLevel'), '${r.water}', 'ADC', kBlue, data: s.hist.map((e) => e.water.toDouble()).toList(), alarm: s.alerts.contains('aWater'))),
                FadeIn(6, Tile(Icons.directions_run_rounded, tr('motion'), r.pir ? tr('yes') : tr('no'), '', kPurple, alarm: s.alerts.contains('aIntruder'))),
                FadeIn(7, Tile(Icons.vibration_rounded, tr('vibration'), r.mpu.toStringAsFixed(2), 'g', Colors.indigo, data: s.hist.map((e) => e.mpu).toList(), alarm: s.alerts.contains('aMpu'))),
              ],
            )
          else
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
          const SizedBox(height: 14),
          Text(tr('disclaimer'), style: Theme.of(context).textTheme.bodySmall),
        ]),
      ),
    ]);
  }
}

// ───────── Không khí ─────────
class AirScreen extends StatelessWidget {
  const AirScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = Scope.of(context), r = s.r;
    final delta = r == null || s.mqBase < 0 ? 0 : r.mq - s.mqBase;
    final lvl = delta > mqDelta ? 2 : delta > mqDelta / 2 ? 1 : 0;
    return ListView(padding: EdgeInsets.zero, children: [
      Header(tr('air'), tr('app')),
      if (r != null) Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        FadeIn(0, Glass(child: Row(children: [
          Gauge(value: max(0, delta) / (mqDelta * 1.5), color: levelColor(lvl), size: 130, center: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.local_fire_department_rounded, color: levelColor(lvl)),
            AnimNum(r.mq.toDouble(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const Text('ADC', style: TextStyle(fontSize: 11)),
          ])),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tr('gas'), style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(s.mqBase < 0 ? tr('calibrating') : '${tr('baseline')}: ${s.mqBase} · Δ ${delta >= 0 ? '+' : ''}$delta', style: TextStyle(color: levelColor(lvl), fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(tr('gasNote'), style: Theme.of(context).textTheme.bodySmall),
          ])),
        ]))),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: FadeIn(1, SizedBox(height: 120, child: Tile(Icons.thermostat_rounded, tr('temp'), f1(r.t), '°C', Colors.orange)))),
          const SizedBox(width: 12),
          Expanded(child: FadeIn(2, SizedBox(height: 120, child: Tile(Icons.device_thermostat_rounded, tr('surface'), f1(r.td), '°C', Colors.deepOrange)))),
        ]),
        const SizedBox(height: 12),
        FadeIn(3, ChartCard('MQ-2 (ADC)', s.hist.map((e) => e.mq.toDouble()).toList(), kRed)),
        const SizedBox(height: 12),
        FadeIn(4, ChartCard('${tr('temp')} (°C)', s.hist.map((e) => e.t).toList(), Colors.orange, limit: tempMax)),
        const SizedBox(height: 12),
        FadeIn(5, ChartCard('${tr('hum')} (%)', s.hist.map((e) => e.h).toList(), kTeal, limit: humMax)),
      ])),
    ]);
  }
}

// ───────── An ninh: hoạt động + camera + ghi chú ─────────
class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});
  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final note = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final s = Scope.of(context), r = s.r;
    Widget sensor(IconData i, String k, bool on, Color c) => Glass(pad: const EdgeInsets.all(12), child: Row(children: [
          AnimatedContainer(duration: const Duration(milliseconds: 300), width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, color: (on ? c : Colors.grey).withValues(alpha: .15)), child: Icon(i, color: on ? c : Colors.grey)),
          const SizedBox(width: 10),
          Expanded(child: Text(tr(k), style: const TextStyle(fontWeight: FontWeight.w600))),
          AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: Text(on ? tr('yes') : tr('no'), key: ValueKey(on), style: TextStyle(fontWeight: FontWeight.w800, color: on ? c : Colors.grey))),
        ]));
    return ListView(padding: EdgeInsets.zero, children: [
      Header(tr('security'), tr('app')),
      if (r != null) Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (s.alerts.contains('aIntruder')) FadeIn(0, Container(
          margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: kRed, borderRadius: BorderRadius.circular(18)),
          child: Row(children: [const Icon(Icons.person_search_rounded, color: Colors.white), const SizedBox(width: 10), Expanded(child: Text(tr('aIntruder'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)))]),
        )),
        GridView.count(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 2.6,
          children: [
            FadeIn(1, sensor(Icons.directions_run_rounded, 'motion', r.pir, kPurple)),
            FadeIn(2, sensor(Icons.graphic_eq_rounded, 'sound', r.snd, kAmber)),
            FadeIn(3, sensor(Icons.light_mode_rounded, 'light', r.light, Colors.amber)),
            FadeIn(4, sensor(Icons.linear_scale_rounded, 'line', r.line, kTeal)),
          ],
        ),
        const SizedBox(height: 12),
        FadeIn(5, ChartCard('MPU6050 (g)', s.hist.map((e) => e.mpu).toList(), Colors.indigo, limit: null)),
        const SizedBox(height: 18),
        Text(tr('camera'), style: h2(context)),
        const SizedBox(height: 10),
        Glass(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          AnimatedSize(duration: const Duration(milliseconds: 300), child: s.photo == null
              ? Container(height: 150, decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: Theme.of(context).colorScheme.surfaceContainerHighest), child: const Icon(Icons.photo_camera_outlined, size: 48, color: Colors.grey))
              : ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.memory(s.photo!, height: 220, fit: BoxFit.cover))),
          const SizedBox(height: 10),
          FilledButton.icon(icon: const Icon(Icons.photo_camera_rounded), label: Text(tr('takePhoto')), onPressed: () async {
            final x = await ImagePicker().pickImage(source: ImageSource.camera, maxWidth: 1280, imageQuality: 80);
            if (x != null) s.setPhoto(await x.readAsBytes());
          }),
          const SizedBox(height: 12),
          TextField(controller: note, decoration: InputDecoration(labelText: tr('note'), prefixIcon: const Icon(Icons.edit_note_rounded))),
          const SizedBox(height: 8),
          OutlinedButton.icon(icon: const Icon(Icons.save_rounded), label: Text(tr('saveNote')), onPressed: () {
            if (note.text.trim().isEmpty) return;
            s.addNote(note.text.trim());
            note.clear();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✓ ${tr('saveNote')}'), behavior: SnackBarBehavior.floating));
          }),
        ])),
        const SizedBox(height: 10),
        Text(tr('gasSafety'), style: Theme.of(context).textTheme.bodySmall),
      ])),
    ]);
  }
}

// ───────── Nước ─────────
class WaterScreen extends StatelessWidget {
  const WaterScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = Scope.of(context), r = s.r;
    return ListView(padding: EdgeInsets.zero, children: [
      Header(tr('water'), tr('app')),
      if (r != null) Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        FadeIn(0, Glass(child: Column(children: [
          SizedBox(height: 200, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _Tank(r.water / 4095, r.water > waterMax),
            const SizedBox(width: 24),
            Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr('waterLevel'), style: const TextStyle(fontWeight: FontWeight.w700)),
              AnimNum(r.water.toDouble(), style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900)),
              Text('ADC · ${tr('threshold')} $waterMax', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              Chip(
                avatar: Icon(r.water > waterMax ? Icons.warning_rounded : Icons.check_circle_rounded, color: Colors.white, size: 18),
                label: Text(r.water > waterMax ? tr('over') : tr('stable'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                backgroundColor: r.water > waterMax ? kRed : kGreen, side: BorderSide.none,
              ),
            ]),
          ])),
        ]))),
        const SizedBox(height: 12),
        FadeIn(1, ChartCard('${tr('waterLevel')} (ADC)', s.hist.map((e) => e.water.toDouble()).toList(), kBlue, limit: waterMax.toDouble())),
      ])),
    ]);
  }
}

/// Bể nước có mặt sóng chuyển động.
class _Tank extends StatelessWidget {
  final double level;
  final bool alarm;
  const _Tank(this.level, this.alarm);
  @override
  Widget build(BuildContext context) => Container(
        width: 110, height: 190,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.grey.withValues(alpha: .5), width: 3)),
        clipBehavior: Clip.antiAlias,
        child: Stack(children: [
          // vạch ngưỡng
          Positioned(left: 0, right: 0, bottom: 184 * waterMax / 4095, child: Container(height: 2, color: kRed.withValues(alpha: .7))),
          Align(alignment: Alignment.bottomCenter, child: TweenAnimationBuilder<double>(
            tween: Tween(end: level.clamp(0.0, 1.0)), duration: const Duration(milliseconds: 900), curve: Curves.easeOutCubic,
            builder: (_, v, _) => SizedBox(height: 184 * v + 12, child: Column(children: [
              Waves(height: 12, colors: [(alarm ? kRed : kTeal).withValues(alpha: .6)]),
              Expanded(child: Container(color: (alarm ? kRed : kTeal).withValues(alpha: .6))),
            ])),
          )),
        ]),
      );
}

// ───────── Lịch sử ─────────
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String f = 'all';
  @override
  Widget build(BuildContext context) {
    final s = Scope.of(context);
    final list = s.log.where((e) => f == 'all' || e.kind == f).toList();
    const meta = {'alert': (Icons.warning_amber_rounded, kRed), 'note': (Icons.edit_note_rounded, kBlue), 'info': (Icons.info_outline_rounded, kTeal)};
    return Column(children: [
      Header(tr('history'), tr('app'), trailing: IconButton(
        icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white), tooltip: tr('clear'),
        onPressed: () async {
          final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: Text('${tr('clear')}?'), actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('✕')),
                FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(tr('clear'))),
              ]));
          if (ok == true) s.clearLog();
        },
      )),
      SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.fromLTRB(12, 12, 12, 0), child: Row(children: [
        for (final (k, l) in [('all', 'all'), ('alert', 'alertsOnly'), ('note', 'notesOnly')])
          Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(tr(l)), selected: f == k, onSelected: (_) => setState(() => f = k))),
      ])),
      Expanded(child: list.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.inbox_rounded, size: 64, color: Colors.grey), Text(tr('noEvents'))]))
          : ListView.builder(
              padding: const EdgeInsets.all(12), itemCount: list.length,
              itemBuilder: (_, i) {
                final e = list[i];
                final (ic, c) = meta[e.kind]!;
                return FadeIn(min(i, 6), Padding(padding: const EdgeInsets.only(bottom: 10), child: Glass(pad: const EdgeInsets.all(12), child: Row(children: [
                  Container(width: 42, height: 42, decoration: BoxDecoration(color: c.withValues(alpha: .14), borderRadius: BorderRadius.circular(14)), child: Icon(ic, color: c)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(e.kind == 'note' ? e.text : tr(e.text), style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text('${e.at.day}/${e.at.month} ${e.at.hour.toString().padLeft(2, '0')}:${e.at.minute.toString().padLeft(2, '0')} · ${ago(e.at)}', style: Theme.of(context).textTheme.bodySmall),
                  ])),
                ]))));
              },
            )),
    ]);
  }
}

// ───────── Cài đặt ─────────
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final ip = TextEditingController(text: Scope.of(context).ip);
  @override
  Widget build(BuildContext context) {
    final s = Scope.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(tr('settings'), style: const TextStyle(fontWeight: FontWeight.w800))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Glass(pad: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), child: Column(children: [
          ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.translate_rounded), title: Text(tr('language')), trailing: LangSwitch(s: s)),
          SwitchListTile(contentPadding: EdgeInsets.zero, secondary: const Icon(Icons.dark_mode_rounded), title: Text(tr('dark')), value: s.dark, onChanged: s.setDark),
          SwitchListTile(contentPadding: EdgeInsets.zero, secondary: const Icon(Icons.notifications_active_rounded), title: Text(tr('notif')), value: s.notify, onChanged: s.setNotify),
        ])),
        const SizedBox(height: 14),
        Glass(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SwitchListTile(contentPadding: EdgeInsets.zero, secondary: const Icon(Icons.science_rounded), title: Text(tr('simMode')), value: s.demo, onChanged: s.setDemo),
          const SizedBox(height: 8),
          TextField(controller: ip, enabled: !s.demo, keyboardType: TextInputType.url, decoration: InputDecoration(labelText: tr('espIp'), prefixIcon: const Icon(Icons.router_rounded), hintText: '192.168.1.50')),
          const SizedBox(height: 10),
          FilledButton.tonalIcon(icon: const Icon(Icons.wifi_find_rounded), label: Text(tr('test')), onPressed: s.demo ? null : () async {
            s.setIp(ip.text);
            String msg;
            try { await s.fetch(); msg = '✓ ${tr('ok')}'; } catch (e) { msg = '✕ ${tr('offline')}: $e'; }
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
          }),
        ])),
        const SizedBox(height: 16),
        Text(tr('disclaimer'), style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 6),
        Center(child: Text('NHÀ CANH · v2.0.0', style: Theme.of(context).textTheme.bodySmall)),
      ]),
    );
  }
}
