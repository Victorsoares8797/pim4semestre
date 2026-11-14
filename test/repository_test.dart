import 'package:flutter_test/flutter_test.dart';
import 'package:pim4semestre/src/application/app_controller.dart';
import 'package:pim4semestre/src/data/in_memory_repository.dart';
import 'package:pim4semestre/src/domain/models.dart';

void main() {
  test('Cadastro, duplicação de e-mail e credenciais', () async {
    final repo = InMemoryBuillonRepository();
    final user = await repo.register(
      'Ana Silva',
      ' ANA@example.com ',
      'senha123',
    );
    expect(user.email, 'ana@example.com');
    await expectLater(
      repo.register('Outra Ana', 'ana@example.com', '123456'),
      throwsA(isA<AppException>()),
    );
    await repo.signOut();
    await expectLater(
      repo.signIn('ana@example.com', 'errada'),
      throwsA(isA<AppException>()),
    );
    expect((await repo.signIn('ANA@example.com', 'senha123')).id, user.id);
  });
  test(
    'Avaliação única por usuário, atualização, exclusão e média sincronizada',
    () async {
      final c = AppController(InMemoryBuillonRepository());
      addTearDown(c.dispose);
      await c.register('Ana Silva', 'ana@example.com', '123456');
      final before = c.rating('r1');
      expect(
        await c.saveReview('r1', 1, 'Um comentário completo de teste.'),
        true,
      );
      expect(c.rating('r1').count, before.count + 1);
      expect(
        c.rating('r1').average,
        closeTo(
          (before.average * before.count + 1) / (before.count + 1),
          .00001,
        ),
      );
      final id = c.myReview('r1')!.id;
      await c.saveReview('r1', 5, 'Agora uma avaliação editada e completa.');
      expect(c.myReviews.length, 1);
      expect(c.myReview('r1')!.id, id);
      await c.deleteReview(id);
      expect(c.myReviews, isEmpty);
      expect(c.rating('r1').average, before.average);
    },
  );
  test('Favoritos e avaliações não vazam entre contas; exige sessão', () async {
    final repo = InMemoryBuillonRepository();
    await repo.register('Ana Silva', 'ana@example.com', '123456');
    await repo.setFavorite('r1', true);
    final review = await repo.saveReview(
      restaurantId: 'r1',
      rating: 4,
      comment: 'Ótima experiência nesta visita.',
    );
    await repo.signOut();
    await expectLater(
      repo.setFavorite('r2', true),
      throwsA(isA<AppException>()),
    );
    await repo.register('Bruno Silva', 'bruno@example.com', '123456');
    expect(await repo.getFavorites(), isEmpty);
    await expectLater(
      repo.deleteReview(review.id),
      throwsA(isA<AppException>()),
    );
    await repo.signIn('ana@example.com', '123456');
    expect(await repo.getFavorites(), {'r1'});
  });
  test('Rejeita nota, comentário e restaurante inválidos', () async {
    final repo = InMemoryBuillonRepository();
    await repo.enterDemo();
    await expectLater(
      repo.saveReview(
        restaurantId: 'r1',
        rating: 0,
        comment: 'Comentário válido.',
      ),
      throwsA(isA<AppException>()),
    );
    await expectLater(
      repo.saveReview(
        restaurantId: 'r1',
        rating: 6,
        comment: 'Comentário válido.',
      ),
      throwsA(isA<AppException>()),
    );
    await expectLater(
      repo.saveReview(restaurantId: 'r1', rating: 5, comment: 'Curto'),
      throwsA(isA<AppException>()),
    );
    await expectLater(
      repo.setFavorite('inexistente', true),
      throwsA(isA<AppException>()),
    );
  });
  test(
    'Perfil atualizado reflete em comentários e sobrevive ao logout da sessão demo',
    () async {
      final repo = InMemoryBuillonRepository();
      final user = await repo.enterDemo();
      await repo.updateProfile(
        name: 'Novo Nome',
        bio: 'Nova bio',
        avatar: 'assets/images/avatar_2.jpg',
      );
      final reviews = (await repo.getReviews()).where(
        (r) => r.userId == user.id,
      );
      expect(reviews.every((r) => r.userName == 'Novo Nome'), true);
      await repo.signOut();
      expect((await repo.enterDemo()).name, 'Novo Nome');
    },
  );
}
