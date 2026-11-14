import 'package:flutter/material.dart';
import '../application/app_controller.dart';
import '../domain/models.dart';
import 'restaurant_screen.dart';
import 'theme.dart';

String formatDishPrice(double price) =>
    'R\$ ${price.toStringAsFixed(2).replaceAll('.', ',')}';

class Brand extends StatelessWidget {
  const Brand({super.key, this.light = false, this.large = false});
  final bool light, large;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: large ? 48 : 38,
        height: large ? 48 : 38,
        decoration: BoxDecoration(
          color: light ? Colors.white : softGreen,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(5),
        child: Image.asset('assets/images/buillon.png'),
      ),
      const SizedBox(width: 10),
      Text(
        'buillon',
        style: TextStyle(
          fontFamily: 'Lora',
          fontSize: large ? 34 : 27,
          fontWeight: FontWeight.w700,
          letterSpacing: -1,
          color: light ? Colors.white : olive,
        ),
      ),
      Text(
        '.',
        style: TextStyle(
          fontSize: large ? 38 : 32,
          color: light ? const Color(0xFFEFB48F) : orange,
        ),
      ),
    ],
  );
}

class Photo extends StatelessWidget {
  const Photo(
    this.path, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });
  final String path;
  final double? width, height;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) {
    if (path.isEmpty) return _placeholder();
    return path.startsWith('https://') || path.startsWith('http://')
        ? Image.network(
            path,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: _error,
          )
        : Image.asset(
            path,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: _error,
          );
  }

  Widget _error(BuildContext context, Object error, StackTrace? stack) =>
      _placeholder();

  Widget _placeholder() => Container(
    width: width,
    height: height,
    color: softGreen,
    alignment: Alignment.center,
    child: const Icon(Icons.restaurant_outlined, color: olive, size: 36),
  );
}

class Avatar extends StatelessWidget {
  const Avatar(this.path, {super.key, this.radius = 22});
  final String path;
  final double radius;
  @override
  Widget build(BuildContext context) => ClipOval(
    child: path.isEmpty
        ? CircleAvatar(
            radius: radius,
            backgroundColor: softGreen,
            child: const Icon(Icons.person_outline, color: olive),
          )
        : Photo(path, width: radius * 2, height: radius * 2),
  );
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color = orange});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: TextStyle(
      fontSize: 10,
      letterSpacing: 2.1,
      fontWeight: FontWeight.w800,
      color: color,
    ),
  );
}

class PageHeading extends StatelessWidget {
  const PageHeading({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });
  final String eyebrow, title, subtitle;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Eyebrow(eyebrow),
      const SizedBox(height: 12),
      Text(title, style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 8),
      Text(subtitle, style: const TextStyle(color: muted, height: 1.6)),
    ],
  );
}

class RatingBadge extends StatelessWidget {
  const RatingBadge(this.rating, {super.key});
  final RatingSummary rating;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: softGreen,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, size: 17, color: olive),
        const SizedBox(width: 3),
        Text(
          rating.label,
          style: const TextStyle(
            color: olive,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class Stars extends StatelessWidget {
  const Stars(this.value, {super.key, this.size = 16});
  final int value;
  final double size;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(
      5,
      (i) => Icon(
        i < value ? Icons.star_rounded : Icons.star_outline_rounded,
        color: orange,
        size: size,
      ),
    ),
  );
}

void showFeedback(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

Future<void> changeFavorite(
  BuildContext context,
  AppController controller,
  String id,
) async {
  final wasFavorite = controller.favorites.contains(id);
  final ok = await controller.toggleFavorite(id);
  if (context.mounted) {
    showFeedback(
      context,
      ok
          ? (wasFavorite
                ? 'Restaurante removido dos favoritos.'
                : 'Restaurante salvo nos favoritos.')
          : controller.operationError,
    );
  }
}

void openRestaurant(
  BuildContext context,
  AppController controller,
  Restaurant restaurant,
) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          RestaurantScreen(controller: controller, restaurant: restaurant),
    ),
  );
}

class RestaurantCard extends StatelessWidget {
  const RestaurantCard({
    super.key,
    required this.restaurant,
    required this.controller,
  });
  final Restaurant restaurant;
  final AppController controller;
  @override
  Widget build(BuildContext context) {
    final rating = controller.rating(restaurant.id);
    final favorite = controller.favorites.contains(restaurant.id);
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openRestaurant(context, controller, restaurant),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 174,
                  width: double.infinity,
                  child: Photo(restaurant.image),
                ),
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      restaurant.category,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: IconButton.filledTonal(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: favorite ? orange : ink,
                    ),
                    tooltip: favorite
                        ? 'Remover ${restaurant.name} dos favoritos'
                        : 'Favoritar ${restaurant.name}',
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
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    [
                      restaurant.neighborhood,
                      restaurant.price,
                      if (restaurant.isExample) 'Exemplo',
                    ].where((value) => value.isNotEmpty).join('  ·  '),
                    style: const TextStyle(color: muted, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      RatingBadge(rating),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          rating.count == 0
                              ? 'Seja o primeiro a avaliar'
                              : '${rating.count} avaliações',
                          style: const TextStyle(fontSize: 12, color: muted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 17,
                        color: olive,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RestaurantList extends StatelessWidget {
  const RestaurantList({
    super.key,
    required this.restaurants,
    required this.controller,
  });
  final List<Restaurant> restaurants;
  final AppController controller;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < restaurants.length; i++) ...[
        RestaurantCard(restaurant: restaurants[i], controller: controller),
        if (i < restaurants.length - 1) const SizedBox(height: 18),
      ],
    ],
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });
  final IconData icon;
  final String title, message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: line),
    ),
    child: Column(
      children: [
        Icon(icon, size: 40, color: olive),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: muted),
        ),
        if (action != null) ...[const SizedBox(height: 20), action!],
      ],
    ),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        ?trailing,
      ],
    ),
  );
}

String displayDate(DateTime value) {
  final date = value.toLocal();
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
