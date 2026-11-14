import 'dart:typed_data';

import 'models.dart';

/// Contrato compartilhado entre a demonstração e o serviço HTTP.
abstract interface class BuillonRepository {
  bool get supportsDemo;
  Future<UserProfile> signIn(
    String email,
    String password, {
    String? document,
    bool owner = false,
  });
  Future<UserProfile> register(
    String name,
    String email,
    String password, {
    String? cpf,
    String? cnpj,
  });
  Future<UserProfile> enterDemo();
  Future<void> signOut();
  Future<List<Restaurant>> getRestaurants();
  Future<List<Review>> getReviews();
  Future<List<String>?> getRankedRestaurantIds();
  Future<Set<String>> getFavorites();
  Future<void> setFavorite(String restaurantId, bool favorite);
  Future<Review> saveReview({
    required String restaurantId,
    required int rating,
    required String comment,
  });
  Future<void> deleteReview(String reviewId);
  Future<UserProfile> updateProfile({
    required String name,
    required String bio,
    required String avatar,
  });
}

abstract interface class EstablishmentRepository {
  Future<List<Restaurant>> getMyRestaurants();
  Future<Map<int, String>> getCategories();
  Future<Restaurant> getRestaurantDetails(String id);
  Future<String> saveRestaurant(String? id, Map<String, Object?> details);
  Future<void> addRestaurantPhoto(String id, Uint8List bytes, String caption);
  Future<void> addDish(
    String id,
    String name,
    String description,
    double price,
    Uint8List? photo,
  );
  Future<void> publishComment(String id, String comment);
}
