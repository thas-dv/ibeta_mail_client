import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibeta_mail_client/features/accounts/provider/account_providers.dart';

import 'add_account_sheet.dart';

class AccountsDrawer extends ConsumerWidget {
  const AccountsDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider);
    final selected = ref.watch(selectedAccountProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            ListTile(
              title: const Text('iBeta Mail'),
              subtitle: const Text('Client IMAP + SMTP multi-comptes'),
              trailing: IconButton(
                icon: Icon(themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode),
                onPressed: () {
                  ref.read(themeModeProvider.notifier).state =
                      themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
                },
              ),
            ),
            const Divider(),
            Expanded(
              child: accounts.when(
                data: (items) => ListView(
                  children: [
                    for (final account in items)
                      ListTile(
                        leading: CircleAvatar(child: Text(account.email.characters.first.toUpperCase())),
                        title: Text(account.displayName),
                        subtitle: Text(account.email),
                        selected: selected?.id == account.id,
                        onTap: () async {
                          await ref.read(accountsProvider.notifier).selectAccount(account.id);
                          if (context.mounted) Navigator.of(context).pop();
                        },
                      ),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Erreur: $error')),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const AddAccountSheet(),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un compte'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
