class AppException implements Exception {
  const AppException(this.message);
  final String message;
  @override
  String toString() => message;
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.avatar,
    this.bio = 'Sempre em busca de uma boa mesa.',
    this.isOwner = false,
  });
  final String id, name, email, avatar, bio;
  final bool isOwner;
  UserProfile copyWith({
    String? name,
    String? avatar,
    String? bio,
    bool? isOwner,
  }) => UserProfile(
    id: id,
    name: name ?? this.name,
    email: email,
    avatar: avatar ?? this.avatar,
    bio: bio ?? this.bio,
    isOwner: isOwner ?? this.isOwner,
  );
  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    avatar: json['avatar'] as String,
    bio: json['bio'] as String? ?? '',
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'avatar': avatar,
    'bio': bio,
  };
}

class Dish {
  const Dish({
    required this.name,
    required this.image,
    required this.description,
    this.price,
  });
  final String name, image, description;
  final double? price;
  factory Dish.fromJson(Map<String, dynamic> json) => Dish(
    name: json['name'] as String,
    image: json['image'] as String,
    description: json['description'] as String,
    price: (json['price'] as num?)?.toDouble(),
  );
  Map<String, dynamic> toJson() => {
    'name': name,
    'image': image,
    'description': description,
    if (price != null) 'price': price,
  };
}

typedef RestaurantPhoto = ({String url, String caption});

class RestaurantPost {
  const RestaurantPost(this.comment, this.createdAt);
  final String comment;
  final DateTime createdAt;
}

class Restaurant {
  const Restaurant({
    required this.id,
    required this.name,
    required this.category,
    required this.neighborhood,
    required this.address,
    required this.description,
    required this.image,
    required this.price,
    required this.hours,
    required this.dishes,
    this.photos = const [],
    this.posts = const [],
    this.details,
    this.isExample = false,
  });
  final String id,
      name,
      category,
      neighborhood,
      address,
      description,
      image,
      price,
      hours;
  final List<Dish> dishes;
  final List<RestaurantPhoto> photos;
  final List<RestaurantPost> posts;
  final Map<String, dynamic>? details;
  final bool isExample;
  factory Restaurant.fromJson(Map<String, dynamic> json) => Restaurant(
    id: json['id'] as String,
    name: json['name'] as String,
    category: json['category'] as String,
    neighborhood: json['neighborhood'] as String,
    address: json['address'] as String,
    description: json['description'] as String,
    image: json['image'] as String,
    price: json['price'] as String,
    hours: json['hours'] as String,
    dishes: (json['dishes'] as List)
        .map((e) => Dish.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    photos: [
      for (final photo in json['fotos'] as List? ?? const [])
        (url: photo['url'] as String, caption: photo['legenda'] as String),
    ],
    posts: [
      for (final post in json['publicacoes'] as List? ?? const [])
        RestaurantPost(
          post['comentario'] as String,
          DateTime.parse(post['criadoEm'] as String),
        ),
    ],
    details: json['dados'] as Map<String, dynamic>?,
    isExample: json['isExample'] as bool? ?? false,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'neighborhood': neighborhood,
    'address': address,
    'description': description,
    'image': image,
    'price': price,
    'hours': hours,
    'dishes': dishes.map((e) => e.toJson()).toList(),
    if (isExample) 'isExample': true,
  };
}

class Review {
  const Review({
    required this.id,
    required this.restaurantId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });
  final String id, restaurantId, userId, userName, userAvatar, comment;
  final int rating;
  final DateTime? createdAt;

  Review withAuthor(UserProfile user) => Review(
    id: id,
    restaurantId: restaurantId,
    userId: userId,
    userName: user.name,
    userAvatar: user.avatar,
    rating: rating,
    comment: comment,
    createdAt: createdAt,
  );
  factory Review.fromJson(Map<String, dynamic> json) => Review(
    id: json['id'] as String,
    restaurantId: json['restaurantId'] as String,
    userId: json['userId'] as String,
    userName: json['userName'] as String,
    userAvatar: json['userAvatar'] as String,
    rating: json['rating'] as int,
    comment: json['comment'] as String,
    createdAt: switch (json['createdAt']) {
      final String date => DateTime.parse(date),
      _ => null,
    },
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'restaurantId': restaurantId,
    'userId': userId,
    'userName': userName,
    'userAvatar': userAvatar,
    'rating': rating,
    'comment': comment,
    'createdAt': createdAt?.toUtc().toIso8601String(),
  };
}

class RatingSummary {
  const RatingSummary(this.average, this.count);
  final double average;
  final int count;
  String get label =>
      count == 0 ? 'Novo' : average.toStringAsFixed(1).replaceAll('.', ',');
}
