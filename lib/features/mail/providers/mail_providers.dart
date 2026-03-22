import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibeta_mail_client/features/accounts/provider/account_providers.dart';

import '../../accounts/models/mail_account.dart';

import '../models/mail_message.dart';
import '../services/mail_cache_service.dart';
import '../services/mail_service.dart';

final mailServiceProvider = Provider(
  (ref) => MailService(
    refreshToken: (account) => ref.read(accountsProvider.notifier).refreshAccountToken(account),
  ),
);
final mailCacheServiceProvider = Provider((ref) => MailCacheService());

final inboxControllerProvider = AsyncNotifierProvider<InboxController, List<MailMessage>>(
  InboxController.new,
);
final messageDetailProvider = FutureProvider.family<MailMessage?, String>((ref, uid) async {
  final account = ref.watch(selectedAccountProvider);
  if (account == null) {
    return null;
  }

  final inbox = ref.watch(inboxControllerProvider).value ?? const <MailMessage>[];
  MailMessage? cached;
  for (final message in inbox) {
    if (message.uid == uid) {
      cached = message;
      break;
    }
  }

  return ref.watch(mailServiceProvider).fetchMessageDetail(
        account,
        uid,
        fallback: cached,
      );
});
class InboxController extends AsyncNotifier<List<MailMessage>> {
  int _page = 0;
  bool _hasMore = true;
  StreamSubscription<void>? _subscription;

  bool get hasMore => _hasMore;

  @override
  Future<List<MailMessage>> build() async {
    ref.listen<MailAccount?>(selectedAccountProvider, (_, next) async {
      _page = 0;
      _hasMore = true;
      state = const AsyncLoading();
      state = await AsyncValue.guard(_loadInitial);
      await _subscription?.cancel();
      if (next != null) {
        _subscription = ref.watch(mailServiceProvider).watchInbox(next).listen((_) {
          refresh();
        });
      }
    });
    ref.onDispose(() => _subscription?.cancel());
    return _loadInitial();
  }

  Future<List<MailMessage>> _loadInitial() async {
    final account = ref.read(selectedAccountProvider);
    if (account == null) {
      return const [];
    }
    final cache = await ref.watch(mailCacheServiceProvider).loadInbox(account.id);
    unawaited(refresh(showLoader: false));
    return cache;
  }

  Future<void> refresh({bool showLoader = true}) async {
    final account = ref.read(selectedAccountProvider);
    if (account == null) {
      state = const AsyncData([]);
      return;
    }
    _page = 0;
    _hasMore = true;
    if (showLoader) {
      state = const AsyncLoading();
    }
    state = await AsyncValue.guard(() async {
      final messages = await ref.watch(mailServiceProvider).fetchInbox(account, page: 0);
      _hasMore = messages.length == 20;
      await ref.watch(mailCacheServiceProvider).saveInbox(account.id, messages);
      return messages;
    });
  }

  Future<void> loadMore() async {
    if (!_hasMore || state.isLoading) {
      return;
    }
    final account = ref.read(selectedAccountProvider);
    if (account == null) {
      return;
    }
    final current = state.value ?? const <MailMessage>[];
    final nextPage = _page + 1;
    final more = await ref.watch(mailServiceProvider).fetchInbox(account, page: nextPage);
    _page = nextPage;
    _hasMore = more.length == 20;
    state = AsyncData([...current, ...more]);
  }
  Future<void> openMessage(MailMessage message) async {
    if (!message.isRead) {
      await toggleRead(message, forceRead: true);
    }
    ref.invalidate(messageDetailProvider(message.uid));
  }

  Future<void> toggleRead(MailMessage message, {bool? forceRead}) async {
    final account = ref.read(selectedAccountProvider);
    if (account == null) {
      return;
    }
   final nextRead = forceRead ?? !message.isRead;
    await ref.watch(mailServiceProvider).markAsRead(account, message.uid, read: nextRead);
    final updated = [
      for (final item in state.value ?? const <MailMessage>[])
      if (item.uid == message.uid) item.copyWith(isRead: nextRead) else item,
    ];
       state = AsyncData(updated);
    await ref.watch(mailCacheServiceProvider).saveInbox(account.id, updated);
     ref.invalidate(messageDetailProvider(message.uid));
  }

  Future<void> deleteMessage(MailMessage message) async {
    final account = ref.read(selectedAccountProvider);
    if (account == null) {
      return;
    }
    await ref.watch(mailServiceProvider).deleteMessage(account, message.uid);
     final updated = [
      for (final item in state.value ?? const <MailMessage>[])
        if (item.uid != message.uid) item,
    ];
     state = AsyncData(updated);
    await ref.watch(mailCacheServiceProvider).saveInbox(account.id, updated);
     ref.invalidate(messageDetailProvider(message.uid));
  }
}
