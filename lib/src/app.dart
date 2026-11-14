import 'package:flutter/material.dart';
import 'application/app_controller.dart';
import 'data/in_memory_repository.dart';
import 'domain/repository.dart';
import 'ui/auth_screen.dart';
import 'ui/shell.dart';
import 'ui/theme.dart';

class BuillonApp extends StatefulWidget {
  const BuillonApp({super.key, this.repository});
  final BuillonRepository? repository;
  @override
  State<BuillonApp> createState() => _BuillonAppState();
}

class _BuillonAppState extends State<BuillonApp> {
  late final controller = AppController(
    widget.repository ?? InMemoryBuillonRepository(),
  );
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Buillon · À sua mesa',
    debugShowCheckedModeBanner: false,
    theme: buillonTheme(),
    // Em uma janela de prévia maior, mantém a mesma composição de celular.
    builder: (context, child) => LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.clamp(0.0, 480.0);
        return ColoredBox(
          color: const Color(0xFFE7EBE4),
          child: Center(
            child: SizedBox(
              width: width,
              child: MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(size: Size(width, constraints.maxHeight)),
                child: child!,
              ),
            ),
          ),
        );
      },
    ),
    home: ListenableBuilder(
      listenable: controller,
      builder: (_, _) => controller.user == null
          ? AuthScreen(controller: controller)
          : AppShell(controller: controller),
    ),
  );
}
