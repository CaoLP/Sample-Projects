import 'dart:math';
import 'package:flutter/material.dart';
import 'i18n.dart';
import 'state.dart';
import 'widgets.dart';
import 'screens.dart';

void main() => runApp(AquaApp(state: AppState()));

class Scope extends InheritedNotifier<AppState> {
  const Scope({super.key, required AppState state, required super.child}) : super(notifier: state);
  static AppState of(BuildContext c) => c.dependOnInheritedWidgetOfExactType<Scope>()!.notifier!;
}

class AquaApp extends StatelessWidget {
  final AppState state;
  const AquaApp({super.key, required this.state});
  ThemeData _theme(Brightness b) => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: kBlue, brightness: b),
        fontFamily: 'Roboto',
        cardTheme: const CardThemeData(elevation: 0),
        inputDecorationTheme: InputDecorationTheme(filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)),
      );
  @override
  Widget build(BuildContext context) => Scope(
        state: state,
        child: ListenableBuilder(
          listenable: state,
          builder: (_, _) => MaterialApp(
            title: 'AquaSentinel AI',
            debugShowCheckedModeBanner: false,
            theme: _theme(Brightness.light),
            darkTheme: _theme(Brightness.dark),
            themeMode: state.dark ? ThemeMode.dark : ThemeMode.light,
            // ?tab=0..4 mở thẳng 1 tab (dùng để chụp ảnh giới thiệu trên bản web)
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

  void _go(bool officer) async {
    final s = Scope.of(context);
    if (officer && !await showDialog<bool>(context: context, builder: (_) => const LoginDialog()).then((v) => v == true)) return;
    s.officer = officer;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (_, _, _) => const Shell(),
      transitionsBuilder: (_, a, _, ch) => FadeTransition(opacity: a, child: ScaleTransition(scale: Tween(begin: 1.04, end: 1.0).animate(a), child: ch)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final s = Scope.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0C4A6E), kBlue, kTeal])),
        child: Stack(children: [
          const Positioned(left: 0, right: 0, bottom: 0, child: Waves(height: 180)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                Align(alignment: Alignment.topRight, child: LangSwitch(onDark: true, s: s)),
                const Spacer(),
                ScaleTransition(
                  scale: CurvedAnimation(parent: c, curve: Curves.elasticOut),
                  child: Container(
                    width: 112, height: 112,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .15), border: Border.all(color: Colors.white38, width: 2)),
                    child: const Icon(Icons.water_drop_rounded, color: Colors.white, size: 64),
                  ),
                ),
                const SizedBox(height: 22),
                FadeTransition(opacity: c, child: Text(tr('app'), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: .5))),
                const SizedBox(height: 8),
                FadeTransition(opacity: c, child: Text(tr('slogan'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 14))),
                const Spacer(),
                FadeIn(1, _RoleCard(Icons.people_alt_rounded, tr('citizen'), tr('citizenSub'), () => _go(false))),
                const SizedBox(height: 12),
                FadeIn(2, _RoleCard(Icons.admin_panel_settings_rounded, tr('officer'), tr('officerSub'), () => _go(true))),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title, sub;
  final VoidCallback onTap;
  const _RoleCard(this.icon, this.title, this.sub, this.onTap);
  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(children: [
              CircleAvatar(radius: 24, backgroundColor: Colors.white, child: Icon(icon, color: kBlue)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                Text(sub, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ])),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 18),
            ]),
          ),
        ),
      );
}

class LoginDialog extends StatefulWidget {
  const LoginDialog({super.key});
  @override
  State<LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<LoginDialog> {
  final u = TextEditingController(), p = TextEditingController();
  String? err;
  bool hide = true;
  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(tr('login')),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: u, decoration: InputDecoration(labelText: tr('user'), prefixIcon: const Icon(Icons.person))),
          const SizedBox(height: 12),
          TextField(
            controller: p, obscureText: hide,
            decoration: InputDecoration(labelText: tr('pass'), prefixIcon: const Icon(Icons.lock), errorText: err,
                suffixIcon: IconButton(icon: Icon(hide ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => hide = !hide))),
          ),
          const SizedBox(height: 8),
          Text(tr('demoHint'), style: Theme.of(context).textTheme.bodySmall),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('✕')),
          // shortcut: tài khoản demo cứng; bản thật gọi POST /login của server FastAPI (PBKDF2) rồi lưu token.
          FilledButton(onPressed: () => u.text == 'admin' && p.text == '123456' ? Navigator.pop(context, true) : setState(() => err = tr('wrongPass')), child: Text(tr('login'))),
        ],
      );
}

class LangSwitch extends StatelessWidget {
  final AppState s;
  final bool onDark;
  const LangSwitch({super.key, required this.s, this.onDark = false});
  @override
  Widget build(BuildContext context) => SegmentedButton<String>(
        style: onDark ? SegmentedButton.styleFrom(foregroundColor: Colors.white, selectedForegroundColor: kBlue, selectedBackgroundColor: Colors.white, side: const BorderSide(color: Colors.white54)) : null,
        showSelectedIcon: false,
        segments: const [ButtonSegment(value: 'vi', label: Text('🇻🇳 VI')), ButtonSegment(value: 'en', label: Text('🇬🇧 EN'))],
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
    if (Uri.base.queryParameters['officer'] == '1') s.officer = true;
    final unread = s.alerts.where((a) => DateTime.now().difference(a.at).inMinutes < 5).length;
    final pages = [const Dashboard(), const MapScreen(), const AlertsScreen(), const ReportScreen(), const MoreScreen()];
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
          NavigationDestination(icon: const Icon(Icons.dashboard_outlined), selectedIcon: const Icon(Icons.dashboard_rounded), label: tr('overview')),
          NavigationDestination(icon: const Icon(Icons.map_outlined), selectedIcon: const Icon(Icons.map_rounded), label: tr('map')),
          NavigationDestination(icon: Badge(isLabelVisible: unread > 0, label: Text('${min(unread, 9)}'), child: const Icon(Icons.notifications_outlined)), selectedIcon: const Icon(Icons.notifications_rounded), label: tr('alerts')),
          NavigationDestination(icon: const Icon(Icons.campaign_outlined), selectedIcon: const Icon(Icons.campaign_rounded), label: tr('report')),
          NavigationDestination(icon: const Icon(Icons.apps_outlined), selectedIcon: const Icon(Icons.apps_rounded), label: tr('more')),
        ],
      ),
    );
  }
}
