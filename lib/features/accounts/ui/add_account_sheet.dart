import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ibeta_mail_client/features/accounts/provider/account_providers.dart';
import 'package:ibeta_mail_client/features/accounts/services/google_oauth_service.dart';
import 'package:ibeta_mail_client/features/accounts/widgets/google_sign_in_web_button.dart';
class AddAccountSheet extends ConsumerStatefulWidget {
  const AddAccountSheet({super.key});

  @override
  ConsumerState<AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends ConsumerState<AddAccountSheet> {

  bool _loading = false;

  StreamSubscription<GoogleSignInAuthenticationEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _subscription = ref
          .read(googleOAuthServiceProvider)
          .authenticationEvents
          .listen((event) async {
            if (event is! GoogleSignInAuthenticationEventSignIn || _loading) {
              return;
            }
            setState(() => _loading = true);
            try {
              await ref.read(accountsProvider.notifier).finalizeWebGoogleSignIn();
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
              if (mounted) {
                setState(() => _loading = false);
              }
            }
          });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
     final googleOAuthService = ref.watch(googleOAuthServiceProvider);
    final requiresWebButton = googleOAuthService.requiresWebButton;
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
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: requiresWebButton
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            child: Icon(Icons.alternate_email),
                          ),
                          title: Text('Continuer avec Google'),
                          subtitle: Text(
                            'Sur le Web, le SDK Google impose l’utilisation du bouton officiel.',
                          ),
                                ),
                        SizedBox(
                          width: double.infinity,
                          child: Center(
                            child: buildGoogleSignInWebButton(
                              width: 320,
                              height: 44,
                            ),
                          ),
                        ),
                        if (_loading) ...[
                          const SizedBox(height: 16),
                          const Center(child: CircularProgressIndicator()),
                        ],
                      ],
                    )
                  : ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.alternate_email),
                      ),
                      title: const Text('Continuer avec Google'),
                      subtitle: const Text(
                        'IMAP/SMTP via OAuth2, sans mot de passe utilisateur.',
                      ),
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
                                    content: Text(
                                      'Impossible d’ajouter le compte Google : $error',
                                    ),
                                  ),
                                );
                              } finally {
                                if (mounted) {
                                  setState(() => _loading = false);
                                }
                              }
                            },
                    ),
            ),
          ),
          
          const SizedBox(height: 16),
           Text(
            requiresWebButton
                ? 'Astuce : sur le Web, fournissez --dart-define GOOGLE_OAUTH_CLIENT_ID. N’utilisez jamais GOOGLE_OAUTH_SERVER_CLIENT_ID sur Web.'
                : 'Astuce : configurez vos identifiants OAuth Google via --dart-define GOOGLE_OAUTH_CLIENT_ID et GOOGLE_OAUTH_SERVER_CLIENT_ID pour Android.',
          ),
        ],
      ),
    );
  }
}
