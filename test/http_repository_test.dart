import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pim4semestre/src/application/app_controller.dart';
import 'package:pim4semestre/src/data/demo_data.dart';
import 'package:pim4semestre/src/data/http_repository.dart';

http.Response jsonResponse(Object data, [int status = 200]) => http.Response(
  jsonEncode(data),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  test('API envia CPF, autentica favoritos e aceita logout expirado', () async {
    final client = MockClient((request) async {
      switch (request.url.path) {
        case '/api/auth/registar':
          expect(request.method, 'POST');
          expect(jsonDecode(request.body), {
            'nome': 'Ana Silva',
            'email': 'ana@example.com',
            'senha': 'senha123',
            'cpf': '52998224725',
          });
          return jsonResponse({
            'token': 'sessao',
            'user': demoUser.toJson(),
          }, 201);
        case '/api/perfil/favoritos':
          expect(request.headers['Authorization'], 'Bearer sessao');
          return jsonResponse(['1']);
        case '/api/auth/sair':
          expect(request.headers['Authorization'], 'Bearer sessao');
          return http.Response('', 401);
        default:
          fail('Rota inesperada ${request.url}');
      }
    });
    final repository = HttpBuillonRepository(
      Uri.parse('http://localhost:5080'),
      client: client,
    );
    expect(repository.supportsDemo, isFalse);
    await repository.register(
      'Ana Silva',
      'ana@example.com',
      'senha123',
      cpf: '52998224725',
    );
    expect(await repository.getFavorites(), {'1'});
    await repository.signOut();
  });

  test(
    'Controlador usa a ordem da API e mantém avaliação gravada com ranking indisponível',
    () async {
      final restaurants = demoRestaurants()
          .take(2)
          .map((item) => item.toJson())
          .toList();
      final saved = {
        'id': '123',
        'restaurantId': 'r1',
        'userId': demoUser.id,
        'userName': demoUser.name,
        'userAvatar': demoUser.avatar,
        'rating': 5,
        'comment': 'Ótima experiência.',
        'createdAt': null,
      };
      var rankingOffline = false;
      final client = MockClient((request) async {
        switch (request.url.path) {
          case '/api/auth/login':
            return jsonResponse({'token': 'sessao', 'user': demoUser.toJson()});
          case '/api/restaurantes':
            expect(request.url.queryParameters, {
              'pagina': '1',
              'tamanho': '50',
            });
            return jsonResponse(restaurants);
          case '/api/restaurantes/avaliacoes':
          case '/api/perfil/favoritos':
            return jsonResponse([]);
          case '/api/restaurantes/ranking':
            return rankingOffline
                ? jsonResponse({'message': 'Indisponível.'}, 503)
                : jsonResponse([
                    {'id': 'r2'},
                    {'id': 'r1'},
                  ]);
          case '/api/restaurantes/r1/avaliacao':
            expect(request.method, 'PUT');
            expect(request.headers['Authorization'], 'Bearer sessao');
            rankingOffline = true;
            return jsonResponse(saved);
          default:
            fail('Rota inesperada ${request.url}');
        }
      });
      final controller = AppController(
        HttpBuillonRepository(
          Uri.parse('http://localhost:5080'),
          client: client,
        ),
      );
      addTearDown(controller.dispose);
      expect(await controller.signIn('ana@example.com', 'senha123'), isTrue);
      expect(controller.topTen.map((item) => item.id), ['r2', 'r1']);
      expect(
        await controller.saveReview('r1', 5, 'Ótima experiência.'),
        isTrue,
      );
      expect(controller.myReview('r1')?.id, '123');
      expect(controller.topTen.single.id, 'r1');
    },
  );
}
