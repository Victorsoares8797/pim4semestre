import 'package:flutter/material.dart';
import '../application/app_controller.dart';
import '../domain/models.dart';
import '../domain/repository.dart';
import 'review_dialog.dart';
import 'theme.dart';
import 'widgets.dart';

class RestaurantScreen extends StatefulWidget {
  const RestaurantScreen({
    super.key,
    required this.controller,
    required this.restaurant,
  });
  final AppController controller;
  final Restaurant restaurant;
  @override
  State<RestaurantScreen> createState() => _RestaurantScreenState();
}

class _RestaurantScreenState extends State<RestaurantScreen> {
  late Restaurant restaurant = widget.restaurant;
  AppController get controller => widget.controller;
  String? _detailError;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final source = controller.repository;
    if (source is! EstablishmentRepository) return;
    try {
      final updated = await (source as EstablishmentRepository)
          .getRestaurantDetails(restaurant.id);
      if (mounted) {
        setState(() {
          restaurant = updated;
          _detailError = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _detailError = 'Fotos e comentários adicionais indisponíveis.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final rating = controller.rating(restaurant.id);
      final reviews = controller.restaurantReviews(restaurant.id);
      final favorite = controller.favorites.contains(restaurant.id);
      return Scaffold(
        appBar: AppBar(
          title: const Brand(),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: favorite
                  ? 'Remover dos favoritos'
                  : 'Adicionar aos favoritos',
              onPressed: controller.busy
                  ? null
                  : () => changeFavorite(context, controller, restaurant.id),
              icon: Icon(
                favorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: orange,
              ),
            ),
            const SizedBox(width: 14),
          ],
        ),
        body: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: SizedBox(
                        height: 220,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Photo(restaurant.image),
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.center,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Color(0xAA162419),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              left: 24,
                              bottom: 24,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  [restaurant.category, restaurant.price]
                                      .where((value) => value.isNotEmpty)
                                      .join('  ·  '),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(26),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Eyebrow(
                          restaurant.isExample
                              ? 'RESTAURANTE DE EXEMPLO'
                              : 'UMA NOVA EXPERIÊNCIA À MESA',
                        ),
                        const SizedBox(height: 12),
                        Text(
                          restaurant.name,
                          style: Theme.of(
                            context,
                          ).textTheme.headlineLarge?.copyWith(fontSize: 28),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 12,
                          runSpacing: 10,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            RatingBadge(rating),
                            Text(
                              '${rating.count} avaliações',
                              style: const TextStyle(
                                fontSize: 12,
                                color: muted,
                              ),
                            ),
                            const Text('·', style: TextStyle(color: muted)),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  color: muted,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  restaurant.neighborhood,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: muted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (controller.canReview) ...[
                              FilledButton.icon(
                                onPressed: controller.busy
                                    ? null
                                    : () => editReview(
                                        context,
                                        controller,
                                        restaurant,
                                      ),
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                label: Text(
                                  controller.myReview(restaurant.id) == null
                                      ? 'Avaliar restaurante'
                                      : 'Editar minha avaliação',
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            OutlinedButton.icon(
                              onPressed: controller.busy
                                  ? null
                                  : () => changeFavorite(
                                      context,
                                      controller,
                                      restaurant.id,
                                    ),
                              icon: Icon(
                                favorite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                size: 18,
                              ),
                              label: Text(
                                favorite
                                    ? 'Nos seus favoritos'
                                    : 'Salvar nos favoritos',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        const Divider(),
                        const SizedBox(height: 26),
                        const SectionTitle('Um pouco sobre a casa'),
                        Text(
                          restaurant.description,
                          style: const TextStyle(
                            color: muted,
                            height: 1.9,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 22),
                        _Info(
                          Icons.location_on_outlined,
                          restaurant.address.isEmpty
                              ? 'Endereço não informado'
                              : restaurant.address,
                        ),
                        if (restaurant.hours.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _Info(Icons.schedule_rounded, restaurant.hours),
                        ],
                        if (_detailError case final String message)
                          TextButton(
                            onPressed: _loadDetails,
                            child: Text('$message Tentar novamente'),
                          ),
                        if (restaurant.photos.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          const SectionTitle('Fotos do estabelecimento'),
                          SizedBox(
                            height: 128,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: restaurant.photos.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 10),
                              itemBuilder: (_, index) {
                                final photo = restaurant.photos[index];
                                return InkWell(
                                  onTap: () => _viewDish(
                                    context,
                                    Dish(
                                      name: 'Foto do estabelecimento',
                                      image: photo.url,
                                      description: photo.caption,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Photo(
                                      photo.url,
                                      width: 164,
                                      height: 128,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                        if (restaurant.posts.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          const SectionTitle('Comentários do estabelecimento'),
                          for (final post in restaurant.posts)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(post.comment),
                              subtitle: Text(displayDate(post.createdAt)),
                            ),
                        ],
                        const SizedBox(height: 34),
                        const SectionTitle('Sabores para conhecer'),
                        if (restaurant.dishes.isEmpty)
                          const Text(
                            'Cardápio ainda não publicado.',
                            style: TextStyle(color: muted),
                          )
                        else
                          LayoutBuilder(
                            builder: (context, box) {
                              final width = (box.maxWidth * .84).clamp(
                                200.0,
                                300.0,
                              );
                              return SizedBox(
                                height: 262,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: restaurant.dishes.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(width: 16),
                                  itemBuilder: (context, i) {
                                    final dish = restaurant.dishes[i];
                                    return SizedBox(
                                      width: width,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          InkWell(
                                            onTap: () =>
                                                _viewDish(context, dish),
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              child: Photo(
                                                dish.image,
                                                height: 165,
                                                width: width,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            dish.name,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            dish.description,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: muted,
                                            ),
                                          ),
                                          if (dish.price case final price?)
                                            Text(
                                              formatDishPrice(price),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: olive,
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 28),
                        const SectionTitle('Experiências de quem já foi'),
                        Container(
                          padding: const EdgeInsets.all(22),
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: softGreen,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Column(
                                children: [
                                  Text(
                                    rating.label,
                                    style: const TextStyle(
                                      fontFamily: 'Lora',
                                      color: olive,
                                      fontSize: 38,
                                    ),
                                  ),
                                  Text(
                                    '${rating.count} avaliações',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: muted,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 30),
                              Expanded(
                                child: Column(
                                  children: [
                                    for (var star = 5; star >= 1; star--)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 3,
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              '$star',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: olive,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            const Icon(
                                              Icons.star_rounded,
                                              size: 12,
                                              color: olive,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                child: LinearProgressIndicator(
                                                  value: reviews.isEmpty
                                                      ? 0
                                                      : reviews
                                                                .where(
                                                                  (r) =>
                                                                      r.rating ==
                                                                      star,
                                                                )
                                                                .length /
                                                            reviews.length,
                                                  minHeight: 6,
                                                  backgroundColor: const Color(
                                                    0xFFDCE3D6,
                                                  ),
                                                  color: olive,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            SizedBox(
                                              width: 20,
                                              child: Text(
                                                '${reviews.where((r) => r.rating == star).length}',
                                                textAlign: TextAlign.right,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: muted,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (reviews.isEmpty)
                          const EmptyState(
                            icon: Icons.rate_review_outlined,
                            title: 'A primeira história pode ser sua',
                            message:
                                'Já conhece esta casa? Conte como foi a sua experiência.',
                          )
                        else
                          for (final review in reviews)
                            ReviewCard(review: review, controller: controller),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
  void _viewDish(BuildContext context, Dish dish) => showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Photo(dish.image, height: 350, width: 700),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: IconButton.filledTonal(
                      tooltip: 'Fechar foto',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dish.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(dish.description),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Info extends StatelessWidget {
  const _Info(this.icon, this.text);
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: orange),
      const SizedBox(width: 10),
      Expanded(
        child: Text(text, style: const TextStyle(color: muted, fontSize: 12)),
      ),
    ],
  );
}
