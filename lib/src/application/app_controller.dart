import 'package:flutter/foundation.dart';
import '../domain/models.dart';
import '../domain/ranking.dart';
import '../domain/repository.dart';

class AppController extends ChangeNotifier {
  AppController(this.repository);
  final BuillonRepository repository;
  UserProfile? user;
  List<Restaurant> restaurants = [];
  List<Restaurant> myRestaurants = [];
  List<Review> reviews = [];
  Set<String> favorites = {};
  bool busy = false;
  String? error;
  String? initialLoadError;
  List<String>? _rankedRestaurantIds;
  bool get supportsDemo => repository.supportsDemo;
  bool get canReview => user?.isOwner == false;
  bool ownsReview(Review review) => canReview && review.userId == user?.id;
  String get operationError => error ?? 'Aguarde a operação em andamento.';

  RatingSummary rating(String id) =>
      summarize(reviews.where((r) => r.restaurantId == id));
  List<Restaurant> get topTen {
    final ids = _rankedRestaurantIds;
    if (ids == null) return rankRestaurants(restaurants, reviews);
    final byId = {
      for (final restaurant in restaurants) restaurant.id: restaurant,
    };
    return ids.map((id) => byId[id]).nonNulls.toList();
  }

  List<Review> restaurantReviews(String id) =>
      reviews.where((r) => r.restaurantId == id).toList()..sort(_newestFirst);
  List<Review> get myReviews =>
      reviews.where(ownsReview).toList()..sort(_newestFirst);

  static int _newestFirst(Review a, Review b) {
    final first = a.createdAt;
    final second = b.createdAt;
    if (first == null) return second == null ? 0 : 1;
    return second == null ? -1 : second.compareTo(first);
  }

  Review? myReview(String id) =>
      myReviews.where((r) => r.restaurantId == id).firstOrNull;
  Restaurant restaurant(String id) => restaurants.firstWhere((r) => r.id == id);
  Future<void> _load() async {
    final source = repository;
    final owned = user?.isOwner == true && source is EstablishmentRepository
        ? await (source as EstablishmentRepository).getMyRestaurants()
        : <Restaurant>[];
    final loadedRestaurants = await repository.getRestaurants();
    final loadedReviews = await repository.getReviews();
    final loadedFavorites = await repository.getFavorites();
    final ids = [
      ...loadedRestaurants,
      ...owned,
    ].map((restaurant) => restaurant.id).toSet();
    restaurants = loadedRestaurants;
    myRestaurants = owned;
    reviews = loadedReviews
        .where((review) => ids.contains(review.restaurantId))
        .toList();
    favorites = loadedFavorites;
    initialLoadError = null;
    await _refreshRanking();
  }

  Future<void> _refreshRanking() async {
    _rankedRestaurantIds = null;
    try {
      _rankedRestaurantIds = await repository.getRankedRestaurantIds();
    } on AppException {
      // O ranking local mantém a tela utilizável se a consulta estiver indisponível.
    }
  }

  Future<bool> _run(Future<void> Function() operation) async {
    if (busy) return false;
    busy = true;
    error = null;
    notifyListeners();
    try {
      await operation();
      return true;
    } on AppException catch (e) {
      error = e.message;
      return false;
    } catch (_) {
      error = 'Não foi possível concluir. Tente novamente.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> _authenticate(Future<UserProfile> Function() action) =>
      _run(() async {
        user = await action();
        try {
          await _load();
        } on AppException catch (e) {
          initialLoadError = e.message;
        } catch (_) {
          initialLoadError =
              'Não foi possível carregar o catálogo. Tente novamente.';
        }
      });
  Future<bool> signIn(
    String email,
    String password, {
    String? document,
    bool owner = false,
  }) => _authenticate(
    () => repository.signIn(email, password, document: document, owner: owner),
  );
  Future<bool> register(
    String name,
    String email,
    String password, {
    String? cpf,
    String? cnpj,
  }) => _authenticate(
    () => repository.register(name, email, password, cpf: cpf, cnpj: cnpj),
  );
  Future<bool> demo() => _authenticate(repository.enterDemo);
  Future<bool> refresh() => _run(_load);
  Future<bool> changeEstablishment(Future<void> Function() save) =>
      _run(() async {
        await save();
        try {
          await _load();
        } catch (_) {
          initialLoadError =
              'Alteração salva. Atualize para ver os dados mais recentes.';
        }
      });
  Future<bool> toggleFavorite(String id) => _run(() async {
    final favorite = !favorites.contains(id);
    await repository.setFavorite(id, favorite);
    favorites = {...favorites};
    if (favorite) {
      favorites.add(id);
    } else {
      favorites.remove(id);
    }
  });
  Future<bool> saveReview(String id, int rating, String comment) =>
      _run(() async {
        if (!canReview) {
          throw const AppException(
            'Avaliações estão disponíveis para contas CPF.',
          );
        }
        final saved = await repository.saveReview(
          restaurantId: id,
          rating: rating,
          comment: comment,
        );
        reviews = [...reviews.where((review) => review.id != saved.id), saved];
        await _refreshRanking();
      });
  Future<bool> deleteReview(String id) => _run(() async {
    if (!canReview) {
      throw const AppException('Avaliações estão disponíveis para contas CPF.');
    }
    await repository.deleteReview(id);
    reviews = reviews.where((review) => review.id != id).toList();
    await _refreshRanking();
  });
  Future<bool> updateProfile(String name, String bio, String avatar) =>
      _run(() async {
        final updated = await repository.updateProfile(
          name: name,
          bio: bio,
          avatar: avatar,
        );
        user = updated;
        reviews = [
          for (final review in reviews)
            ownsReview(review) ? review.withAuthor(updated) : review,
        ];
      });
  Future<bool> signOut() => _run(() async {
    await repository.signOut();
    user = null;
    restaurants = [];
    myRestaurants = [];
    reviews = [];
    favorites = {};
    _rankedRestaurantIds = null;
    initialLoadError = null;
  });
}
