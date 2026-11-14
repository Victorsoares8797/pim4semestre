import 'package:flutter/material.dart';
import '../application/app_controller.dart';
import '../domain/repository.dart';
import 'establishment_screen.dart';
import 'explore_screen.dart';
import 'profile_screen.dart';
import 'ranking_screen.dart';
import 'theme.dart';
import 'widgets.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.controller});
  final AppController controller;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _index =
      widget.controller.user?.isOwner == true &&
          widget.controller.repository is EstablishmentRepository
      ? 4
      : 0;
  void _select(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final user = c.user;
    if (user == null) return const SizedBox.shrink();
    final repository = c.repository;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              height: 68,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: line)),
              ),
              child: Row(
                children: [
                  const Brand(),
                  const Spacer(),
                  Semantics(
                    label: 'Abrir meu perfil',
                    button: true,
                    child: IconButton(
                      tooltip: 'Meu perfil',
                      onPressed: () => _select(3),
                      icon: Avatar(user.avatar, radius: 19),
                    ),
                  ),
                ],
              ),
            ),
            if (c.busy) const LinearProgressIndicator(minHeight: 2),
            if (c.initialLoadError case final String message)
              MaterialBanner(
                content: Text(message),
                actions: [
                  TextButton(
                    onPressed: c.busy
                        ? null
                        : () async {
                            final ok = await c.refresh();
                            if (!ok && context.mounted) {
                              showFeedback(context, c.operationError);
                            }
                          },
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            Expanded(
              child: IndexedStack(
                index: _index,
                children: [
                  ExploreScreen(controller: c, onRanking: () => _select(1)),
                  RankingScreen(controller: c),
                  FavoritesScreen(controller: c, onExplore: () => _select(0)),
                  ProfileScreen(controller: c, onExplore: () => _select(0)),
                  if (user.isOwner && repository is EstablishmentRepository)
                    EstablishmentScreen(
                      controller: c,
                      repository: repository as EstablishmentRepository,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            label: 'Explorar',
          ),
          const NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            label: 'Top 10',
          ),
          const NavigationDestination(
            icon: Icon(Icons.favorite_border_rounded),
            label: 'Favoritos',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Meu perfil',
          ),
          if (user.isOwner && repository is EstablishmentRepository)
            const NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              label: 'Painel',
            ),
        ],
      ),
    );
  }
}

class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.child, this.onRefresh});
  final Widget child;
  final Future<void> Function()? onRefresh;
  @override
  Widget build(BuildContext context) {
    final scroll = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
      child: child,
    );
    return onRefresh == null
        ? scroll
        : RefreshIndicator(onRefresh: onRefresh!, child: scroll);
  }
}
