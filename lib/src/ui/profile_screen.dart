import 'package:flutter/material.dart';
import '../application/app_controller.dart';
import 'review_dialog.dart';
import 'shell.dart';
import 'theme.dart';
import 'widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.controller,
    required this.onExplore,
  });
  final AppController controller;
  final VoidCallback onExplore;
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _tab = 0;
  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final user = c.user!;
    final reviews = c.myReviews;
    final bestReviews = [...reviews]
      ..sort((a, b) {
        final score = b.rating.compareTo(a.rating);
        return score != 0
            ? score
            : c
                  .restaurant(a.restaurantId)
                  .name
                  .compareTo(c.restaurant(b.restaurantId).name);
      });
    final best = bestReviews
        .take(6)
        .map((r) => c.restaurant(r.restaurantId))
        .toList();
    final favorites = c.restaurants
        .where((r) => c.favorites.contains(r.id))
        .toList();
    return PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeading(
            eyebrow: 'SUA HISTÓRIA À MESA',
            title: 'Meu perfil',
            subtitle: 'Suas mesas, favoritos e experiências.',
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Avatar(user.avatar, radius: 34),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              fontFamily: 'Lora',
                              fontSize: 23,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            user.email,
                            style: const TextStyle(color: muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  user.bio,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: muted,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: c.busy ? null : () => _editProfile(context),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Editar perfil'),
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 18),
                Row(
                  children: [
                    if (c.canReview)
                      Expanded(child: _Stat('${reviews.length}', 'avaliações')),
                    Expanded(child: _Stat('${favorites.length}', 'favoritos')),
                    if (c.canReview)
                      Expanded(
                        child: _Stat(
                          reviews.isEmpty
                              ? '—'
                              : (reviews.fold<int>(
                                          0,
                                          (sum, r) => sum + r.rating,
                                        ) /
                                        reviews.length)
                                    .toStringAsFixed(1)
                                    .replaceAll('.', ','),
                          'minha nota média',
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          if (c.canReview)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final (index, label) in [
                    (0, 'Minhas melhores mesas'),
                    (1, 'Favoritos'),
                    (2, 'Meus comentários'),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ChoiceChip(
                        label: Text(label),
                        selected: _tab == index,
                        showCheckmark: false,
                        selectedColor: olive,
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          color: _tab == index ? Colors.white : muted,
                          fontSize: 12,
                        ),
                        side: BorderSide(color: _tab == index ? olive : line),
                        onSelected: (_) => setState(() => _tab = index),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          if (c.canReview && _tab == 0) ...[
            const SectionTitle('Os lugares que você mais gostou'),
            if (best.isEmpty)
              _empty()
            else ...[
              const Text(
                'Até seis restaurantes, ordenados pelas notas que você deu.',
                style: TextStyle(color: muted, fontSize: 11),
              ),
              const SizedBox(height: 18),
              RestaurantList(restaurants: best, controller: c),
            ],
          ] else if (!c.canReview || _tab == 1) ...[
            const SectionTitle('Seus favoritos'),
            if (favorites.isEmpty)
              _empty(favorites: true)
            else
              RestaurantList(restaurants: favorites, controller: c),
          ] else ...[
            const SectionTitle('O que você compartilhou'),
            if (reviews.isEmpty)
              _empty()
            else
              for (final review in reviews)
                ReviewCard(review: review, controller: c, showRestaurant: true),
          ],
          const SizedBox(height: 36),
          const Divider(),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: c.busy
                ? null
                : () async {
                    final ok = await c.signOut();
                    if (!ok && context.mounted) {
                      showFeedback(context, c.operationError);
                    }
                  },
            icon: const Icon(Icons.logout_rounded, size: 17),
            label: const Text(
              'Sair da minha conta',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty({bool favorites = false}) => EmptyState(
    icon: favorites ? Icons.favorite_border : Icons.rate_review_outlined,
    title: favorites
        ? 'Guarde suas próximas descobertas'
        : 'Toda boa história tem uma primeira mesa',
    message: favorites
        ? 'Toque no coração de um restaurante para salvar.'
        : 'Avalie um restaurante e encontre sua experiência aqui.',
    action: FilledButton(
      onPressed: widget.onExplore,
      child: const Text('Explorar restaurantes'),
    ),
  );
  void _editProfile(BuildContext context) => showDialog<void>(
    context: context,
    builder: (_) => _EditProfileDialog(controller: widget.controller),
  );
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label);
  final String value, label;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(fontFamily: 'Lora', fontSize: 27, color: olive),
      ),
      const SizedBox(height: 5),
      Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 10, color: muted),
      ),
    ],
  );
}

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({required this.controller});
  final AppController controller;
  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.controller.user!.name);
  late final _bio = TextEditingController(text: widget.controller.user!.bio);
  late String _avatar = widget.controller.user!.avatar;
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      title: const Text(
        'Seu jeito de estar à mesa.',
        style: TextStyle(fontFamily: 'Lora', fontSize: 23),
      ),
      content: SizedBox(
        width: 430,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Escolha sua foto',
                  style: TextStyle(fontSize: 12, color: muted),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  children: [
                    for (final (path, label) in [
                      ('', 'Sem foto'),
                      for (var i = 1; i <= 3; i++)
                        ('assets/images/avatar_$i.jpg', 'Foto de perfil $i'),
                    ])
                      Semantics(
                        label: label,
                        selected: _avatar == path,
                        button: true,
                        child: InkWell(
                          onTap: _saving
                              ? null
                              : () => setState(() => _avatar = path),
                          borderRadius: BorderRadius.circular(50),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                width: 2,
                                color: _avatar == path
                                    ? orange
                                    : Colors.transparent,
                              ),
                            ),
                            child: Avatar(path, radius: 28),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _name,
                  enabled: !_saving,
                  maxLength: 60,
                  decoration: const InputDecoration(labelText: 'Seu nome'),
                  validator: (v) => (v?.trim().length ?? 0) < 2
                      ? 'Informe pelo menos 2 caracteres.'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _bio,
                  enabled: !_saving,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 160,
                  decoration: const InputDecoration(
                    labelText: 'Sobre você',
                    alignLabelWithHint: true,
                  ),
                ),
                if (_error != null)
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving
              ? null
              : () async {
                  if (!_form.currentState!.validate()) return;
                  setState(() {
                    _saving = true;
                    _error = null;
                  });
                  final ok = await widget.controller.updateProfile(
                    _name.text,
                    _bio.text,
                    _avatar,
                  );
                  if (!context.mounted) return;
                  if (ok) {
                    Navigator.pop(context);
                    showFeedback(context, 'Perfil atualizado.');
                  } else {
                    setState(() {
                      _saving = false;
                      _error = widget.controller.operationError;
                    });
                  }
                },
          child: Text(_saving ? 'Salvando…' : 'Salvar perfil'),
        ),
      ],
    ),
  );
}
