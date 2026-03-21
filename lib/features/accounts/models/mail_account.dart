import 'dart:convert';

class MailAccount {
  const MailAccount({
    required this.id,
    required this.email,
    required this.displayName,
    required this.imapHost,
    required this.imapPort,
    required this.smtpHost,
    required this.smtpPort,
    required this.password,
    this.useSsl = true,
  });

  final String id;
  final String email;
  final String displayName;
  final String imapHost;
  final int imapPort;
  final String smtpHost;
  final int smtpPort;
  final String password;
  final bool useSsl;

  MailAccount copyWith({
    String? id,
    String? email,
    String? displayName,
    String? imapHost,
    int? imapPort,
    String? smtpHost,
    int? smtpPort,
    String? password,
    bool? useSsl,
  }) {
    return MailAccount(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      imapHost: imapHost ?? this.imapHost,
      imapPort: imapPort ?? this.imapPort,
      smtpHost: smtpHost ?? this.smtpHost,
      smtpPort: smtpPort ?? this.smtpPort,
      password: password ?? this.password,
      useSsl: useSsl ?? this.useSsl,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'imapHost': imapHost,
        'imapPort': imapPort,
        'smtpHost': smtpHost,
        'smtpPort': smtpPort,
        'useSsl': useSsl,
      };

  factory MailAccount.fromJson(Map<String, dynamic> json, {required String password}) {
    return MailAccount(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      imapHost: json['imapHost'] as String,
      imapPort: json['imapPort'] as int,
      smtpHost: json['smtpHost'] as String,
      smtpPort: json['smtpPort'] as int,
      useSsl: json['useSsl'] as bool? ?? true,
      password: password,
    );
  }

  String serialize() => jsonEncode(toJson());
}
