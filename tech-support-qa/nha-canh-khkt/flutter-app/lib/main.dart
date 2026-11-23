import 'package:flutter/material.dart';
import 'i18n.dart';
import 'state.dart';
import 'widgets.dart';
import 'screens.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final s = AppState();
  runApp(NhaCanhApp(state: s));
  s.init();
}

class Scope extends InheritedNotifier<AppState> {
  const Scope({super.key, required AppState state, required super.child}) : super(notifier: state);
  static AppState of(BuildContext c) => c.dependOnInheritedWidgetOfExactType<Scope>()!.notifier!;
}

class NhaCanhApp extends StatelessWidget {
  final AppState state;
  const NhaCanhApp({super.key, required this.state});
  ThemeData _theme(Brightness b) => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: kBlue, brightness: b),
        inputDecorationTheme: InputDecorationTheme(filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)),
      );
  @override
  Widget build(BuildContext context) => Scope(
        state: state,
        child: ListenableBuilder(
          listenable: state,
          builder: (_, _) => MaterialApp(
            title: 'Nhà Canh',
            debugShowCheckedModeBanner: false,
            theme: _theme(Brightness.light),
            darkTheme: _theme(Brightness.dark),
            themeMode: state.dark ? ThemeMode.dark : ThemeMode.light,
            // ?tab=0..4 mở thẳng 1 tab (để chụp ảnh giới thiệu trên bản web)
            home: Uri.base.queryParameters['tab'] == null ? const Splash() : Shell(initial: int.parse(Uri.base.queryParameters['tab']!)),
          ),
        ),
      );
}

class Splash extends StatefulWidget {
  const Splash({super.key});
  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> with SingleTickerProviderStateMixin {
  late final c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..forward();
  @override
  void dispose() { c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final s = Scope.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF312E81), kBlue, kTeal])),
        child: Stack(children: [
          const Positioned(left: 0, right: 0, bottom: 0, child: Waves(height: 160)),
          SafeArea(child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              Align(alignment: Alignment.topRight, child: LangSwitch(s: s, onDark: true)),
              const Spacer(),
              ScaleTransition(
                scale: CurvedAnimation(parent: c, curve: Curves.elasticOut),
                child: Stack(alignment: Alignment.center, children: [
                  const Pulse(Colors.white24, size: 90),
                  Container(
                    width: 110, height: 110,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .16), border: Border.all(color: Colors.white38, width: 2)),
                    child: const Icon(Icons.home_rounded, color: Colors.white, size: 62),
                  ),
                  const Positioned(bottom: 26, child: Icon(Icons.shield_rounded, color: Color(0xFF86EFAC), size: 26)),
                ]),
              ),
              const SizedBox(height: 20),
              FadeTransition(opacity: c, child: Text(tr('app'), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 2))),
              const SizedBox(height: 6),
              FadeTransition(opacity: c, child: Text(tr('slogan'), style: const TextStyle(color: Colors.white70, fontSize: 15))),
              const Spacer(),
              FadeIn(2, Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
                for (final (i, k) in [(Icons.local_fire_department_rounded, 'gasShort'), (Icons.thermostat_rounded, 'temp'), (Icons.directions_run_rounded, 'motion'), (Icons.water_drop_rounded, 'water')])
                  Chip(avatar: Icon(i, size: 18, color: Colors.white), label: Text(tr(k), style: const TextStyle(color: Colors.white)), backgroundColor: Colors.white.withValues(alpha: .14), side: BorderSide.none),
              ])),
              const SizedBox(height: 28),
              FadeIn(3, SizedBox(width: double.infinity, height: 56, child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: kBlue, textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                onPressed: () => Navigator.of(context).pushReplacement(PageRouteBuilder(
                  transitionDuration: const Duration(milliseconds: 600),
                  pageBuilder: (_, _, _) => const Shell(),
                  transitionsBuilder: (_, a, _, ch) => FadeTransition(opacity: a, child: ScaleTransition(scale: Tween(begin: 1.04, end: 1.0).animate(a), child: ch)),
                )),
                child: Text(tr('start')),
              ))),
              const SizedBox(height: 36),
            ]),
          )),
        ]),
      ),
    );
  }
}

class LangSwitch extends StatelessWidget {
  final AppState s;
  final bool onDark;
  const LangSwitch({super.key, required this.s, this.onDark = false});
  @override
  Widget build(BuildContext context) => SegmentedButton<String>(
        style: onDark ? SegmentedButton.styleFrom(foregroundColor: Colors.white, selectedForegroundColor: kBlue, selectedBackgroundColor: Colors.white, side: const BorderSide(color: Colors.white54)) : null,
        showSelectedIcon: false,
        segments: const [ButtonSegment(value: 'vi', label: Text('VI')), ButtonSegment(value: 'en', label: Text('EN'))],
        selected: {lang},
        onSelectionChanged: (v) => s.setLang(v.first),
      );
}

class Shell extends StatefulWidget {
  final int initial;
  const Shell({super.key, this.initial = 0});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  late int i = widget.initial;
  @override
  Widget build(BuildContext context) {
    final s = Scope.of(context);
    final pages = [const HomeScreen(), const AirScreen(), const SecurityScreen(), const WaterScreen(), const HistoryScreen()];
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        transitionBuilder: (ch, a) => FadeTransition(opacity: a, child: SlideTransition(position: Tween(begin: const Offset(0, .03), end: Offset.zero).animate(a), child: ch)),
        child: KeyedSubtree(key: ValueKey('$i$lang'), child: pages[i]),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: i,
        onDestinationSelected: (v) => setState(() => i = v),
        destinations: [
          NavigationDestination(icon: Badge(isLabelVisible: s.alerts.isNotEmpty, label: Text('${s.alerts.length}'), child: const Icon(Icons.home_outlined)), selectedIcon: const Icon(Icons.home_rounded), label: tr('home')),
          NavigationDestination(icon: const Icon(Icons.air_outlined), selectedIcon: const Icon(Icons.air_rounded), label: tr('air')),
          NavigationDestination(icon: const Icon(Icons.shield_outlined), selectedIcon: const Icon(Icons.shield_rounded), label: tr('security')),
          NavigationDestination(icon: const Icon(Icons.water_drop_outlined), selectedIcon: const Icon(Icons.water_drop_rounded), label: tr('water')),
          NavigationDestination(icon: const Icon(Icons.history_rounded), selectedIcon: const Icon(Icons.history_rounded), label: tr('history')),
        ],
      ),
    );
  }
}
