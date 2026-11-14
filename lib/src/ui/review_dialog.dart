import 'package:flutter/material.dart';
import '../application/app_controller.dart';
import '../domain/models.dart';
import 'theme.dart';
import 'widgets.dart';

Future<void> editReview(
  BuildContext context,
  AppController controller,
  Restaurant restaurant,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  backgroundColor: paper,
  constraints: BoxConstraints(
    maxHeight: MediaQuery.sizeOf(context).height * .94,
  ),
  builder: (_) => _ReviewDialog(controller: controller, restaurant: restaurant),
);

class _ReviewDialog extends StatefulWidget {
  const _ReviewDialog({required this.controller, required this.restaurant});
  final AppController controller;
  final Restaurant restaurant;
  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  final _form = GlobalKey<FormState>();
  late final _existing = widget.controller.myReview(widget.restaurant.id);
  late final _comment = TextEditingController(text: _existing?.comment ?? '');
  late int _rating = _existing?.rating ?? 0;
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_rating == 0) {
      setState(() => _error = 'Escolha uma nota de 1 a 5 estrelas.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final ok = await widget.controller.saveReview(
      widget.restaurant.id,
      _rating,
      _comment.text,
    );
    if (!mounted) return;
    if (ok) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Sua avaliação foi salva. Obrigado por compartilhar!'),
        ),
      );
    } else {
      setState(() {
        _saving = false;
        _error = widget.controller.operationError;
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _existing == null
                          ? 'Como foi a experiência?'
                          : 'Sua experiência, atualizada.',
                      style: const TextStyle(fontFamily: 'Lora', fontSize: 23),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar avaliação',
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.restaurant.name,
                style: const TextStyle(color: muted, fontSize: 14),
              ),
              const SizedBox(height: 22),
              const Text(
                'Sua nota',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                children: List.generate(
                  5,
                  (i) => IconButton(
                    tooltip: '${i + 1} ${i == 0 ? 'estrela' : 'estrelas'}',
                    onPressed: _saving
                        ? null
                        : () => setState(() {
                            _rating = i + 1;
                            _error = null;
                          }),
                    icon: Icon(
                      i < _rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: orange,
                      size: 34,
                    ),
                  ),
                ),
              ),
              if (_rating > 0)
                Text(
                  [
                    '',
                    'Não foi como eu esperava',
                    'Pode melhorar',
                    'Foi uma boa experiência',
                    'Gostei muito',
                    'Foi inesquecível!',
                  ][_rating],
                  style: const TextStyle(fontSize: 13, color: olive),
                ),
              const SizedBox(height: 22),
              TextFormField(
                controller: _comment,
                enabled: !_saving,
                minLines: 4,
                maxLines: 7,
                maxLength: 1000,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Seu comentário',
                  alignLabelWithHint: true,
                  hintText:
                      'Como estavam a comida, o ambiente e o atendimento?',
                ),
                validator: (v) => (v?.trim().length ?? 0) < 10
                    ? 'Escreva pelo menos 10 caracteres.'
                    : null,
              ),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 13,
                  ),
                ),
              const SizedBox(height: 8),
              const Text(
                'Sua nota entra na média do restaurante. Você pode editar ou excluir depois.',
                style: TextStyle(fontSize: 12, color: muted, height: 1.6),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Salvando…' : 'Publicar avaliação'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> removeReview(
  BuildContext context,
  AppController controller,
  Review review,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text(
        'Excluir sua avaliação?',
        style: TextStyle(fontFamily: 'Lora'),
      ),
      content: const Text(
        'Sua nota e seu comentário serão removidos. A média do restaurante será recalculada.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Manter avaliação'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Excluir'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  final ok = await controller.deleteReview(review.id);
  if (context.mounted) {
    showFeedback(
      context,
      ok ? 'Avaliação excluída.' : controller.operationError,
    );
  }
}

class ReviewCard extends StatelessWidget {
  const ReviewCard({
    super.key,
    required this.review,
    required this.controller,
    this.showRestaurant = false,
  });
  final Review review;
  final AppController controller;
  final bool showRestaurant;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showRestaurant) ...[
          InkWell(
            onTap: () => openRestaurant(
              context,
              controller,
              controller.restaurant(review.restaurantId),
            ),
            child: Row(
              children: [
                const Icon(Icons.restaurant_outlined, color: orange, size: 17),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    controller.restaurant(review.restaurantId).name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward, size: 16),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Row(
          children: [
            Avatar(review.userAvatar, radius: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.ownsReview(review)
                        ? '${review.userName} · você'
                        : review.userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  if (review.createdAt case final DateTime date)
                    Text(
                      displayDate(date),
                      style: const TextStyle(color: muted, fontSize: 10),
                    ),
                ],
              ),
            ),
            if (controller.ownsReview(review))
              PopupMenuButton<String>(
                tooltip: 'Opções da sua avaliação',
                enabled: !controller.busy,
                onSelected: (value) {
                  if (value == 'edit') {
                    editReview(
                      context,
                      controller,
                      controller.restaurant(review.restaurantId),
                    );
                  } else {
                    removeReview(context, controller, review);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Editar avaliação'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Excluir avaliação'),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 12),
        Stars(review.rating),
        const SizedBox(height: 10),
        Text(
          review.comment,
          style: const TextStyle(
            fontSize: 14,
            height: 1.9,
            color: Color(0xFF596056),
          ),
        ),
      ],
    ),
  );
}
