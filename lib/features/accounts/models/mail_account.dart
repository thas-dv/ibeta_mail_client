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
   required this.accessToken,
    required this.refreshToken,
    this.photoUrl,
    this.serverAuthCode,
    this.useSsl = true,
  });

  final String id;
  final String email;
  final String displayName;
  final String imapHost;
  final int imapPort;
  final String smtpHost;
  final int smtpPort;
  final String accessToken;
  final String? refreshToken;
  final String? photoUrl;
  final String? serverAuthCode;
  final bool useSsl;

  MailAccount copyWith({
    String? id,
    String? email,
    String? displayName,
    String? imapHost,
    int? imapPort,
    String? smtpHost,
    int? smtpPort,
    String? accessToken,
    String? refreshToken,
    String? photoUrl,
    String? serverAuthCode,
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
 accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      photoUrl: photoUrl ?? this.photoUrl,
      serverAuthCode: serverAuthCode ?? this.serverAuthCode,
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
         'photoUrl': photoUrl,
        'serverAuthCode': serverAuthCode,
        'useSsl': useSsl,
      };

  factory MailAccount.fromJson(
    Map<String, dynamic> json, {
    required String accessToken,
    required String? refreshToken,
  }) {
    return MailAccount(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      imapHost: json['imapHost'] as String,
      imapPort: json['imapPort'] as int,
      smtpHost: json['smtpHost'] as String,
      smtpPort: json['smtpPort'] as int,
        photoUrl: json['photoUrl'] as String?,
      serverAuthCode: json['serverAuthCode'] as String?,
      useSsl: json['useSsl'] as bool? ?? true,
  accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  String serialize() => jsonEncode(toJson());
}
