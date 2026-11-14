import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pim4semestre/main.dart';
import 'package:pim4semestre/src/ui/widgets.dart';
import 'test_fonts.dart';

Future<void> tapText(WidgetTester tester, String text) async {
  final target = find.text(text).first;
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> tab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

void size(WidgetTester tester, Size value) {
  tester.view.physicalSize = value;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadTestFonts);
  testWidgets('Celular: cadastro validado, logout e login da conta criada', (
    tester,
  ) async {
    size(tester, const Size(390, 844));
    await tester.pumpWidget(const MyApp());
    await tapText(tester, 'Cadastre-se');
    await tapText(tester, 'Criar minha conta');
    expect(find.text('Informe seu nome.'), findsOneWidget);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Ana Silva');
    await tester.enterText(fields.at(1), 'ana@example.com');
    await tester.enterText(fields.at(2), 'senha123');
    await tester.enterText(fields.at(3), 'diferente');
    await tapText(tester, 'Criar minha conta');
    expect(find.text('As senhas precisam ser iguais.'), findsOneWidget);
    await tester.enterText(fields.at(3), 'senha123');
    await tapText(tester, 'Criar minha conta');
    expect(find.text('Onde vamos comer?'), findsOneWidget);
    expect(find.text('Painel'), findsNothing);
    await tab(tester, 'Meu perfil');
    expect(find.text('Ana Silva'), findsOneWidget);
    await tapText(tester, 'Sair da minha conta');
    await tester.enterText(find.byType(TextFormField).at(0), 'ana@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'senha123');
    await tapText(tester, 'Entrar na minha conta');
    expect(find.text('Onde vamos comer?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Celular: busca, detalhes, avaliação com teclado e ranking', (
    tester,
  ) async {
    size(tester, const Size(390, 844));
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(const MyApp());
    await tapText(tester, 'Explorar demonstração');
    await tester.enterText(find.byType(TextField), 'manjericao');
    await tester.pumpAndSettle();
    expect(find.text('1 restaurante para descobrir'), findsOneWidget);
    await tapText(tester, 'Casa do Manjericão');
    await tapText(tester, 'Editar minha avaliação');
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField),
      'Uma experiência excelente e muito acolhedora.',
    );
    await tapText(tester, 'Publicar avaliação');
    expect(
      find.text('Sua avaliação foi salva. Obrigado por compartilhar!'),
      findsOneWidget,
    );
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tab(tester, 'Top 10');
    expect(find.text('Top 10 da cidade'), findsOneWidget);
    await tab(tester, 'Explorar');
    expect(find.text('1 restaurante para descobrir'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  for (final phoneSize in [
    const Size(320, 720),
    const Size(360, 800),
    const Size(390, 844),
    const Size(430, 932),
  ]) {
    testWidgets('Navegação mobile sem overflow em $phoneSize', (tester) async {
      size(tester, phoneSize);
      await tester.pumpWidget(const MyApp());
      await tapText(tester, 'Explorar demonstração');
      for (final label in ['Top 10', 'Favoritos', 'Meu perfil', 'Explorar']) {
        await tab(tester, label);
        expect(tester.takeException(), isNull);
      }
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });
  }
  testWidgets('Foto e média aparecem na primeira tela do celular', (
    tester,
  ) async {
    size(tester, const Size(390, 844));
    await tester.pumpWidget(const MyApp());
    await tapText(tester, 'Explorar demonstração');
    final card = find.byType(RestaurantCard).first;
    final rating = find.descendant(
      of: card,
      matching: find.byType(RatingBadge),
    );
    expect(
      tester.getRect(rating).bottom,
      lessThan(tester.getRect(find.byType(NavigationBar)).top),
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Busca e ordenação usam controles mobile e preservam estado nas abas',
    (tester) async {
      size(tester, const Size(390, 844));
      await tester.pumpWidget(const MyApp());
      await tapText(tester, 'Explorar demonstração');
      await tester.tap(find.byTooltip('Ordenar restaurantes'));
      await tester.pumpAndSettle();
      await tapText(tester, 'Melhor avaliação');
      await tester.enterText(find.byType(TextField), 'nori');
      await tester.pumpAndSettle();
      await tab(tester, 'Favoritos');
      await tab(tester, 'Explorar');
      expect(find.text('1 restaurante para descobrir'), findsOneWidget);
      expect(find.text('Nori & Co.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Janela de prévia grande mantém a composição de celular', (
    tester,
  ) async {
    size(tester, const Size(1280, 900));
    await tester.pumpWidget(const MyApp());
    await tapText(tester, 'Explorar demonstração');
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(
      tester.getSize(find.byType(RestaurantCard).first).width,
      lessThanOrEqualTo(440),
    );
    expect(tester.takeException(), isNull);
  });
}
