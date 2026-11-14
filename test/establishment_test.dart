import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pim4semestre/src/app.dart';
import 'package:pim4semestre/src/data/demo_data.dart';
import 'package:pim4semestre/src/data/http_repository.dart';

void main() {
  test('cada restaurante da demonstração tem uma foto de prato própria', () {
    final images = demoRestaurants()
        .expand((item) => item.dishes)
        .map((dish) => dish.image)
        .toList();
    expect(images.toSet(), hasLength(images.length));
  });

  testWidgets('CNPJ abre o painel e permite criar um estabelecimento', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Map<String, dynamic>? created;
    var favorite = false;
    final session = {
      'token': 'test-token',
      'role': 'Proprietario',
      'user': demoUser.toJson(),
    };
    final sample = {...demoRestaurants().first.toJson(), 'isExample': true};
    final existing = {
      ...demoRestaurants()[1].toJson(),
      'id': '2',
      'name': 'Bar do Zé',
    };
    final client = MockClient((request) async {
      http.Response json(Object data, [int status = 200]) => http.Response(
        jsonEncode(data),
        status,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
      switch (request.url.path) {
        case '/api/auth/registar':
          expect(
            jsonDecode(request.body),
            containsPair('documento', '12345678000199'),
          );
          expect(
            jsonDecode(request.body),
            containsPair('role', 'Proprietario'),
          );
          return json(session, 201);
        case '/api/restaurantes/meus':
          expect(request.headers['Authorization'], 'Bearer test-token');
          return json(
            created == null
                ? []
                : [
                    {...existing, 'id': '3', 'name': created!['nome']},
                  ],
          );
        case '/api/restaurantes/avaliacoes':
          return json([
            {
              'id': '1',
              'restaurantId': sample['id'],
              'userId': demoUser.id,
              'userName': 'Cliente com ID coincidente',
              'userAvatar': '',
              'rating': 5,
              'comment': 'Avaliação de um cliente.',
              'createdAt': null,
            },
          ]);
        case '/api/restaurantes/ranking':
          return json([
            {'id': sample['id']},
          ]);
        case '/api/perfil/favoritos':
          return json(favorite ? [sample['id']] : []);
        case '/api/perfil/favoritos/r1':
          favorite = jsonDecode(request.body)['favorite'] as bool;
          return http.Response('', 204);
        case '/api/perfil':
          expect(request.method, 'PUT');
          return json({
            ...demoUser.toJson(),
            'name': jsonDecode(request.body)['name'],
          });
        case '/api/restaurantes/r1':
          return json(sample);
        case '/api/restaurantes/categorias':
          return json([
            {'id': 1, 'nome': 'Brasileira'},
          ]);
        case '/api/restaurantes':
          if (request.method == 'GET') {
            return json([
              sample,
              existing,
              if (created != null)
                {...existing, 'id': '3', 'name': created!['nome']},
            ]);
          }
          expect(request.method, 'POST');
          created = jsonDecode(request.body) as Map<String, dynamic>;
          return json({'id': 3}, 201);
      }
      fail('Rota inesperada ${request.url}');
    });
    await tester.pumpWidget(
      BuillonApp(
        repository: HttpBuillonRepository(
          Uri.parse('http://localhost:5080'),
          client: client,
        ),
      ),
    );
    await tester.tap(find.text('CNPJ'));
    await tester.pumpAndSettle();
    expect(find.text('CNPJ do estabelecimento'), findsOneWidget);
    await tester.tap(find.text('Cadastre-se'));
    await tester.pumpAndSettle();
    final form = find.byType(TextFormField);
    for (final (index, value) in [
      (0, '12.345.678/0001-99'),
      (1, 'Titular Teste'),
      (2, 'dono@example.invalid'),
      (3, 'senha123'),
      (4, 'senha123'),
    ]) {
      await tester.enterText(form.at(index), value);
    }
    await tester.tap(find.text('Criar minha conta'));
    await tester.pumpAndSettle();
    expect(find.text('Meus estabelecimentos'), findsOneWidget);
    expect(find.text('Casa do Manjericão'), findsNothing);
    expect(find.text('Bar do Zé'), findsNothing);
    Future<void> openTab(String name) async {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(name),
        ),
      );
      await tester.pumpAndSettle();
    }

    await openTab('Explorar');
    expect(find.text('Onde vamos comer?'), findsOneWidget);
    expect(find.text('Bar do Zé'), findsOneWidget);
    expect(find.textContaining('·  Exemplo'), findsOneWidget);
    await tester.tap(find.byTooltip('Favoritar Casa do Manjericão'));
    await tester.pumpAndSettle();
    expect(favorite, isTrue);
    await tester.tap(find.text('Casa do Manjericão'));
    await tester.pumpAndSettle();
    expect(find.text('RESTAURANTE DE EXEMPLO'), findsOneWidget);
    expect(find.text('Avaliar restaurante'), findsNothing);
    expect(find.text('Editar minha avaliação'), findsNothing);
    expect(find.byTooltip('Opções da sua avaliação'), findsNothing);
    expect(find.textContaining('· você'), findsNothing);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await openTab('Favoritos');
    expect(find.text('Casa do Manjericão'), findsOneWidget);
    await openTab('Top 10');
    expect(find.text('Casa do Manjericão'), findsOneWidget);
    await openTab('Meu perfil');
    await tester.tap(find.text('Editar perfil'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).first,
      'Titular Atualizado',
    );
    await tester.tap(find.text('Salvar perfil'));
    await tester.pumpAndSettle();
    expect(find.text('Titular Atualizado'), findsOneWidget);
    await openTab('Painel');
    await tester.tap(find.text('Criar estabelecimento'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Brasileira').last);
    await tester.pumpAndSettle();
    for (final (index, value) in [
      (0, 'Cozinha Teste'),
      (1, '12345678000199'),
      (3, 'Rua Teste'),
      (6, 'São Paulo'),
    ]) {
      await tester.enterText(form.at(index), value);
    }
    await tester.ensureVisible(find.text('Salvar estabelecimento'));
    await tester.tap(find.text('Salvar estabelecimento'));
    await tester.pumpAndSettle();
    expect(created, containsPair('categoriaId', 1));
    expect(find.text('Cozinha Teste'), findsOneWidget);
    expect(find.text('Adicionar foto'), findsOneWidget);
    expect(find.text('Adicionar prato'), findsOneWidget);
    expect(find.text('Publicar comentário'), findsOneWidget);
    await openTab('Explorar');
    expect(find.text('Casa do Manjericão'), findsOneWidget);
    expect(find.text('Bar do Zé'), findsOneWidget);
    expect(find.text('Cozinha Teste'), findsOneWidget);
  });
}
