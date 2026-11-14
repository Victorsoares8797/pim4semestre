import '../domain/models.dart';
import '../domain/repository.dart';
import '../domain/validation.dart';
import 'demo_data.dart';

class _DemoAccount {
  _DemoAccount(this.profile, this.password);
  UserProfile profile;
  final String password;
}

/// Simulação em memória: sem rede, banco ou persistência de credenciais.
class InMemoryBuillonRepository implements BuillonRepository {
  @override
  bool get supportsDemo => true;

  final _restaurants = demoRestaurants();
  final _reviews = demoReviews();
  final _accounts = <String, _DemoAccount>{};
  final _favorites = <String, Set<String>>{
    demoUser.id: {'r1', 'r2', 'r3'},
  };
  UserProfile? _session;
  UserProfile _demoProfile = demoUser;
  var _sequence = 0;

  UserProfile get _user =>
      _session ??
      (throw const AppException('Entre na sua conta para continuar.'));
  void _requireRestaurant(String id) {
    if (!_restaurants.any((r) => r.id == id)) {
      throw const AppException('Restaurante não encontrado.');
    }
  }

  @override
  Future<UserProfile> enterDemo() async => _session = _demoProfile;
  @override
  Future<UserProfile> signIn(
    String email,
    String password, {
    String? document,
    bool owner = false,
  }) async {
    final account = _accounts[email.trim().toLowerCase()];
    if (account == null || account.password != password) {
      throw const AppException(
        'E-mail ou senha incorretos. Crie uma conta ou explore a demonstração.',
      );
    }
    return _session = account.profile;
  }

  @override
  Future<UserProfile> register(
    String name,
    String email,
    String password, {
    String? cpf,
    String? cnpj,
  }) async {
    final normalized = email.trim().toLowerCase();
    if (name.trim().length < 2 ||
        name.trim().length > 60 ||
        !isValidEmail(normalized) ||
        password.length < 6) {
      throw const AppException(
        'Confira nome, e-mail e senha de pelo menos 6 caracteres.',
      );
    }
    if (_accounts.containsKey(normalized) || normalized == demoUser.email) {
      throw const AppException('Este e-mail já está cadastrado.');
    }
    final profile = UserProfile(
      id: 'user-${++_sequence}',
      name: name.trim(),
      email: normalized,
      avatar: '',
    );
    _accounts[normalized] = _DemoAccount(profile, password);
    return _session = profile;
  }

  @override
  Future<void> signOut() async {
    _session = null;
  }

  @override
  Future<List<Restaurant>> getRestaurants() async =>
      List.unmodifiable(_restaurants);
  @override
  Future<List<Review>> getReviews() async => List.unmodifiable(_reviews);
  @override
  Future<List<String>?> getRankedRestaurantIds() async => null;
  @override
  Future<Set<String>> getFavorites() async =>
      Set.unmodifiable(_favorites[_user.id] ?? {});
  @override
  Future<void> setFavorite(String restaurantId, bool favorite) async {
    _requireRestaurant(restaurantId);
    final set = _favorites.putIfAbsent(_user.id, () => <String>{});
    if (favorite) {
      set.add(restaurantId);
    } else {
      set.remove(restaurantId);
    }
  }

  @override
  Future<Review> saveReview({
    required String restaurantId,
    required int rating,
    required String comment,
  }) async {
    final user = _user;
    _requireRestaurant(restaurantId);
    if (rating < 1 || rating > 5) {
      throw const AppException('Escolha uma nota de 1 a 5 estrelas.');
    }
    if (comment.trim().length < 10 || comment.trim().length > 1000) {
      throw const AppException(
        'Escreva um comentário entre 10 e 1.000 caracteres.',
      );
    }
    final existing = _reviews
        .where((r) => r.restaurantId == restaurantId && r.userId == user.id)
        .firstOrNull;
    final review = Review(
      id: existing?.id ?? 'review-${++_sequence}',
      restaurantId: restaurantId,
      userId: user.id,
      userName: user.name,
      userAvatar: user.avatar,
      rating: rating,
      comment: comment.trim(),
      createdAt: existing?.createdAt ?? DateTime.now(),
    );
    _reviews.removeWhere((r) => r.id == review.id);
    _reviews.add(review);
    return review;
  }

  @override
  Future<void> deleteReview(String reviewId) async {
    final id = _user.id;
    if (!_reviews.any((r) => r.id == reviewId && r.userId == id)) {
      throw const AppException('Avaliação não encontrada.');
    }
    _reviews.removeWhere((r) => r.id == reviewId && r.userId == id);
  }

  @override
  Future<UserProfile> updateProfile({
    required String name,
    required String bio,
    required String avatar,
  }) async {
    if (name.trim().length < 2 ||
        name.trim().length > 60 ||
        bio.trim().length > 160) {
      throw const AppException(
        'Use um nome de 2 a 60 caracteres e uma bio de até 160 caracteres.',
      );
    }
    if (![
      '',
      'assets/images/avatar_1.jpg',
      'assets/images/avatar_2.jpg',
      'assets/images/avatar_3.jpg',
    ].contains(avatar)) {
      throw const AppException('Selecione uma foto disponível.');
    }
    final updated = _user.copyWith(
      name: name.trim(),
      bio: bio.trim(),
      avatar: avatar,
    );
    if (updated.id == demoUser.id) _demoProfile = updated;
    final account = _accounts[updated.email];
    if (account != null) {
      account.profile = updated;
    }
    for (var i = 0; i < _reviews.length; i++) {
      final r = _reviews[i];
      if (r.userId == updated.id) {
        _reviews[i] = r.withAuthor(updated);
      }
    }
    return _session = updated;
  }
}
