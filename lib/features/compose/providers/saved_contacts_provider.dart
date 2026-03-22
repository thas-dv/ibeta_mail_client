import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final savedContactsProvider =
    AsyncNotifierProvider<SavedContactsNotifier, List<String>>(
  SavedContactsNotifier.new,
);

class SavedContactsNotifier extends AsyncNotifier<List<String>> {
  static const _storageKey = 'saved_mail_addresses';

  @override
  Future<List<String>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final contacts = prefs.getStringList(_storageKey) ?? <String>[];
    contacts.sort();
    return contacts;
  }

  Future<void> addAddress(String email) async {
    final normalized = email.trim().toLowerCase();
    if (!_isValidEmail(normalized)) {
      throw StateError('Adresse email invalide.');
    }
    final current = [...?state.value];
    if (!current.contains(normalized)) {
      current.add(normalized);
      current.sort();
      await _save(current);
    }
  }

  Future<void> removeAddress(String email) async {
    final current = [...?state.value]..remove(email);
    await _save(current);
  }

  bool _isValidEmail(String value) {
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return regex.hasMatch(value);
  }

  Future<void> _save(List<String> values) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, values);
    state = AsyncData(values);
  }
}
