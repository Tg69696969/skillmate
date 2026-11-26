import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data.dart';
import '../matching.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

class _HomeData {
  final UserProfile me;
  final List<MatchResult> matches;
  _HomeData(this.me, this.matches);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeState();
}

class _HomeState extends State<HomeScreen> {
  late Future<_HomeData> _f = _load();
  final Set<String> _skipped = {};
  String? _filter;

  Future<_HomeData> _load() async {
    final me = await Db.me();
    final cands = await Db.candidates();
    // Нийцэл 0 болон тэг оноотой хүмүүсийг харуулахгүй
    final ranked = rankMatches(me, cands).where((m) => m.score > 0).toList();
    return _HomeData(me, ranked);
  }

  void _reload() => setState(() => _f = _load());

  Future<void> _request(UserProfile me, MatchResult m) async {
    if (me.offers.isEmpty) {
      snack(context, 'Эхлээд "Миний ур чадвар"-аас зааж чадах ур чадвараа нэмнэ үү', error: true);
      context.push('/skills');
      return;
    }
    if (m.other.offers.isEmpty) return snack(context, 'Энэ хэрэглэгч заах ур чадвар нэмээгүй байна', error: true);
    final result = await showModalBottomSheet<bool>(
      context: context, isScrollControlled: true, showDragHandle: true,
      builder: (_) => _RequestSheet(me: me, m: m),
    );
    if (result == true) {
      if (mounted) snack(context, 'Хүсэлт илгээгдлээ');
      setState(() => _skipped.add(m.other.id));
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: FutureBuilder<_HomeData>(
          future: _f,
          builder: (c, s) {
            if (s.connectionState != ConnectionState.done) return const SkeletonList();
            if (s.hasError) return ErrorState(error: s.error!, onRetry: _reload);
            final d = s.data!;
            final skills = {for (final m in d.matches) ...m.other.offers.keys}.toList()..sort();
            final list = d.matches
                .where((m) => !_skipped.contains(m.other.id) && (_filter == null || m.other.offers.containsKey(_filter)))
                .toList();
            return RefreshIndicator(
              onRefresh: () async => _reload(),
              child: ListView(padding: const EdgeInsets.only(bottom: 24), children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                        Text('Өнөөдрийн санал', style: TextStyle(color: C.muted, fontSize: 13, fontWeight: FontWeight.w500)),
                        Text('Танд тохирох хүмүүс', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                    GestureDetector(onTap: () => context.go('/profile'), child: Avatar(d.me.initial, size: 44, color: C.primaryTint)),
                  ]),
                ),
                if (skills.isNotEmpty)
                  SizedBox(
                    height: 40,
                    child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20), children: [
                      Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: const Text('Бүгд'), selected: _filter == null, onSelected: (_) => setState(() => _filter = null))),
                      for (final s in skills)
                        Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(s), selected: _filter == s, onSelected: (_) => setState(() => _filter = s))),
                    ]),
                  ),
                const SizedBox(height: 12),
                if (list.isEmpty)
                  SizedBox(
                    height: 420,
                    child: EmptyState(
                      icon: Icons.search_off,
                      title: 'Одоогоор санал алга',
                      subtitle: 'Ур чадвар, хобби, боломжит цагаа нэмэх тусам илүү тохирох хүмүүс олдоно.',
                      action: FilledButton(onPressed: () => context.push('/skills'), child: const Text('Ур чадвар нэмэх')),
                    ),
                  ),
                for (final m in list)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: ProfileCard(m: m, onSkip: () => setState(() => _skipped.add(m.other.id)), onRequest: () => _request(d.me, m)),
                  ),
              ]),
            );
          },
        ),
      );
}

class _RequestSheet extends StatefulWidget {
  final UserProfile me;
  final MatchResult m;
  const _RequestSheet({required this.me, required this.m});
  @override
  State<_RequestSheet> createState() => _RequestSheetState();
}

class _RequestSheetState extends State<_RequestSheet> {
  late String _offer = widget.m.iTeach.isNotEmpty ? widget.m.iTeach.first : widget.me.offers.keys.first;
  late String _want = widget.m.theyTeach.isNotEmpty ? widget.m.theyTeach.first : widget.m.other.offers.keys.first;
  final _msg = TextEditingController();
  bool _busy = false;

  Future<void> _send() async {
    setState(() => _busy = true);
    try {
      await Db.sendRequest(
        to: widget.m.other.id, offered: widget.me.offers[_offer]!, wanted: widget.m.other.offers[_want]!, message: _msg.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) snack(context, 'Илгээж чадсангүй: $e', error: true);
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${widget.m.other.fullName}-д хүсэлт илгээх', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _offer, decoration: const InputDecoration(labelText: 'Би заана'),
            items: [for (final k in widget.me.offers.keys) DropdownMenuItem(value: k, child: Text(k))],
            onChanged: (v) => setState(() => _offer = v!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _want, decoration: const InputDecoration(labelText: 'Би сурна'),
            items: [for (final k in widget.m.other.offers.keys) DropdownMenuItem(value: k, child: Text(k))],
            onChanged: (v) => setState(() => _want = v!),
          ),
          const SizedBox(height: 12),
          TextField(controller: _msg, maxLength: 200, decoration: const InputDecoration(labelText: 'Мессеж (заавал биш)')),
          const SizedBox(height: 8),
          FilledButton(onPressed: _busy ? null : _send, child: const Text('Илгээх')),
        ]),
      );
}
