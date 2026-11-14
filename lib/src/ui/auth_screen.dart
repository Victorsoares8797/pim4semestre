import 'package:flutter/material.dart';
import '../application/app_controller.dart';
import '../domain/validation.dart';
import 'theme.dart';
import 'widgets.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.controller,
    this.register = false,
    this.initialOwner = false,
  });
  final AppController controller;
  final bool register;
  final bool initialOwner;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class TelaCadastrese extends AuthScreen {
  const TelaCadastrese({
    super.key,
    required super.controller,
    super.initialOwner,
  }) : super(register: true);
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _document = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  late bool _owner = widget.initialOwner;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _document.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final c = widget.controller;
    final document = c.supportsDemo
        ? null
        : _document.text.replaceAll(RegExp(r'[./\s-]'), '');
    final ok = widget.register
        ? await c.register(
            _name.text,
            _email.text,
            _password.text,
            cpf: _owner ? null : document,
            cnpj: _owner ? document : null,
          )
        : await c.signIn(
            _email.text,
            _password.text,
            document: document,
            owner: _owner,
          );
    if (!mounted) return;
    if (ok && widget.register) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (!ok) {
      setState(() => _error = c.operationError);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) => Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 410),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Brand(large: true),
                    ),
                    const SizedBox(height: 32),
                    Eyebrow(
                      widget.register
                          ? 'SUA PRÓXIMA DESCOBERTA COMEÇA AQUI'
                          : 'BOM TER VOCÊ POR AQUI',
                    ),
                    const SizedBox(height: 14),
                    Text(
                      widget.register
                          ? 'Um lugar à sua mesa.'
                          : 'Entre. Sinta-se em casa.',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.register
                          ? 'Crie sua conta e compartilhe seus melhores sabores.'
                          : 'Descubra lugares, compartilhe sabores e guarde seus favoritos.',
                      style: const TextStyle(color: muted, height: 1.7),
                    ),
                    const SizedBox(height: 30),
                    if (!widget.controller.supportsDemo) ...[
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: false, label: Text('CPF')),
                          ButtonSegment(value: true, label: Text('CNPJ')),
                        ],
                        selected: {_owner},
                        onSelectionChanged: widget.controller.busy
                            ? null
                            : (choice) {
                                setState(() {
                                  _owner = choice.single;
                                  _document.clear();
                                  _error = null;
                                });
                              },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: ValueKey(_owner),
                        controller: _document,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: _owner
                              ? 'CNPJ do estabelecimento'
                              : 'CPF do cliente',
                          prefixIcon: const Icon(Icons.badge_outlined),
                        ),
                        validator: (value) {
                          final digits = (value ?? '').replaceAll(
                            RegExp(r'[./\s-]'),
                            '',
                          );
                          final expected = _owner ? 14 : 11;
                          return digits.length == expected &&
                                  RegExp(r'^\d+$').hasMatch(digits)
                              ? null
                              : 'Informe os $expected dígitos do ${_owner ? 'CNPJ' : 'CPF'}.';
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (widget.register) ...[
                      TextFormField(
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        maxLength: 60,
                        decoration: const InputDecoration(
                          labelText: 'Nome completo',
                          prefixIcon: Icon(Icons.person_outline),
                          counterText: '',
                        ),
                        validator: (v) => (v?.trim().length ?? 0) < 2
                            ? 'Informe seu nome.'
                            : null,
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                      validator: (v) => !isValidEmail(v ?? '')
                          ? 'Digite um e-mail válido.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      autofillHints: [
                        widget.register
                            ? AutofillHints.newPassword
                            : AutofillHints.password,
                      ],
                      onFieldSubmitted: (_) {
                        if (!widget.register && !widget.controller.busy) {
                          _submit();
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          tooltip: _obscure ? 'Mostrar senha' : 'Ocultar senha',
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (v) => (v?.length ?? 0) < 6
                          ? 'Use pelo menos 6 caracteres.'
                          : null,
                    ),
                    if (widget.register) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirm,
                        obscureText: _obscure,
                        decoration: const InputDecoration(
                          labelText: 'Confirmar senha',
                          prefixIcon: Icon(Icons.lock_outline_rounded),
                        ),
                        validator: (v) => v != _password.text
                            ? 'As senhas precisam ser iguais.'
                            : null,
                      ),
                    ],
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: widget.controller.busy ? null : _submit,
                      child: Text(
                        widget.controller.busy
                            ? 'Aguarde…'
                            : widget.register
                            ? 'Criar minha conta'
                            : 'Entrar na minha conta',
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (!widget.register && widget.controller.supportsDemo) ...[
                      OutlinedButton.icon(
                        onPressed: widget.controller.busy
                            ? null
                            : () async {
                                final ok = await widget.controller.demo();
                                if (!ok && mounted) {
                                  setState(
                                    () => _error =
                                        widget.controller.operationError,
                                  );
                                }
                              },
                        icon: const Icon(Icons.explore_outlined, size: 18),
                        label: const Text('Explorar demonstração'),
                      ),
                      const SizedBox(height: 18),
                    ],
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          widget.register
                              ? 'Já tem uma conta?'
                              : 'Ainda não tem conta?',
                          style: const TextStyle(fontSize: 12, color: muted),
                        ),
                        TextButton(
                          onPressed: widget.controller.busy
                              ? null
                              : () {
                                  if (widget.register) {
                                    Navigator.pop(context);
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (_) => TelaCadastrese(
                                          controller: widget.controller,
                                          initialOwner: _owner,
                                        ),
                                      ),
                                    );
                                  }
                                },
                          child: Text(
                            widget.register ? 'Entrar' : 'Cadastre-se',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (widget.controller.supportsDemo)
                      const Text(
                        'Versão de demonstração · dados temporários nesta sessão.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 10, color: muted),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
