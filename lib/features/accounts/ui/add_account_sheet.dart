import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibeta_mail_client/features/accounts/provider/account_providers.dart';

class AddAccountSheet extends ConsumerStatefulWidget {
  const AddAccountSheet({super.key});

  @override
  ConsumerState<AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends ConsumerState<AddAccountSheet> {

  bool _loading = false;

 

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
       child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ajouter un compte Gmail',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          const Text(
            'Connexion sécurisée Google OAuth2. Aucun mot de passe Gmail n’est stocké dans l’application.',
          ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.alternate_email)),
              title: const Text('Continuer avec Google'),
              subtitle: const Text('IMAP/SMTP via XOAUTH2 avec token OAuth2'),
              trailing: _loading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: _loading

                  ? null
                  : () async {
                     
                      setState(() => _loading = true);
                      try {
                         await ref.read(accountsProvider.notifier).addAccountWithGoogle();
                        if (mounted) {
                          Navigator.of(context).pop();
                        }
                      } catch (error) {
                        if (!mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                             content: Text('Impossible d’ajouter le compte Google : $error'),
                          ),
                        );
                      } finally {
                        if (mounted) setState(() => _loading = false);
                      }
                    },
               ),),
          const SizedBox(height: 16),
          const Text(
            'Astuce : configurez vos identifiants OAuth Google via --dart-define GOOGLE_OAUTH_CLIENT_ID et GOOGLE_OAUTH_SERVER_CLIENT_ID.',
          )
        ],
      ),
    );
  }
}
