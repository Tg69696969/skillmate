import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});
  @override
  Widget build(BuildContext context) => SafeArea(
        child: DefaultTabController(
          length: 2,
          child: Column(children: [
            const ScreenTitle('Хүсэлтүүд'),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: C.border, borderRadius: BorderRadius.circular(14)),
              child: TabBar(
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                labelColor: C.text, unselectedLabelColor: C.muted,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                tabs: const [Tab(text: 'Ирсэн', height: 36), Tab(text: 'Илгээсэн', height: 36)],
              ),
            ),
            const SizedBox(height: 12),
            const Expanded(child: TabBarView(children: [_RequestList(incoming: true), _RequestList(incoming: false)])),
          ]),
        ),
      );
}

class _RequestList extends StatefulWidget {
  final bool incoming;
  const _RequestList({required this.incoming});
  @override
  State<_RequestList> createState() => _RequestListState();
}

class _RequestListState extends State<_RequestList> with AutomaticKeepAliveClientMixin {
  late Future<List<RequestItem>> _f = Db.requests(widget.incoming ? 'incoming' : 'outgoing');
  @override
  bool get wantKeepAlive => true;

  void _reload() => setState(() => _f = Db.requests(widget.incoming ? 'incoming' : 'outgoing'));

  Future<void> _respond(RequestItem r, String status) async {
    try {
      await Db.respond(r.id, status);
      if (!mounted) return;
      _reload();
      if (status == 'accepted') {
        snack(context, 'Зөвшөөрлөө. Одоо чатлах боломжтой.');
        context.push('/chat/${r.id}?name=${Uri.encodeComponent(r.otherName)}&other=${r.otherId}');
      }
    } catch (e) {
      if (mounted) snack(context, 'Алдаа: $e', error: true);
    }
  }

  static const _statusText = {'pending': 'Хүлээгдэж байна', 'accepted': 'Зөвшөөрсөн', 'declined': 'Татгалзсан'};

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<RequestItem>>(
      future: _f,
      builder: (c, s) {
        if (s.connectionState != ConnectionState.done) return const SkeletonList(count: 3);
        if (s.hasError) return ErrorState(error: s.error!, onRetry: _reload);
        final items = s.data!;
        if (items.isEmpty) {
          return EmptyState(
            icon: Icons.inbox_outlined,
            title: widget.incoming ? 'Ирсэн хүсэлт байхгүй байна' : 'Илгээсэн хүсэлт байхгүй байна',
            subtitle: 'Тохирох хүнээ олоод анхны хүсэлтээ илгээгээрэй.',
            action: FilledButton(onPressed: () => context.go('/home'), child: const Text('Санал болгох хүмүүсийг үзэх')),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => _reload(),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final r = items[i];
              // r.offered = илгээгчийн заах, r.wanted = илгээгчийн сурах
              final theyTeach = r.incoming ? r.offered : r.wanted;
              final iTeach = r.incoming ? r.wanted : r.offered;
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: cardDeco(),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Avatar(r.otherName.isEmpty ? '?' : String.fromCharCode(r.otherName.runes.first).toUpperCase(), size: 48),
                    const SizedBox(width: 12),
                    Expanded(child: Text(r.otherName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                    if (r.status != 'pending' || !r.incoming)
                      Text(_statusText[r.status]!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: r.status == 'declined' ? C.error : C.secondaryDark)),
                  ]),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(12)),
                    child: Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                      const Text('Тэр:', style: TextStyle(color: C.muted, fontSize: 12)), SkillChip(theyTeach),
                      const Icon(Icons.swap_horiz, size: 16, color: C.muted),
                      const Text('Та:', style: TextStyle(color: C.muted, fontSize: 12)), SkillChip(iTeach),
                    ]),
                  ),
                  if (r.message != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text('“${r.message}”', style: const TextStyle(color: C.muted))),
                  if (r.incoming && r.status == 'pending') ...[
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: OutlinedButton(onPressed: () => _respond(r, 'declined'), child: const Text('Татгалзах'))),
                      const SizedBox(width: 12),
                      Expanded(child: FilledButton(onPressed: () => _respond(r, 'accepted'), child: const Text('Зөвшөөрөх'))),
                    ]),
                  ],
                  if (r.status == 'accepted') ...[
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => context.push('/chat/${r.id}?name=${Uri.encodeComponent(r.otherName)}&other=${r.otherId}'),
                      child: const Text('Чат нээх'),
                    ),
                  ],
                ]),
              );
            },
          ),
        );
      },
    );
  }
}
