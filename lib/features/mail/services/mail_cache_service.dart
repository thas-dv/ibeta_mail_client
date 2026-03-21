import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/mail_message.dart';

class MailCacheService {
  Future<List<MailMessage>> loadInbox(String accountId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('cache_inbox_$accountId');
    if (raw == null) {
      return const [];
    }
    final data = jsonDecode(raw) as List<dynamic>;
    return data
        .map(
          (entry) => MailMessage(
            uid: entry['uid'] as int,
            subject: entry['subject'] as String,
            from: entry['from'] as String,
            preview: entry['preview'] as String,
            date: DateTime.parse(entry['date'] as String),
            isRead: entry['isRead'] as bool,
          ),
        )
        .toList();
  }

  Future<void> saveInbox(String accountId, List<MailMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'cache_inbox_$accountId',
      jsonEncode(
        messages
            .map(
              (message) => {
                'uid': message.uid,
                'subject': message.subject,
                'from': message.from,
                'preview': message.preview,
                'date': message.date.toIso8601String(),
                'isRead': message.isRead,
              },
            )
            .toList(),
      ),
    );
  }
}
