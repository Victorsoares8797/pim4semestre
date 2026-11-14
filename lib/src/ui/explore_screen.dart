import 'package:flutter/material.dart';
import '../application/app_controller.dart';
import 'shell.dart';
import 'theme.dart';
import 'widgets.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({
    super.key,
    required this.controller,
    required this.onRanking,
  });
  final AppController controller;
  final VoidCallback onRanking;
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _search = TextEditingController();
  String _category = 'Todos';
  String _sort = 'Recomendados';
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _normalize(String value) {
    const from = 'áàâãäéèêëíìîïóòôõöúùûüç';
    const to = 'aaaaaeeeeiiiiooooouuuuc';
    var normalized = value.toLowerCase();
    for (var i = 0; i < from.length; i++) {
      normalized = normalized.replaceAll(from[i], to[i]);
    }
    return normalized;
  }

  Future<void> _chooseSort() async {
    final value = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Ordenar restaurantes',
                style: TextStyle(fontFamily: 'Lora', fontSize: 22),
              ),
            ),
            for (final option in [
              'Recomendados',
              'Melhor avaliação',
              'Nome A–Z',
            ])
              ListTile(
                title: Text(option),
                trailing: _sort == option
                    ? const Icon(Icons.check, color: olive)
                    : null,
                onTap: () => Navigator.pop(context, option),
              ),
          ],
        ),
      ),
    );
    if (value != null && mounted) setState(() => _sort = value);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final query = _normalize(_search.text.trim());
    final restaurants = c.restaurants
        .where(
          (r) =>
              (_category == 'Todos' || r.category == _category) &&
              _normalize(
                '${r.name} ${r.category} ${r.neighborhood}',
              ).contains(query),
        )
        .toList();
    if (_sort == 'Melhor avaliação') {
      restaurants.sort((a, b) {
        final score = c.rating(b.id).average.compareTo(c.rating(a.id).average);
        return score == 0 ? a.name.compareTo(b.name) : score;
      });
    } else if (_sort == 'Nome A–Z') {
      restaurants.sort((a, b) => a.name.compareTo(b.name));
    }
    final categories = [
      'Todos',
      ...c.restaurants.map((r) => r.category).toSet(),
    ];
    return PageBody(
      onRefresh: () async {
        final ok = await c.refresh();
        if (!ok && context.mounted) showFeedback(context, c.operationError);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Onde vamos comer?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: orange),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  c.supportsDemo
                      ? 'São Paulo · descubra novos sabores'
                      : 'Descubra novos sabores',
                  style: const TextStyle(color: muted, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Restaurante, cozinha ou bairro',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpar busca',
                      onPressed: () => setState(_search.clear),
                      icon: const Icon(Icons.close),
                    ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) => ChoiceChip(
                label: Text(categories[index]),
                selected: _category == categories[index],
                showCheckmark: false,
                backgroundColor: Colors.white,
                selectedColor: olive,
                labelStyle: TextStyle(
                  color: _category == categories[index] ? Colors.white : muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                side: BorderSide(
                  color: _category == categories[index] ? olive : line,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                onSelected: (_) =>
                    setState(() => _category = categories[index]),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Para conhecer',
                      style: TextStyle(fontFamily: 'Lora', fontSize: 22),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${restaurants.length} ${restaurants.length == 1 ? 'restaurante para descobrir' : 'restaurantes para descobrir'}',
                      style: const TextStyle(fontSize: 12, color: muted),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Ordenar restaurantes',
                onPressed: _chooseSort,
                icon: const Icon(Icons.tune_rounded, color: olive),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (restaurants.isEmpty)
            EmptyState(
              icon: Icons.search_off_rounded,
              title: 'Nenhuma mesa por aqui ainda',
              message: 'Tente outro nome, bairro ou tipo de cozinha.',
              action: OutlinedButton(
                onPressed: () => setState(() {
                  _search.clear();
                  _category = 'Todos';
                }),
                child: const Text('Limpar filtros'),
              ),
            )
          else
            for (var i = 0; i < restaurants.length; i++) ...[
              RestaurantCard(restaurant: restaurants[i], controller: c),
              const SizedBox(height: 18),
              if (i == 2) ...[
                Material(
                  color: softGreen,
                  borderRadius: BorderRadius.circular(16),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    leading: const Icon(
                      Icons.emoji_events_outlined,
                      color: olive,
                    ),
                    title: const Text(
                      'Os mais amados da cidade',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: const Text(
                      'Conheça o Top 10 da comunidade',
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.arrow_forward, size: 18),
                    onTap: widget.onRanking,
                  ),
                ),
                const SizedBox(height: 18),
              ],
            ],
        ],
      ),
    );
  }
}

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({
    super.key,
    required this.controller,
    required this.onExplore,
  });
  final AppController controller;
  final VoidCallback onExplore;
  @override
  Widget build(BuildContext context) {
    final restaurants = controller.restaurants
        .where((r) => controller.favorites.contains(r.id))
        .toList();
    return PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeading(
            eyebrow: 'GUARDE O QUE FAZ BEM',
            title: 'Sua lista de boas mesas.',
            subtitle:
                'Lugares para voltar. E aqueles que você ainda quer conhecer.',
          ),
          const SizedBox(height: 30),
          if (restaurants.isEmpty)
            EmptyState(
              icon: Icons.favorite_border_rounded,
              title: 'Seu próximo favorito espera por você',
              message:
                  'Toque no coração de um restaurante para guardá-lo aqui.',
              action: FilledButton(
                onPressed: onExplore,
                child: const Text('Explorar restaurantes'),
              ),
            )
          else ...[
            Text(
              '${restaurants.length} restaurantes favoritos',
              style: const TextStyle(color: muted, fontSize: 12),
            ),
            const SizedBox(height: 20),
            RestaurantList(restaurants: restaurants, controller: controller),
          ],
        ],
      ),
    );
  }
}
