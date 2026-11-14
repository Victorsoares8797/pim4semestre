import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../domain/models.dart';
import '../domain/repository.dart';

class HttpBuillonRepository
    implements BuillonRepository, EstablishmentRepository {
  HttpBuillonRepository(Uri baseUrl, {http.Client? client})
    : _baseUrl = baseUrl.path.endsWith('/')
          ? baseUrl
          : baseUrl.replace(path: '${baseUrl.path}/'),
      _client = client ?? http.Client();

  final Uri _baseUrl;
  final http.Client _client;
  String? _token;
  bool _isOwner = false;

  @override
  bool get supportsDemo => false;

  Future<Object?> _request(
    String method,
    String path, {
    Map<String, Object?>? body,
    bool allowExpired = false,
  }) async {
    final request = http.Request(method, _baseUrl.resolve('api/$path'));
    request.headers['Accept'] = 'application/json';
    if (_token case final String token) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    if (body != null) {
      request.headers['Content-Type'] = 'application/json; charset=utf-8';
      request.body = jsonEncode(body);
    }

    try {
      final response = await (() async {
        return http.Response.fromStream(await _client.send(request));
      })().timeout(const Duration(seconds: 15));
      if (allowExpired && response.statusCode == 401) return null;

      final content = utf8.decode(response.bodyBytes);
      final isJson =
          response.headers['content-type']?.contains('json') ?? false;
      final decoded = isJson && content.isNotEmpty ? jsonDecode(content) : null;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded;
      }
      if (decoded case {'message': final String message}) {
        throw AppException(message);
      }
      throw AppException(switch (response.statusCode) {
        401 => 'Sua sessão expirou. Saia e entre novamente.',
        429 => 'Muitas tentativas. Aguarde um minuto e tente de novo.',
        _ => 'A API do Buillon respondeu com erro (${response.statusCode}).',
      });
    } on http.ClientException {
      throw const AppException('Não foi possível conectar à API do Buillon.');
    } on TimeoutException {
      throw const AppException('A API demorou a responder. Tente novamente.');
    } on FormatException {
      throw const AppException(
        'A API do Buillon retornou uma resposta inválida.',
      );
    }
  }

  Future<UserProfile> _authenticate(
    String path,
    Map<String, Object?> body,
  ) async {
    final session =
        await _request('POST', 'auth/$path', body: body)
            as Map<String, dynamic>;
    final profile = UserProfile.fromJson(
      session['user'] as Map<String, dynamic>,
    );
    _token = session['token'] as String;
    _isOwner = session['role'] == 'Proprietario';
    return profile.copyWith(isOwner: _isOwner);
  }

  @override
  Future<UserProfile> signIn(
    String email,
    String password, {
    String? document,
    bool owner = false,
  }) => _authenticate('login', {
    'email': email,
    'senha': password,
    'documento': ?document,
    if (owner) 'role': 'Proprietario',
  });

  @override
  Future<UserProfile> register(
    String name,
    String email,
    String password, {
    String? cpf,
    String? cnpj,
  }) => _authenticate('registar', {
    'nome': name,
    'email': email,
    'senha': password,
    'cpf': cpf,
    if (cnpj != null) ...{'role': 'Proprietario', 'documento': cnpj},
  });

  @override
  Future<UserProfile> enterDemo() async =>
      throw const AppException('Abra o Buillon no modo de demonstração.');

  @override
  Future<void> signOut() async {
    await _request('POST', 'auth/sair', allowExpired: true);
    _token = null;
    _isOwner = false;
  }

  @override
  Future<List<Restaurant>> getRestaurants() => _restaurants('restaurantes');

  Future<List<Restaurant>> _restaurants(String path) async {
    const pageSize = 50;
    final restaurants = <Restaurant>[];
    for (var page = 1; ; page++) {
      final rows =
          await _request('GET', '$path?pagina=$page&tamanho=$pageSize') as List;
      restaurants.addAll(rows.cast<Map<String, dynamic>>().map(_restaurant));
      if (rows.length < pageSize) return restaurants;
    }
  }

  String _imageUrl(String path) => path.startsWith('api/restaurantes/imagens/')
      ? _baseUrl.resolve(path).toString()
      : path;

  Restaurant _restaurant(Map<String, dynamic> json) => Restaurant.fromJson({
    ...json,
    'image': _imageUrl(json['image'] as String),
    'dishes': [
      for (final dish in json['dishes'] as List)
        {
          ...dish as Map<String, dynamic>,
          'image': _imageUrl(dish['image'] as String),
        },
    ],
    'fotos': [
      for (final photo in json['fotos'] as List? ?? const [])
        {
          ...photo as Map<String, dynamic>,
          'url': _imageUrl(photo['url'] as String),
        },
    ],
  });

  @override
  Future<List<Restaurant>> getMyRestaurants() =>
      _restaurants('restaurantes/meus');

  @override
  Future<Map<int, String>> getCategories() async => {
    for (final row in await _request('GET', 'restaurantes/categorias') as List)
      row['id'] as int: row['nome'] as String,
  };

  @override
  Future<Restaurant> getRestaurantDetails(String id) async => _restaurant(
    await _request('GET', 'restaurantes/$id') as Map<String, dynamic>,
  );

  @override
  Future<String> saveRestaurant(
    String? id,
    Map<String, Object?> details,
  ) async {
    final result = await _request(
      id == null ? 'POST' : 'PUT',
      id == null ? 'restaurantes' : 'restaurantes/$id',
      body: details,
    );
    return id ?? (result as Map<String, dynamic>)['id'].toString();
  }

  @override
  Future<void> addRestaurantPhoto(
    String id,
    Uint8List bytes,
    String caption,
  ) async {
    await _request(
      'POST',
      'restaurantes/$id/fotos',
      body: {'arquivo': base64Encode(bytes), 'legenda': caption},
    );
  }

  @override
  Future<void> addDish(
    String id,
    String name,
    String description,
    double price,
    Uint8List? photo,
  ) async {
    await _request(
      'POST',
      'restaurantes/$id/cardapio',
      body: {
        'nome': name,
        'descricao': description,
        'preco': price,
        'arquivo': ?(photo == null ? null : base64Encode(photo)),
      },
    );
  }

  @override
  Future<void> publishComment(String id, String comment) async {
    await _request(
      'POST',
      'restaurantes/$id/publicacoes',
      body: {'comentario': comment},
    );
  }

  @override
  Future<List<Review>> getReviews() async =>
      (await _request('GET', 'restaurantes/avaliacoes') as List)
          .cast<Map<String, dynamic>>()
          .map(Review.fromJson)
          .toList();

  @override
  Future<List<String>> getRankedRestaurantIds() async {
    final rows = await _request('GET', 'restaurantes/ranking');
    if (rows is! List ||
        rows.any((row) => row is! Map || row['id'] is! String)) {
      throw const AppException('A API retornou um ranking inválido.');
    }
    return rows.map((row) => row['id'] as String).toList();
  }

  @override
  Future<Set<String>> getFavorites() async =>
      (await _request('GET', 'perfil/favoritos') as List)
          .cast<String>()
          .toSet();

  @override
  Future<void> setFavorite(String restaurantId, bool favorite) async {
    await _request(
      'PUT',
      'perfil/favoritos/$restaurantId',
      body: {'favorite': favorite},
    );
  }

  @override
  Future<Review> saveReview({
    required String restaurantId,
    required int rating,
    required String comment,
  }) async => Review.fromJson(
    await _request(
          'PUT',
          'restaurantes/$restaurantId/avaliacao',
          body: {'rating': rating, 'comment': comment},
        )
        as Map<String, dynamic>,
  );

  @override
  Future<void> deleteReview(String reviewId) async {
    await _request('DELETE', 'restaurantes/avaliacoes/$reviewId');
  }

  @override
  Future<UserProfile> updateProfile({
    required String name,
    required String bio,
    required String avatar,
  }) async => UserProfile.fromJson(
    await _request(
          'PUT',
          'perfil',
          body: {'name': name, 'bio': bio, 'avatar': avatar},
        )
        as Map<String, dynamic>,
  ).copyWith(isOwner: _isOwner);
}
