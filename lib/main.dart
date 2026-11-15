// Secure Pass - Mobile Password Strength Checker and Generator
// Works 100% offline. No password is stored or sent anywhere.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const SecurePassApp());

class SecurePassApp extends StatelessWidget {
  const SecurePassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Secure Pass',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF3949AB),
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF3949AB),
        brightness: Brightness.dark,
      ),
      home: const HomePage(),
    );
  }
}

// ---------------------------------------------------------------------------
// Strength logic
// ---------------------------------------------------------------------------

class PasswordRule {
  final String label;
  final bool Function(String) test;
  const PasswordRule(this.label, this.test);
}

final List<PasswordRule> passwordRules = [
  PasswordRule('At least 8 characters', (p) => p.length >= 8),
  PasswordRule('At least 12 characters (recommended)', (p) => p.length >= 12),
  PasswordRule('Contains an uppercase letter (A-Z)',
      (p) => p.contains(RegExp(r'[A-Z]'))),
  PasswordRule('Contains a lowercase letter (a-z)',
      (p) => p.contains(RegExp(r'[a-z]'))),
  PasswordRule('Contains a digit (0-9)', (p) => p.contains(RegExp(r'[0-9]'))),
  PasswordRule('Contains a special character (!@#\$...)',
      (p) => p.contains(RegExp(r'[^A-Za-z0-9]'))),
];

class StrengthResult {
  final int score; // 0 - 100
  final String label;
  final Color color;
  const StrengthResult(this.score, this.label, this.color);
}

StrengthResult evaluate(String p) {
  if (p.isEmpty) return const StrengthResult(0, 'Empty', Colors.grey);
  final passed = passwordRules.where((r) => r.test(p)).length;
  int score = (passed / passwordRules.length * 100).round();
  // Very short passwords are always weak, whatever characters they use.
  if (p.length < 6) score = min(score, 25);
  if (score < 40) return StrengthResult(score, 'Weak', Colors.red);
  if (score < 70) return StrengthResult(score, 'Medium', Colors.orange);
  if (score < 100) return StrengthResult(score, 'Strong', Colors.lightGreen);
  return StrengthResult(score, 'Very strong', Colors.green);
}

// ---------------------------------------------------------------------------
// Home with bottom navigation
// ---------------------------------------------------------------------------

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;
  final _pages = const [CheckerPage(), GeneratorPage(), AboutPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Pass'),
        centerTitle: true,
      ),
      body: SafeArea(child: _pages[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.shield_outlined),
              selectedIcon: Icon(Icons.shield),
              label: 'Check'),
          NavigationDestination(
              icon: Icon(Icons.password_outlined),
              selectedIcon: Icon(Icons.password),
              label: 'Generate'),
          NavigationDestination(
              icon: Icon(Icons.info_outline),
              selectedIcon: Icon(Icons.info),
              label: 'About'),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared widget: strength meter
// ---------------------------------------------------------------------------

class StrengthMeter extends StatelessWidget {
  final String password;
  const StrengthMeter({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    final r = evaluate(password);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(r.label,
                style: TextStyle(
                    color: r.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            Text('${r.score}/100',
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: r.score / 100),
            duration: const Duration(milliseconds: 250),
            builder: (_, v, __) => LinearProgressIndicator(
              value: v,
              minHeight: 12,
              color: r.color,
              backgroundColor: Colors.grey.withOpacity(0.25),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Page 1: Strength checker
// ---------------------------------------------------------------------------

class CheckerPage extends StatefulWidget {
  const CheckerPage({super.key});

  @override
  State<CheckerPage> createState() => _CheckerPageState();
}

class _CheckerPageState extends State<CheckerPage> {
  final _controller = TextEditingController();
  bool _hidden = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = _controller.text;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Check your password',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        const Text('Type a password to see how strong it is.'),
        const SizedBox(height: 20),
        TextField(
          controller: _controller,
          obscureText: _hidden,
          enableSuggestions: false,
          autocorrect: false,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Password',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (p.isNotEmpty)
                  IconButton(
                    tooltip: 'Clear',
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(_controller.clear),
                  ),
                IconButton(
                  tooltip: _hidden ? 'Show' : 'Hide',
                  icon: Icon(
                      _hidden ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _hidden = !_hidden),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        StrengthMeter(password: p),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: passwordRules.map((rule) {
                final ok = rule.test(p);
                return ListTile(
                  dense: true,
                  leading: Icon(ok ? Icons.check_circle : Icons.cancel,
                      color: ok ? Colors.green : Colors.red),
                  title: Text(rule.label),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Your password never leaves this device.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Page 2: Generator
// ---------------------------------------------------------------------------

class GeneratorPage extends StatefulWidget {
  const GeneratorPage({super.key});

  @override
  State<GeneratorPage> createState() => _GeneratorPageState();
}

class _GeneratorPageState extends State<GeneratorPage> {
  static const _upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const _lower = 'abcdefghijklmnopqrstuvwxyz';
  static const _digits = '0123456789';
  static const _symbols = '!@#\$%^&*()-_=+[]{};:,.<>?/';

  final _rng = Random.secure();
  double _length = 16;
  bool _useUpper = true;
  bool _useLower = true;
  bool _useDigits = true;
  bool _useSymbols = true;
  String _password = '';

  @override
  void initState() {
    super.initState();
    _generate();
  }

  bool get _anySelected => _useUpper || _useLower || _useDigits || _useSymbols;

  void _generate() {
    if (!_anySelected) return;
    final sets = <String>[
      if (_useUpper) _upper,
      if (_useLower) _lower,
      if (_useDigits) _digits,
      if (_useSymbols) _symbols,
    ];
    final all = sets.join();
    final len = _length.round();
    // Make sure every selected type appears at least once.
    final chars = <String>[
      for (final s in sets) s[_rng.nextInt(s.length)],
    ];
    while (chars.length < len) {
      chars.add(all[_rng.nextInt(all.length)]);
    }
    chars.shuffle(_rng);
    setState(() => _password = chars.join());
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _password));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password copied to clipboard')),
    );
  }

  Widget _option(String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: (v) {
        onChanged(v);
        _generate();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Generate a password',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SelectableText(
            _anySelected ? _password : 'Select at least one character type',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontFamily: 'monospace', fontSize: 20, letterSpacing: 1),
          ),
        ),
        const SizedBox(height: 16),
        if (_anySelected) StrengthMeter(password: _password),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _anySelected ? _generate : null,
                icon: const Icon(Icons.refresh),
                label: const Text('Generate'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _anySelected ? _copy : null,
                icon: const Icon(Icons.copy),
                label: const Text('Copy'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Length: ${_length.round()}',
            style: Theme.of(context).textTheme.titleMedium),
        Slider(
          value: _length,
          min: 6,
          max: 32,
          divisions: 26,
          label: _length.round().toString(),
          onChanged: (v) {
            setState(() => _length = v);
            _generate();
          },
        ),
        Card(
          child: Column(
            children: [
              _option('Uppercase (A-Z)', _useUpper,
                  (v) => setState(() => _useUpper = v)),
              _option('Lowercase (a-z)', _useLower,
                  (v) => setState(() => _useLower = v)),
              _option('Digits (0-9)', _useDigits,
                  (v) => setState(() => _useDigits = v)),
              _option('Symbols (!@#...)', _useSymbols,
                  (v) => setState(() => _useSymbols = v)),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Page 3: About / tips
// ---------------------------------------------------------------------------

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const _tips = [
    'Use at least 12 characters.',
    'Mix uppercase, lowercase, digits and symbols.',
    'Never reuse the same password on different sites.',
    'Avoid names, birthdays and common words.',
    'Turn on two-factor authentication when you can.',
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Icon(Icons.shield, size: 72, color: Color(0xFF3949AB)),
        const SizedBox(height: 8),
        Text('Secure Pass',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium),
        const Text('Version 1.0.0', textAlign: TextAlign.center),
        const SizedBox(height: 24),
        Text('Password tips', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        ..._tips.map((t) => ListTile(
              dense: true,
              leading: const Icon(Icons.tips_and_updates_outlined),
              title: Text(t),
            )),
        const SizedBox(height: 16),
        const ListTile(
          leading: Icon(Icons.wifi_off),
          title: Text('100% offline'),
          subtitle: Text(
              'This app has no internet permission. Nothing is saved or sent.'),
        ),
        const SizedBox(height: 32),
        const Text(
          'Developed by Hoor',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}
