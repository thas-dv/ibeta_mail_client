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
      final password = await _secureStorage.read(key: 'mail_password_${data['id']}');
      if (password != null) {
        accounts.add(MailAccount.fromJson(data, password: password));
      }
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
        key: 'mail_password_${account.id}',
        value: account.password,
      );
    }
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
