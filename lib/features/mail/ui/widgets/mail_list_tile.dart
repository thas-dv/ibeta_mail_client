import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/mail_message.dart';

class MailListTile extends StatelessWidget {
  const MailListTile({
    super.key,
    required this.message,
    required this.onOpen,
    required this.onToggleRead,
    required this.onDelete,
  });

  final MailMessage message;
   final VoidCallback onOpen;
  final VoidCallback onToggleRead;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd MMM').format(message.date);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
       child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onOpen,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: CircleAvatar(
            child: Text(message.from.isNotEmpty ? message.from[0].toUpperCase() : '?'),
          ),
          title: Text(
            message.from,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: message.isRead ? FontWeight.w500 : FontWeight.w800,
                ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                message.subject,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: message.isRead ? FontWeight.w400 : FontWeight.w700,
                    ),

              ),
        
    const SizedBox(height: 2),
              Text(
                message.preview.isEmpty ? 'Aperçu indisponible' : message.preview,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(date),
              const SizedBox(height: 8),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'read') onToggleRead();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'read',
                    child: Text(message.isRead ? 'Marquer non lu' : 'Marquer lu'),
                  ),
            

                  const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
