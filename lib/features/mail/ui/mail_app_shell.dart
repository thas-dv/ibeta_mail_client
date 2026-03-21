import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibeta_mail_client/features/accounts/provider/account_providers.dart';


import '../../accounts/ui/accounts_drawer.dart';
import '../../compose/ui/compose_page.dart';
import '../providers/mail_providers.dart';
import 'widgets/mail_list_tile.dart';

class MailAppShell extends ConsumerStatefulWidget {
  const MailAppShell({super.key});

  @override
  ConsumerState<MailAppShell> createState() => _MailAppShellState();
}

class _MailAppShellState extends ConsumerState<MailAppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(selectedAccountProvider);
    final inbox = ref.watch(inboxControllerProvider);

    return Scaffold(
      drawer: const AccountsDrawer(),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Boîte de réception'),
            Text(
              account?.email ?? 'Ajoutez un compte',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _index,
        children: [
          RefreshIndicator(
            onRefresh: () => ref.read(inboxControllerProvider.notifier).refresh(),
            child: inbox.when(
              data: (messages) {
                if (account == null) {
                  return const _EmptyState(
                    icon: Icons.account_circle_outlined,
                    title: 'Aucun compte configuré',
                    subtitle: 'Ajoutez un compte Gmail, Outlook, Yahoo ou IMAP personnalisé depuis le menu.',
                  );
                }
                if (messages.isEmpty) {
                  return const _EmptyState(
                    icon: Icons.mark_email_read_outlined,
                    title: 'Aucun message en cache',
                    subtitle: 'Tirez pour rafraîchir afin de charger les messages IMAP.',
                  );
                }
                return NotificationListener<ScrollEndNotification>(
                  onNotification: (notification) {
                    if (notification.metrics.pixels >= notification.metrics.maxScrollExtent - 120) {
                      ref.read(inboxControllerProvider.notifier).loadMore();
                    }
                    return false;
                  },
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return MailListTile(
                        message: message,
                        onToggleRead: () => ref.read(inboxControllerProvider.notifier).toggleRead(message),
                        onDelete: () => ref.read(inboxControllerProvider.notifier).deleteMessage(message),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _EmptyState(
                icon: Icons.cloud_off,
                title: 'Connexion impossible',
                subtitle: '$error',
              ),
            ),
          ),
          const _SettingsPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.inbox_outlined), selectedIcon: Icon(Icons.inbox), label: 'Inbox'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Réglages'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ComposePage()));
        },
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Composer'),
      ),
    );
  }
}

class _SettingsPage extends ConsumerWidget {
  const _SettingsPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(selectedAccountProvider);
    final themeMode = ref.watch(themeModeProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            title: const Text('Compte actif'),
            subtitle: Text(account?.email ?? 'Aucun'),
          ),
        ),
        Card(
          child: SwitchListTile(
            value: themeMode == ThemeMode.dark,
            title: const Text('Dark mode'),
            subtitle: const Text('Bascule entre les thèmes clair et sombre.'),
            onChanged: (value) {
              ref.read(themeModeProvider.notifier).state = value ? ThemeMode.dark : ThemeMode.light;
            },
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 72),
                  const SizedBox(height: 16),
                  Text(title, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(subtitle, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
