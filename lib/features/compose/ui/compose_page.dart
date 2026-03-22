import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/saved_contacts_provider.dart';
import '../providers/compose_providers.dart';

class ComposePage extends ConsumerStatefulWidget {
  const ComposePage({super.key});

  @override
  ConsumerState<ComposePage> createState() => _ComposePageState();
}

class _ComposePageState extends ConsumerState<ComposePage> {
  final _formKey = GlobalKey<FormState>();
  final _toController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();

  @override
  void dispose() {
    _toController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final composeState = ref.watch(composeControllerProvider);
 final savedContacts = ref.watch(savedContactsProvider).value ?? const [];
    ref.listen(composeControllerProvider, (previous, next) {
      next.whenOrNull(
        data: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email envoyé.')),
          );
          Navigator.of(context).pop();
        },
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Échec de l’envoi: $error')),
          );
        },
      );
    });

    return Scaffold(
        appBar: AppBar(
        title: const Text('Nouveau message'),
        actions: [
          IconButton(
            tooltip: 'Enregistrer l’adresse',
            onPressed: () async {
              final email = _toController.text.trim();
              if (email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Saisissez une adresse email à enregistrer.')),
                );
                return;
              }
              try {
                await ref.read(savedContactsProvider.notifier).addAddress(email);
                if (!context.mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Adresse enregistrée : $email')),
                );
              } catch (error) {
                if (!context.mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$error')),
                );
              }
            },
            icon: const Icon(Icons.person_add_alt_1_outlined),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _toController,
                decoration: const InputDecoration(labelText: 'Destinataire'),
                validator: (value) => value != null && value.contains('@') ? null : 'Destinataire invalide',
              ),
               if (savedContacts.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Adresses enregistrées',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final email in savedContacts)
                      InputChip(
                        label: Text(email),
                        onPressed: () {
                          _toController.text = email;
                        },
                        onDeleted: () async {
                          await ref.read(savedContactsProvider.notifier).removeAddress(email);
                        },
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _subjectController,
                  decoration: const InputDecoration(labelText: 'Sujet'),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TextFormField(
                  controller: _bodyController,
                  minLines: 12,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                     labelText: 'Message',
                    hintText: 'Écrivez votre email ici…',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: composeState.isLoading
            ? null
            : () async {
                if (!_formKey.currentState!.validate()) {
                  return;
                }
                final to = _toController.text.trim();
                await ref.read(composeControllerProvider.notifier).send(
                      to: to,
                      subject: _subjectController.text.trim(),
                      body: _bodyController.text,
                    );
                    await ref.read(savedContactsProvider.notifier).addAddress(to);
              },
        icon: composeState.isLoading
            ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.send),
        label: Text(composeState.isLoading ? 'Envoi…' : 'Envoyer'),
      ),
    );
  }
}
