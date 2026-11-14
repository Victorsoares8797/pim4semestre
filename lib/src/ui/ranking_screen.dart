import 'package:flutter/material.dart';
import '../application/app_controller.dart';
import 'shell.dart';
import 'theme.dart';
import 'widgets.dart';

class RankingScreen extends StatelessWidget {
  const RankingScreen({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) {
    final top = controller.topTen;
    return PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeading(
            eyebrow: 'OS FAVORITOS DA COMUNIDADE',
            title: 'Top 10 da cidade',
            subtitle: 'As melhores notas de quem já esteve à mesa.',
          ),
          const SizedBox(height: 22),
          Material(
            color: softGreen,
            borderRadius: BorderRadius.circular(14),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              leading: const Icon(Icons.emoji_events_outlined, color: olive),
              title: const Text(
                'Cada experiência conta',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              subtitle: const Text(
                'Como funciona o ranking',
                style: TextStyle(fontSize: 12),
              ),
              trailing: const Icon(Icons.info_outline, size: 20),
              onTap: () => showModalBottomSheet<void>(
                context: context,
                useSafeArea: true,
                showDragHandle: true,
                builder: (context) => Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Um ranking feito por vocês',
                        style: TextStyle(fontFamily: 'Lora', fontSize: 24),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        controller.supportsDemo
                            ? 'A ordem acompanha a média das notas de 1 a 5 estrelas. Em caso de empate, vale a quantidade de avaliações e depois o nome. Cada comentário vem acompanhado de uma nota.'
                            : 'A ordem acompanha a média das notas de 1 a 5 estrelas. Em caso de empate, vale a quantidade de avaliações.',
                        style: const TextStyle(
                          fontSize: 14,
                          color: muted,
                          height: 1.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          if (top.isEmpty)
            const EmptyState(
              icon: Icons.emoji_events_outlined,
              title: 'O ranking está começando',
              message: 'As primeiras avaliações vão dar vida a esta lista.',
            ),
          for (var i = 0; i < top.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: i == 0 ? const Color(0xFFD4B883) : line,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => openRestaurant(context, controller, top[i]),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 25,
                          child: Text(
                            '${i + 1}'.padLeft(2, '0'),
                            style: TextStyle(
                              fontFamily: 'Lora',
                              fontSize: 22,
                              color: i < 3 ? orange : muted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Photo(top[i].image, width: 66, height: 88),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (i == 0) ...[
                                const Eyebrow('O MAIS AMADO'),
                                const SizedBox(height: 5),
                              ],
                              Text(
                                top[i].name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                top[i].neighborhood,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: muted,
                                ),
                              ),
                              const SizedBox(height: 9),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  RatingBadge(controller.rating(top[i].id)),
                                  Text(
                                    '${controller.rating(top[i].id).count} avaliações',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: muted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 10),
          const Center(
            child: Text(
              'Atualizado a cada nova avaliação.',
              style: TextStyle(fontSize: 12, color: muted),
            ),
          ),
        ],
      ),
    );
  }
}
