import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/mail_account.dart';

class AccountStorageService {
  AccountStorageService(this._secureStorage);

  static const _accountsKey = 'mail_accounts';
  static const _selectedAccountKey = 'selected_account';
  final FlutterSecureStorage _secureStorage;

  Future<List<MailAccount>> loadAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_accountsKey) ?? const [];

    final accounts = <MailAccount>[];
    for (final entry in raw) {
      final data = jsonDecode(entry) as Map<String, dynamic>;
final accountId = data['id'] as String;
      final accessToken = await _secureStorage.read(key: 'mail_access_token_$accountId');
      if (accessToken == null) {
        continue;
      }
        final refreshToken = await _secureStorage.read(key: 'mail_refresh_token_$accountId');
      accounts.add(
        MailAccount.fromJson(
          data,
          accessToken: accessToken,
          refreshToken: refreshToken,
        ),
      );
    }
    return accounts;
  }

  Future<void> saveAccounts(List<MailAccount> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _accountsKey,
      accounts.map((account) => account.serialize()).toList(),
    );
    for (final account in accounts) {
      await _secureStorage.write(
        key: 'mail_access_token_${account.id}',
        value: account.accessToken,
      );
      await _secureStorage.write(
        key: 'mail_refresh_token_${account.id}',
        value: account.refreshToken,
      );
    }
  }
 Future<void> deleteAccount(String accountId) async {
    final accounts = await loadAccounts();
    final filtered = accounts.where((account) => account.id != accountId).toList();
    await saveAccounts(filtered);
    await _secureStorage.delete(key: 'mail_access_token_$accountId');
    await _secureStorage.delete(key: 'mail_refresh_token_$accountId');
  }
  
  Future<String?> loadSelectedAccountId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedAccountKey);
  }

  Future<void> saveSelectedAccountId(String? accountId) async {
    final prefs = await SharedPreferences.getInstance();
    if (accountId == null) {
      await prefs.remove(_selectedAccountKey);
      return;
    }
    await prefs.setString(_selectedAccountKey, accountId);
  }
}
