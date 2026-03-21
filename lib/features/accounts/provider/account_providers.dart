import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/mail_account.dart';
import '../services/account_storage_service.dart';
import '../services/google_oauth_service.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

final secureStorageProvider = Provider((ref) => const FlutterSecureStorage());

final accountStorageProvider = Provider(
  (ref) => AccountStorageService(ref.watch(secureStorageProvider)),
);
final googleOAuthServiceProvider = Provider((ref) => GoogleOAuthService());
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
     await ref.read(googleOAuthServiceProvider).initialize();
    final accounts = await ref.watch(accountStorageProvider).loadAccounts();
    final selectedId = await ref.watch(accountStorageProvider).loadSelectedAccountId();
    ref.read(selectedAccountIdProvider.notifier).state = selectedId;
    return accounts;
  }

   Future<void> addAccountWithGoogle() async {
    final current = state.value ?? <MailAccount>[];
   final account = await ref.read(googleOAuthServiceProvider).authenticate();
    
    final updated = [...current.where((entry) => entry.id != account.id), account];
    state = AsyncData(updated);
    await ref.watch(accountStorageProvider).saveAccounts(updated);
    await selectAccount(account.id);
  }
    Future<MailAccount> refreshAccountToken(MailAccount account) async {
    final refreshed = await ref.read(googleOAuthServiceProvider).refreshAccount(account);
    final current = state.value ?? const <MailAccount>[];
    final updated = [
      for (final entry in current) if (entry.id == refreshed.id) refreshed else entry,
    ];
    state = AsyncData(updated);
    await ref.watch(accountStorageProvider).saveAccounts(updated);
    return refreshed;
  }

  Future<void> removeAccount(String accountId) async {
    final current = state.value ?? const <MailAccount>[];
    final updated = current.where((account) => account.id != accountId).toList();
    state = AsyncData(updated);
    await ref.watch(accountStorageProvider).deleteAccount(accountId);

    final selectedId = ref.read(selectedAccountIdProvider);
    if (selectedId == accountId) {
      await selectAccount(updated.isEmpty ? null : updated.first.id);
    }
  }

  Future<void> selectAccount(String? accountId) async {
    ref.read(selectedAccountIdProvider.notifier).state = accountId;
    await ref.watch(accountStorageProvider).saveSelectedAccountId(accountId);
  }
}
