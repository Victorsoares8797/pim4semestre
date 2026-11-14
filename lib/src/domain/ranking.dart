import 'models.dart';

RatingSummary summarize(Iterable<Review> reviews) {
  final list = reviews.toList();
  if (list.isEmpty) return const RatingSummary(0, 0);
  var total = 0;
  for (final review in list) {
    total += review.rating;
  }
  return RatingSummary(total / list.length, list.length);
}

/// Apenas restaurantes avaliados. Desempate: quantidade de avaliações e nome.
List<Restaurant> rankRestaurants(
  List<Restaurant> restaurants,
  List<Review> reviews,
) {
  final summaries = {
    for (final restaurant in restaurants)
      restaurant.id: summarize(
        reviews.where((r) => r.restaurantId == restaurant.id),
      ),
  };
  final result = restaurants.where((r) => summaries[r.id]!.count > 0).toList();
  result.sort((a, b) {
    final byAverage = summaries[b.id]!.average.compareTo(
      summaries[a.id]!.average,
    );
    if (byAverage != 0) return byAverage;
    final byCount = summaries[b.id]!.count.compareTo(summaries[a.id]!.count);
    return byCount != 0 ? byCount : a.name.compareTo(b.name);
  });
  return result.take(10).toList();
}
