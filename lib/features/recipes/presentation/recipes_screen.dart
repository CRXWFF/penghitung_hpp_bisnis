import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:penghitung_hpp_bisnis/core/database/database.dart';
import 'package:penghitung_hpp_bisnis/core/providers.dart';
import 'package:penghitung_hpp_bisnis/core/utils/design_widgets.dart';
import 'package:penghitung_hpp_bisnis/features/home/presentation/home_screen.dart';
import 'package:penghitung_hpp_bisnis/features/recipes/presentation/recipe_editor_screen.dart';

/// No dedicated mock; reuses the Dashboard recipe card so the Resep tab stays
/// visually consistent with screen_mock/Dashboard_dan_Resep_Terakhir.html.
class RecipesScreen extends ConsumerStatefulWidget {
  const RecipesScreen({super.key});

  @override
  ConsumerState<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends ConsumerState<RecipesScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = ref.watch(recipeRepositoryProvider);

    return StreamBuilder<List<Recipe>>(
      stream: repo.watchAll(query: _query),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final recipes = snap.data!;

        return Column(
          children: [
            const AppHeader(title: 'Recipe & HPP Manager', subtitle: 'Resep'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  Text('Daftar Resep', style: theme.textTheme.headlineLarge),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v),
                    style: theme.textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Cari resep...',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      prefixIcon: Icon(Icons.search, size: 20, color: theme.colorScheme.outline),
                      prefixIconConstraints: const BoxConstraints(minWidth: 40),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.cancel, size: 18),
                              color: theme.colorScheme.outline,
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _query = '');
                              },
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RecipeEditorScreen()),
                      ),
                      icon: const Icon(Icons.add_circle, size: 20),
                      label: const Text('Buat Resep Baru'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (recipes.isEmpty)
                    AppEmptyState(
                      icon: Icons.menu_book_outlined,
                      title: _query.isNotEmpty ? 'Resep tidak ditemukan' : 'Belum ada resep',
                      subtitle: _query.isNotEmpty
                          ? 'Coba kata kunci lain.'
                          : 'Tambahkan resep pertama\nuntuk mulai menghitung HPP.',
                      action: FilledButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RecipeEditorScreen()),
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text('Tambah Resep'),
                      ),
                    )
                  else
                    ...recipes.map((r) => _SwipeToDelete(
                          key: ValueKey('recipe-${r.id}'),
                          recipeName: r.name,
                          onDelete: () => repo.delete(r.id),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: RecipeCostCard(recipe: r),
                          ),
                        )),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SwipeToDelete extends StatelessWidget {
  const _SwipeToDelete({
    super.key,
    required this.recipeName,
    required this.onDelete,
    required this.child,
  });

  final String recipeName;
  final VoidCallback onDelete;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('dismiss-$recipeName'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete, color: Theme.of(context).colorScheme.onErrorContainer),
      ),
      confirmDismiss: (_) async {
        final res = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Hapus resep "$recipeName"?'),
            content: const Text(
              'Resep beserta bahan dan biaya tambahan akan dihapus permanen. '
              'Riwayat kalkulasi juga ikut terhapus.',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error,
                  minimumSize: const Size(88, 44),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Hapus'),
              ),
            ],
          ),
        );
        return res ?? false;
      },
      onDismissed: (_) => onDelete(),
      child: child,
    );
  }
}
