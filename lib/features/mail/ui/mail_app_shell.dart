import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibeta_mail_client/features/accounts/provider/account_providers.dart';
import 'package:intl/intl.dart';
import '../../compose/providers/saved_contacts_provider.dart';
import '../models/mail_message.dart';
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
             Text(_index == 0 ? 'Boîte de réception' : 'Paramètres'),
            Text(
              account?.email ?? 'Ajoutez un compte Gmail',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _index,
        children: [
          RefreshIndicator(
            onRefresh: () =>
                ref.read(inboxControllerProvider.notifier).refresh(),
            child: inbox.when(
              data: (messages) {
                if (account == null) {
                  return const _EmptyState(
                    icon: Icons.account_circle_outlined,
                    title: 'Aucun compte Gmail connecté',
                    subtitle:
                        'Ajoutez un compte via Google OAuth2 pour synchroniser vos emails sans mot de passe.',
                  );
                }
                if (messages.isEmpty) {
                  return const _EmptyState(
                    icon: Icons.mark_email_read_outlined,
                    title: 'Aucun message en cache',
                    subtitle:
                        'Tirez pour rafraîchir afin de charger les messages Gmail via IMAP XOAUTH2.',
                  );
                }
                return NotificationListener<ScrollEndNotification>(
                  onNotification: (notification) {
                    if (notification.metrics.pixels >=
                        notification.metrics.maxScrollExtent - 120) {
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
                         onOpen: () async {
                          await ref
                              .read(inboxControllerProvider.notifier)
                              .openMessage(message);
                          if (!context.mounted) {
                            return;
                          }
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => MailMessageDetailPage(
                                messageUid: message.uid,
                              ),
                            ),
                          );
                        },

                        onToggleRead: () => ref
                            .read(inboxControllerProvider.notifier)
                            .toggleRead(message),
                        onDelete: () => ref
                            .read(inboxControllerProvider.notifier)
                            .deleteMessage(message),
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
          NavigationDestination(
            icon: Icon(Icons.inbox_outlined),
            selectedIcon: Icon(Icons.inbox),
            label: 'Inbox',
          ),
           NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Paramètres',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
         onPressed: account == null
            ? null
            : () {
                 Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ComposePage(),
                  ),
                );
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
    final accounts = ref.watch(accountsProvider).value ?? const [];
    final themeMode = ref.watch(themeModeProvider);
 final savedContacts = ref.watch(savedContactsProvider).value ?? const [];
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
          child: ListTile(
            title: const Text('Comptes locaux'),
            subtitle: Text(
              '${accounts.length} compte(s) Gmail enregistrés sur cet appareil',
            ),
          ),
        ),
        Card(
          child: ListTile(
            title: const Text('Adresses enregistrées'),
            subtitle: Text(
              '${savedContacts.length} adresse(s) email réutilisable(s) dans la rédaction',
            ),
          ),
        ),
        Card(
          child: const ListTile(
            title: Text('Suppression locale'), 
            subtitle: Text(
              'Retirer un compte dans l’application ne supprime jamais le compte Gmail réel ni les emails côté serveur.',
            ),
          ),
        ),
        Card(
          child: SwitchListTile(
            value: themeMode == ThemeMode.dark,
            title: const Text('Dark mode'),
            subtitle: const Text('Bascule entre les thèmes clair et sombre.'),
            onChanged: (value) {
              ref.read(themeModeProvider.notifier).state =
                  value ? ThemeMode.dark : ThemeMode.light;
            },
          ),
        ),
      ],
    );
  }
}
class MailMessageDetailPage extends ConsumerWidget {
  const MailMessageDetailPage({
    super.key,
    required this.messageUid,
  });

  final String messageUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(messageDetailProvider(messageUid));
    final account = ref.watch(selectedAccountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Message'),
        actions: [
          IconButton(
            tooltip: 'Rédiger',
            onPressed: account == null
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ComposePage(),
                      ),
                    );
                  },
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erreur: $error')),
        data: (message) {
          if (message == null) {
            return const Center(child: Text('Message introuvable.'));
          }

          final formattedDate =
              DateFormat('dd MMM yyyy • HH:mm').format(message.date);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                message.subject,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    child: Text(
                      message.from.isNotEmpty
                          ? message.from[0].toUpperCase()
                          : '?',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.from,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (message.to.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('À : ${message.to}'),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          formattedDate,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SelectableText(
                message.body.isEmpty ? message.preview : message.body,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(height: 1.5),
              ),
              if (message.body.isEmpty && message.preview.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Le corps complet n’était pas disponible, aperçu affiché.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          );
        },
      ),
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
