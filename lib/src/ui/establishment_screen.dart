import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../application/app_controller.dart';
import '../domain/models.dart';
import '../domain/repository.dart';
import 'widgets.dart';

class EstablishmentScreen extends StatefulWidget {
  const EstablishmentScreen({
    super.key,
    required this.controller,
    required this.repository,
  });
  final AppController controller;
  final EstablishmentRepository repository;

  @override
  State<EstablishmentScreen> createState() => _EstablishmentScreenState();
}

class _EstablishmentScreenState extends State<EstablishmentScreen> {
  String? _selected;
  AppController get controller => widget.controller;

  Future<void> _edit([Restaurant? restaurant]) async {
    final categories = widget.repository.getCategories();
    final selected = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => _RestaurantForm(
          restaurant: restaurant,
          categories: categories,
          controller: controller,
          repository: widget.repository,
        ),
      ),
    );
    if (mounted && selected != null) setState(() => _selected = selected);
  }

  Future<void> _add(Restaurant restaurant, _Content kind) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => _PublicationForm(
            kind: kind,
            controller: controller,
            repository: widget.repository,
            id: restaurant.id,
          ),
        ),
      );

  Future<void> _refresh() async {
    final ok = await controller.refresh();
    if (!ok && mounted) showFeedback(context, controller.operationError);
  }

  @override
  Widget build(BuildContext context) {
    final restaurants = controller.myRestaurants;
    final current =
        restaurants.where((item) => item.id == _selected).firstOrNull ??
        restaurants.firstOrNull;
    final reviews = current == null
        ? <Review>[]
        : controller.restaurantReviews(current.id);
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(20),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Text(
            'Meus estabelecimentos',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: controller.busy ? null : () => _edit(),
            icon: const Icon(Icons.add),
            label: const Text('Criar estabelecimento'),
          ),
          if (current == null && controller.initialLoadError == null) ...[
            const SizedBox(height: 24),
            const Text(
              'Cadastre seu estabelecimento para publicar fotos e pratos.',
            ),
          ],
          if (current != null) ...[
            if (restaurants.length > 1) ...[
              const SizedBox(height: 16),
              DropdownButton<String>(
                isExpanded: true,
                value: current.id,
                items: [
                  for (final item in restaurants)
                    DropdownMenuItem(value: item.id, child: Text(item.name)),
                ],
                onChanged: (id) => setState(() => _selected = id),
              ),
            ],
            const SizedBox(height: 24),
            if (current.image.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Photo(
                  current.image,
                  width: double.infinity,
                  height: 180,
                ),
              ),
              const SizedBox(height: 14),
            ],
            Text(current.name, style: Theme.of(context).textTheme.titleLarge),
            if (current.address.isNotEmpty) Text(current.address),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: controller.busy ? null : () => _edit(current),
                  child: const Text('Editar dados'),
                ),
                OutlinedButton(
                  onPressed: controller.busy
                      ? null
                      : () => _add(current, _Content.photo),
                  child: const Text('Adicionar foto'),
                ),
                OutlinedButton(
                  onPressed: controller.busy
                      ? null
                      : () => _add(current, _Content.dish),
                  child: const Text('Adicionar prato'),
                ),
                OutlinedButton(
                  onPressed: controller.busy
                      ? null
                      : () => _add(current, _Content.post),
                  child: const Text('Publicar comentário'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (current.photos.isNotEmpty) ...[
              const SectionTitle('Fotos'),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: current.photos.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, index) => ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Photo(
                      current.photos[index].url,
                      width: 150,
                      height: 120,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            const SectionTitle('Cardápio'),
            if (current.dishes.isEmpty)
              const Text('Ainda não há pratos publicados.'),
            for (final dish in current.dishes)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Photo(dish.image, width: 48, height: 48),
                title: Text(dish.name),
                subtitle: dish.price == null
                    ? null
                    : Text(formatDishPrice(dish.price!)),
              ),
            const SizedBox(height: 24),
            const SectionTitle('Comentários do estabelecimento'),
            if (current.posts.isEmpty)
              const Text('Nenhum comentário publicado.'),
            for (final post in current.posts)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(post.comment),
                subtitle: Text(displayDate(post.createdAt)),
              ),
            const SizedBox(height: 24),
            const SectionTitle('Avaliações dos clientes'),
            if (reviews.isEmpty)
              const Text('Este estabelecimento ainda não recebeu avaliações.'),
            for (final review in reviews)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Avatar(review.userAvatar, radius: 18),
                title: Text(review.userName),
                subtitle: Text(review.comment),
                trailing: RatingBadge(
                  RatingSummary(review.rating.toDouble(), 1),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _RestaurantForm extends StatefulWidget {
  const _RestaurantForm({
    required this.restaurant,
    required this.categories,
    required this.controller,
    required this.repository,
  });
  final Restaurant? restaurant;
  final Future<Map<int, String>> categories;
  final AppController controller;
  final EstablishmentRepository repository;

  @override
  State<_RestaurantForm> createState() => _RestaurantFormState();
}

class _RestaurantFormState extends State<_RestaurantForm> {
  static const fields = [
    (key: 'nome', label: 'Nome do estabelecimento', min: 3, max: 100),
    (key: 'cnpj', label: 'CNPJ do estabelecimento', min: 0, max: 18),
    (key: 'descricao', label: 'Descrição', min: 0, max: 1000),
    (key: 'rua', label: 'Rua', min: 1, max: 100),
    (key: 'numero', label: 'Número', min: 0, max: 100),
    (key: 'bairro', label: 'Bairro', min: 0, max: 50),
    (key: 'cidade', label: 'Cidade', min: 1, max: 50),
    (key: 'estado', label: 'UF', min: 0, max: 2),
    (key: 'cep', label: 'CEP', min: 0, max: 9),
    (key: 'telefone', label: 'Telefone', min: 0, max: 20),
  ];
  final _form = GlobalKey<FormState>();
  late final _inputs = {
    for (final field in fields)
      field.key: TextEditingController(
        text: switch (field.key) {
          'nome' => widget.restaurant?.name,
          'descricao' => widget.restaurant?.description,
          _ => widget.restaurant?.details?[field.key] as String?,
        },
      ),
  };
  late int? _category = widget.restaurant?.details?['categoriaId'] as int?;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    for (final input in _inputs.values) {
      input.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    String? selected;
    final ok = await widget.controller.changeEstablishment(() async {
      selected = await widget.repository.saveRestaurant(widget.restaurant?.id, {
        for (final input in _inputs.entries) input.key: input.value.text.trim(),
        'categoriaId': _category,
      });
    });
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, selected);
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
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          widget.restaurant == null
              ? 'Criar estabelecimento'
              : 'Editar estabelecimento',
        ),
      ),
      body: FutureBuilder(
        future: widget.categories,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            final error = snapshot.error;
            return Center(
              child: Text(
                error is AppException
                    ? error.message
                    : 'Erro ao carregar categorias.',
              ),
            );
          }
          final categories = snapshot.data;
          if (categories == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (categories.isEmpty) {
            return const Center(child: Text('Nenhuma categoria disponível.'));
          }
          return Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                DropdownButtonFormField<int>(
                  initialValue: categories.containsKey(_category)
                      ? _category
                      : null,
                  decoration: const InputDecoration(labelText: 'Categoria'),
                  items: [
                    for (final category in categories.entries)
                      DropdownMenuItem(
                        value: category.key,
                        child: Text(category.value),
                      ),
                  ],
                  onChanged: _saving ? null : (value) => _category = value,
                  validator: (value) =>
                      value == null ? 'Escolha uma categoria.' : null,
                ),
                const SizedBox(height: 12),
                for (final field in fields)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextFormField(
                      controller: _inputs[field.key],
                      enabled: !_saving,
                      maxLength: field.max,
                      maxLines: field.key == 'descricao' ? 3 : 1,
                      decoration: InputDecoration(
                        labelText: field.label,
                        counterText: '',
                      ),
                      validator: (value) {
                        final text = (value ?? '').trim();
                        if (field.key == 'cnpj' &&
                            (widget.restaurant == null || text.isNotEmpty)) {
                          if (!RegExp(
                            r'^\d{14}$',
                          ).hasMatch(text.replaceAll(RegExp(r'[./\s-]'), ''))) {
                            return 'Informe os 14 dígitos do CNPJ.';
                          }
                        }
                        return text.length < field.min
                            ? 'Preencha este campo.'
                            : null;
                      },
                    ),
                  ),
                if (_error != null)
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                FilledButton(
                  onPressed: _saving ? null : _submit,
                  child: Text(_saving ? 'Salvando…' : 'Salvar estabelecimento'),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

enum _Content {
  photo('Adicionar foto'),
  dish('Adicionar prato'),
  post('Publicar comentário');

  const _Content(this.title);
  final String title;
}

class _PublicationForm extends StatefulWidget {
  const _PublicationForm({
    required this.kind,
    required this.controller,
    required this.repository,
    required this.id,
  });
  final _Content kind;
  final AppController controller;
  final EstablishmentRepository repository;
  final String id;

  @override
  State<_PublicationForm> createState() => _PublicationFormState();
}

class _PublicationFormState extends State<_PublicationForm> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  Uint8List? _photo;
  bool _picking = false;
  bool _saving = false;
  String? _error;
  double? get _value =>
      double.tryParse(_price.text.trim().replaceAll(',', '.'));

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    setState(() {
      _picking = true;
      _error = null;
    });
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
        requestFullMetadata: false,
      );
      if (file == null) return;
      if (await file.length() > 5 * 1024 * 1024) {
        throw const AppException('Escolha uma foto de até 5 MB.');
      }
      final bytes = await file.readAsBytes();
      if (mounted) setState(() => _photo = bytes);
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is AppException
              ? e.message
              : 'Não foi possível abrir a foto.',
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final photo = _photo;
    final kind = widget.kind;
    if (kind == _Content.photo && photo == null) {
      setState(() => _error = 'Escolha uma foto.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final repository = widget.repository;
    final id = widget.id;
    final text = _description.text.trim();
    final ok = await widget.controller.changeEstablishment(
      () => switch (kind) {
        _Content.photo => repository.addRestaurantPhoto(id, photo!, text),
        _Content.dish => repository.addDish(
          id,
          _name.text.trim(),
          text,
          _value!,
          photo,
        ),
        _Content.post => repository.publishComment(id, text),
      },
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() {
        _saving = false;
        _error = widget.controller.operationError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final kind = widget.kind;
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(title: Text(kind.title)),
        body: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (kind != _Content.post) ...[
                if (_photo case final bytes?)
                  Image.memory(
                    bytes,
                    height: 190,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const Text('Prévia indisponível para este arquivo.'),
                  ),
                OutlinedButton.icon(
                  onPressed: _saving || _picking ? null : _pick,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(
                    _picking
                        ? 'Abrindo galeria…'
                        : _photo == null
                        ? 'Escolher foto'
                        : 'Trocar foto',
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (kind == _Content.dish) ...[
                TextFormField(
                  controller: _name,
                  enabled: !_saving,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: 'Nome do prato',
                    counterText: '',
                  ),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? 'Informe o nome do prato.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _price,
                  enabled: !_saving,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: r'Preço (R$)'),
                  validator: (_) {
                    final value = _value;
                    return value != null && value.isFinite && value > 0
                        ? null
                        : 'Informe um preço válido.';
                  },
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _description,
                enabled: !_saving,
                maxLines: 4,
                maxLength: switch (kind) {
                  _Content.photo => 150,
                  _Content.dish => 300,
                  _Content.post => 1000,
                },
                decoration: InputDecoration(
                  labelText: switch (kind) {
                    _Content.photo => 'Legenda (opcional)',
                    _Content.dish => 'Descrição do prato',
                    _Content.post => 'Comentário',
                  },
                ),
                validator: (value) =>
                    kind == _Content.post && (value ?? '').trim().isEmpty
                    ? 'Escreva um comentário.'
                    : null,
              ),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _saving || _picking ? null : _submit,
                child: Text(_saving ? 'Salvando…' : 'Publicar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
