import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});
  @override
  State<ChatListScreen> createState() => _ChatListState();
}

class _ChatListState extends State<ChatListScreen> {
  late Future<List<RequestItem>> _f = Db.requests('accepted');
  void _reload() => setState(() => _f = Db.requests('accepted'));

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Column(children: [
          const ScreenTitle('Чат'),
          Expanded(
            child: FutureBuilder<List<RequestItem>>(
              future: _f,
              builder: (c, s) {
                if (s.connectionState != ConnectionState.done) return const SkeletonList(count: 3);
                if (s.hasError) return ErrorState(error: s.error!, onRetry: _reload);
                final items = s.data!;
                if (items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.chat_bubble_outline,
                    title: 'Чат байхгүй байна',
                    subtitle: 'Хүсэлт зөвшөөрөгдсөний дараа энд чат нээгдэнэ.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: ListView(padding: const EdgeInsets.symmetric(horizontal: 20), children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: cardDeco(),
                      child: Column(children: [
                        for (final r in items)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Avatar(String.fromCharCode(r.otherName.runes.first).toUpperCase(), size: 52),
                            title: Text(r.otherName, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('${r.offered} ↔ ${r.wanted}', style: const TextStyle(color: C.muted)),
                            onTap: () => context.push('/chat/${r.id}?name=${Uri.encodeComponent(r.otherName)}&other=${r.otherId}'),
                          ),
                      ]),
                    ),
                  ]),
                );
              },
            ),
          ),
        ]),
      );
}

class ChatScreen extends StatefulWidget {
  final int requestId;
  final String otherId, otherName;
  const ChatScreen({super.key, required this.requestId, required this.otherId, required this.otherName});
  @override
  State<ChatScreen> createState() => _ChatState();
}

class _ChatState extends State<ChatScreen> {
  final _ctrl = TextEditingController();
  late final Stream<List<Map<String, dynamic>>> _stream = Db.messages(widget.requestId);

  Future<void> _send() async {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;
    _ctrl.clear();
    try {
      await Db.sendMessage(widget.requestId, t);
    } catch (e) {
      if (mounted) snack(context, 'Илгээж чадсангүй: $e', error: true);
    }
  }

  Future<void> _block() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('${widget.otherName}-г блоклох уу?'),
        content: const Text('Блоклосон хэрэглэгч таны профайлыг харахгүй, мессеж илгээж чадахгүй.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Болих')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Блоклох', style: TextStyle(color: C.error))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Db.block(widget.otherId, widget.otherName);
      if (mounted) {
        snack(context, 'Блоклолоо');
        context.pop();
      }
    } catch (e) {
      if (mounted) snack(context, 'Алдаа: $e', error: true);
    }
  }

  Future<void> _report() async {
    final ctrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Хэрэглэгчийг мэдээлэх'),
        content: TextField(controller: ctrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Шалтгаанаа бичнэ үү')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Болих')),
          TextButton(onPressed: () => Navigator.pop(c, ctrl.text.trim()), child: const Text('Илгээх')),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;
    try {
      await Db.report(widget.otherId, reason);
      if (mounted) snack(context, 'Мэдээлэл хүлээн авлаа. Баярлалаа.');
    } catch (e) {
      if (mounted) snack(context, 'Алдаа: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: C.surface, surfaceTintColor: Colors.transparent,
          title: Row(children: [
            Avatar(widget.otherName.isEmpty ? '?' : String.fromCharCode(widget.otherName.runes.first).toUpperCase(), size: 40, color: C.secondary),
            const SizedBox(width: 12),
            Text(widget.otherName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ]),
          actions: [
            PopupMenuButton<String>(
              onSelected: (v) => v == 'block' ? _block() : _report(),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'report', child: Text('Мэдээлэх')),
                PopupMenuItem(value: 'block', child: Text('Блоклох')),
              ],
            ),
          ],
        ),
        body: Column(children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _stream,
              builder: (c, s) {
                if (s.hasError) return ErrorState(error: s.error!, onRetry: () => setState(() {}));
                if (!s.hasData) return const Center(child: CircularProgressIndicator());
                final msgs = s.data!.reversed.toList();
                if (msgs.isEmpty) {
                  return const EmptyState(icon: Icons.waving_hand_outlined, title: 'Мессеж байхгүй', subtitle: 'Анхны мессежээ бичээрэй!');
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) {
                    final m = msgs[i];
                    final mine = m['sender_id'] == myId;
                    return Align(
                      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: mine ? C.primary : C.surface,
                          border: mine ? null : Border.all(color: C.border),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
                            bottomLeft: Radius.circular(mine ? 18 : 4), bottomRight: Radius.circular(mine ? 4 : 18),
                          ),
                        ),
                        child: Text(m['content'], style: TextStyle(color: mine ? Colors.white : C.text, fontSize: 15)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + MediaQuery.of(context).padding.bottom),
            decoration: const BoxDecoration(color: C.surface, border: Border(top: BorderSide(color: C.border))),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _ctrl, minLines: 1, maxLines: 4, maxLength: 2000, onSubmitted: (_) => _send(),
                  decoration: const InputDecoration(hintText: 'Мессеж бичих...', counterText: '', fillColor: C.bg),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(onPressed: _send, icon: const Icon(Icons.arrow_upward), style: IconButton.styleFrom(backgroundColor: C.primary)),
            ]),
          ),
        ]),
      );
}
