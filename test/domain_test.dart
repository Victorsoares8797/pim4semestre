import 'package:flutter_test/flutter_test.dart';
import 'package:pim4semestre/src/data/demo_data.dart';
import 'package:pim4semestre/src/domain/models.dart';
import 'package:pim4semestre/src/domain/ranking.dart';

Review review(String id, String restaurant, int rating) => Review(
  id: id,
  restaurantId: restaurant,
  userId: id,
  userName: id,
  userAvatar: '',
  rating: rating,
  comment: 'Comentário de teste',
  createdAt: DateTime(2026),
);

void main() {
  test('Média vazia e cálculo sem arredondamento antecipado', () {
    expect(summarize([]).count, 0);
    expect(summarize([]).label, 'Novo');
    final result = summarize([
      review('1', 'r1', 5),
      review('2', 'r1', 4),
      review('3', 'r1', 5),
    ]);
    expect(result.average, closeTo(14 / 3, .00001));
    expect(result.label, '4,7');
  });
  test(
    'Ranking limita dez, ignora sem nota e desempata por contagem e nome',
    () {
      final restaurants = demoRestaurants();
      final reviews = [
        for (var i = 1; i <= 11; i++) review('u$i', 'r$i', 4),
        review('extra', 'r2', 4),
      ];
      final ranked = rankRestaurants(restaurants, reviews);
      expect(ranked.length, 10);
      expect(ranked.first.id, 'r2');
      expect(ranked.any((r) => r.id == 'r12'), false);
      final rest = ranked.skip(1).map((r) => r.name).toList();
      expect(rest, [...rest]..sort());
    },
  );
  test('Ranking usa média real antes da contagem', () {
    final ranked = rankRestaurants(demoRestaurants(), [
      review('a', 'r1', 5),
      review('b', 'r2', 5),
      review('c', 'r2', 4),
    ]);
    expect(ranked.first.id, 'r1');
  });
  test('Modelos fazem round trip JSON para o futuro adaptador', () {
    for (final r in demoRestaurants()) {
      expect(Restaurant.fromJson(r.toJson()).toJson(), r.toJson());
    }
    expect(UserProfile.fromJson(demoUser.toJson()).toJson(), demoUser.toJson());
    final r = demoReviews().first;
    expect(Review.fromJson(r.toJson()).toJson(), r.toJson());
  });
}
