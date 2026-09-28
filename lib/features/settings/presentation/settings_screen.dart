import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:penghitung_hpp_bisnis/core/domain/models.dart';
import 'package:penghitung_hpp_bisnis/core/providers.dart';
import 'package:penghitung_hpp_bisnis/core/units/unit.dart';
import 'package:penghitung_hpp_bisnis/core/utils/design_widgets.dart';

/// No mock provided; follows the same header + tonal-card language as the
/// four mocked screens.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late AppSettings _draft;

  @override
  void initState() {
    super.initState();
    _draft = ref.read(appSettingsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Keep the form in sync when settings change from outside this screen
    // (e.g. the header's theme toggle). Riverpod 3 requires ref.listen inside
    // build, and auto-disposes it with the element.
    ref.listen(appSettingsProvider, (previous, next) {
      if (next != _draft) {
        setState(() => _draft = next);
      }
    });

    return Column(
      children: [
        const AppHeader(title: 'Recipe & HPP Manager', subtitle: 'Settings'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Text('Pengaturan', style: theme.textTheme.headlineLarge),
              const SizedBox(height: 20),

              _SettingsGroup(
                icon: Icons.payments_outlined,
                title: 'Mata Uang',
                child: DropdownButtonFormField<String>(
                  initialValue: _draft.currency,
                  isDense: true,
                  decoration: const InputDecoration(labelText: 'Mata uang'),
                  items: const [
                    DropdownMenuItem(value: 'IDR', child: Text('Rupiah (IDR)')),
                  ],
                  onChanged: (v) => setState(() => _draft = _draft.copyWith(currency: v!)),
                ),
              ),
              const SizedBox(height: 16),

              _SettingsGroup(
                icon: Icons.straighten,
                title: 'Sistem Satuan',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SegmentedButton<UnitSystem>(
                      segments: const [
                        ButtonSegment(value: UnitSystem.metric, label: Text('Metrik')),
                        ButtonSegment(value: UnitSystem.imperial, label: Text('Imperial')),
                      ],
                      selected: {_draft.unitSystem},
                      onSelectionChanged: (s) =>
                          setState(() => _draft = _draft.copyWith(unitSystem: s.first)),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Metrik: gram, kg, ml, liter, cm, m. Imperial: ounce, pound, fl oz, '
                      'gallon, inch, feet. Data tetap disimpan dalam satuan kanonik '
                      '(gram / ml / cm), jadi mengganti satuan tidak mengubah perhitungan HPP.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              _SettingsGroup(
                icon: Icons.palette_outlined,
                title: 'Tema',
                child: SegmentedButton<ThemeOption>(
                  segments: const [
                    ButtonSegment(value: ThemeOption.system, label: Text('Sistem')),
                    ButtonSegment(value: ThemeOption.light, label: Text('Terang')),
                    ButtonSegment(value: ThemeOption.dark, label: Text('Gelap')),
                  ],
                  selected: {_draft.themeMode},
                  onSelectionChanged: (s) =>
                      setState(() => _draft = _draft.copyWith(themeMode: s.first)),
                ),
              ),
              const SizedBox(height: 24),

              FilledButton.icon(
                onPressed: _save,
                icon: Icon(Icons.save_outlined, size: 18),
                label: const Text('Simpan Pengaturan'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => setState(() => _draft = const AppSettings()),
                icon: Icon(Icons.restore_outlined, size: 18),
                label: const Text('Kembalikan ke Default'),
              ),
              const SizedBox(height: 24),
              const InfoNote(
                icon: Icons.cloud_off,
                title: '100% Offline',
                body: 'Semua resep, bahan, dan riwayat disimpan lokal di perangkat ini. '
                    'Aplikasi tetap berfungsi penuh tanpa koneksi internet.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    await ref.read(settingsRepositoryProvider).save(_draft);
    ref.read(appSettingsProvider.notifier).state = _draft;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pengaturan disimpan')),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.icon, required this.title, required this.child});

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TonalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: theme.colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: 10),
              Text(title, style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
