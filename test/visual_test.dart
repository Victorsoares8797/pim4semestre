// Capturas reais do aplicativo exclusivamente em formato de celular.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pim4semestre/src/app.dart';
import 'package:pim4semestre/src/ui/widgets.dart';
import 'test_fonts.dart';

void main() {
  testWidgets('Capturas de todos os fluxos mobile em 390x844', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await loadTestFonts();
    final boundary = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(key: boundary, child: const BuillonApp()),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await Future.wait([
        for (final type in ['restaurant', 'dish', 'avatar'])
          for (var i = 1; i <= (type == 'avatar' ? 3 : 6); i++)
            precacheImage(
              AssetImage('assets/images/${type}_$i.jpg'),
              boundary.currentContext!,
            ),
      ]);
    });
    Future<void> capture(String name) async {
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final render =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await render.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final dir = Directory('docs/screenshots/mobile')
          ..createSync(recursive: true);
        File(
          '${dir.path}/$name.png',
        ).writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
      expect(tester.takeException(), isNull);
    }

    Future<void> tapText(String text) async {
      await tester.ensureVisible(find.text(text).first);
      await tester.tap(find.text(text).first);
      await tester.pumpAndSettle();
    }

    Future<void> tab(String label) async {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(label),
        ),
      );
      await tester.pumpAndSettle();
    }

    await capture('01-login');
    await tapText('Cadastre-se');
    await capture('02-cadastro');
    await tapText('Entrar');
    await tapText('Explorar demonstração');
    await capture('03-inicio');
    final restaurant = find.descendant(
      of: find.byType(RestaurantCard),
      matching: find.text('Casa do Manjericão'),
    );
    await tester.ensureVisible(restaurant);
    await tester.tap(restaurant);
    await tester.pumpAndSettle();
    await capture('04-restaurante');
    await tapText('Editar minha avaliação');
    await capture('05-avaliacao');
    await tester.tap(find.byTooltip('Fechar avaliação'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Sabores para conhecer'));
    await capture('06-pratos');
    await tester.ensureVisible(find.text('Experiências de quem já foi'));
    await capture('07-comentarios');
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tab('Top 10');
    await capture('08-ranking');
    await tab('Favoritos');
    await capture('09-favoritos');
    await tab('Meu perfil');
    await capture('10-perfil');
    await tapText('Meus comentários');
    await tester.ensureVisible(find.text('O que você compartilhou'));
    await capture('11-meus-comentarios');
  });
}
