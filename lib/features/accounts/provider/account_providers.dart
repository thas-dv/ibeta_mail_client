import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/mail_account.dart';
import '../services/account_storage_service.dart';
import '../services/mail_provider_config.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

final secureStorageProvider = Provider((ref) => const FlutterSecureStorage());

final accountStorageProvider = Provider(
  (ref) => AccountStorageService(ref.watch(secureStorageProvider)),
);

final accountsProvider = AsyncNotifierProvider<AccountsNotifier, List<MailAccount>>(
  AccountsNotifier.new,
);

final selectedAccountIdProvider = StateProvider<String?>((ref) => null);

final selectedAccountProvider = Provider<MailAccount?>((ref) {
  final accountsValue = ref.watch(accountsProvider).value ?? const <MailAccount>[];
  final selectedId = ref.watch(selectedAccountIdProvider);
  if (accountsValue.isEmpty) {
    return null;
  }
  return accountsValue.firstWhere(
    (account) => account.id == selectedId,
    orElse: () => accountsValue.first,
  );
});

class AccountsNotifier extends AsyncNotifier<List<MailAccount>> {
  @override
  Future<List<MailAccount>> build() async {
    final accounts = await ref.watch(accountStorageProvider).loadAccounts();
    final selectedId = await ref.watch(accountStorageProvider).loadSelectedAccountId();
    ref.read(selectedAccountIdProvider.notifier).state = selectedId;
    return accounts;
  }

  Future<void> addAccount({
    required String email,
    required String displayName,
    required String password,
  }) async {
    final current = state.value ?? <MailAccount>[];
    final account = MailProviderResolver.buildAccount(
      email: email,
      displayName: displayName,
      password: password,
    );
    final updated = [...current.where((entry) => entry.id != account.id), account];
    state = AsyncData(updated);
    await ref.watch(accountStorageProvider).saveAccounts(updated);
    await selectAccount(account.id);
  }

  Future<void> selectAccount(String? accountId) async {
    ref.read(selectedAccountIdProvider.notifier).state = accountId;
    await ref.watch(accountStorageProvider).saveSelectedAccountId(accountId);
  }
}
