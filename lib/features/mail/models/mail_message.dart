class MailMessage {
  const MailMessage({
    required this.uid,
    required this.subject,
    required this.from,
    required this.preview,
    required this.date,
    required this.isRead,
     this.to = '',
    this.body = '',
  });

  final String uid;
  final String subject;
  final String from;
  final String preview;
  final DateTime date;
  final bool isRead;
   final String to;
  final String body;

  MailMessage copyWith({
    String? uid,
    String? subject,
    String? from,
    String? preview,
    DateTime? date,
    bool? isRead,
      String? to,
    String? body,
  }) {
    return MailMessage(
      uid: uid ?? this.uid,
      subject: subject ?? this.subject,
      from: from ?? this.from,
      preview: preview ?? this.preview,
      date: date ?? this.date,
      isRead: isRead ?? this.isRead,
      to: to ?? this.to,
      body: body ?? this.body,
    );
  }
}
