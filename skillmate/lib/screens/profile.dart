import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

// ======================= Миний профайл =======================
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileState();
}

class _ProfileState extends State<ProfileScreen> {
  late Future<UserProfile> _f = Db.me();

  Future<void> _go(String path) async {
    await context.push(path);
    if (mounted) setState(() => _f = Db.me());
  }

  Widget _section(String title, Iterable<String> items) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          items.isEmpty
              ? const Text('Хараахан нэмээгүй', style: TextStyle(color: C.muted))
              : Wrap(spacing: 8, runSpacing: 8, children: [for (final i in items) SkillChip(i)]),
        ]),
      );

  Widget _stat(String n, String l) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: cardDeco(),
          child: Column(children: [
            Text(n, style: const TextStyle(color: C.primary, fontSize: 20, fontWeight: FontWeight.w700)),
            Text(l, style: const TextStyle(color: C.muted, fontSize: 12, fontWeight: FontWeight.w500)),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) => SafeArea(
        child: FutureBuilder<UserProfile>(
          future: _f,
          builder: (c, s) {
            if (s.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (s.hasError) return ErrorState(error: s.error!, onRetry: () => setState(() => _f = Db.me()));
            final p = s.data!;
            return ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 24), children: [
              const ScreenTitle('Профайл'),
              Center(child: Avatar(p.initial, size: 88)),
              const SizedBox(height: 8),
              Center(child: Text(p.fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700))),
              Center(child: Text([p.major, p.subtitle].where((e) => e != null && e.isNotEmpty).join(' · '), style: const TextStyle(color: C.muted, fontSize: 13))),
              if (p.bio != null && p.bio!.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(p.bio!, textAlign: TextAlign.center)),
              const SizedBox(height: 16),
              Row(children: [_stat('${p.offers.length}', 'Заана'), const SizedBox(width: 10), _stat('${p.wants.length}', 'Сурна'), const SizedBox(width: 10), _stat('${p.hobbies.length}', 'Хобби')]),
              const SizedBox(height: 20),
              _section('Заах ур чадвар', p.offers.keys),
              _section('Сурахыг хүссэн', p.wants.keys),
              _section('Хобби', p.hobbies),
              OutlinedButton(onPressed: () => _go('/profile/edit'), child: const Text('Профайл засах')),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: () => _go('/skills'), child: const Text('Миний ур чадвар')),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: () => _go('/settings'), child: const Text('Тохиргоо')),
            ]);
          },
        ),
      );
}

// ======================= Профайл засах =======================
class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});
  @override
  State<ProfileEditScreen> createState() => _ProfileEditState();
}

class _ProfileEditState extends State<ProfileEditScreen> {
  final _name = TextEditingController(), _uni = TextEditingController(), _major = TextEditingController();
  final _year = TextEditingController(), _bio = TextEditingController(), _values = TextEditingController();
  String? _mbti;
  Set<int> _hobbyIds = {};
  Set<String> _slots = {};
  List<Map<String, dynamic>> _hobbies = [];
  bool _loading = true, _saving = false;

  static const _types = ['INTJ','INTP','ENTJ','ENTP','INFJ','INFP','ENFJ','ENFP','ISTJ','ISFJ','ESTJ','ESFJ','ISTP','ISFP','ESTP','ESFP'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final me = await Db.me();
      final row = await Db.myRow();
      _hobbies = await Db.catalogHobbies();
      _hobbyIds = await Db.myHobbyIds();
      _name.text = me.fullName;
      _uni.text = row['university'] ?? '';
      _major.text = me.major ?? '';
      _year.text = me.year?.toString() ?? '';
      _bio.text = me.bio ?? '';
      _values.text = me.values.join(', ');
      _mbti = me.mbti;
      _slots = {...me.slots};
    } catch (e) {
      if (mounted) snack(context, 'Ачаалж чадсангүй: $e', error: true);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (_name.text.trim().length < 2) return snack(context, 'Нэрээ оруулна уу', error: true);
    final year = _year.text.trim().isEmpty ? null : int.tryParse(_year.text.trim());
    if (year != null && (year < 1 || year > 8)) return snack(context, 'Курс 1-8 хооронд байна', error: true);
    setState(() => _saving = true);
    try {
      await Db.updateProfile({
        'full_name': _name.text.trim(),
        'university': _uni.text.trim().isEmpty ? null : _uni.text.trim(),
        'major': _major.text.trim().isEmpty ? null : _major.text.trim(),
        'year': year,
        'bio': _bio.text.trim().isEmpty ? null : _bio.text.trim(),
        'mbti': _mbti,
        'values_list': _values.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      });
      await Db.setHobbies(_hobbyIds);
      await Db.setAvailability(_slots);
      if (mounted) {
        snack(context, 'Хадгаллаа');
        context.pop();
      }
    } catch (e) {
      if (mounted) snack(context, 'Хадгалж чадсангүй: $e', error: true);
      setState(() => _saving = false);
    }
  }

  Widget _label(String t) => Padding(padding: const EdgeInsets.only(top: 20, bottom: 8), child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600)));

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Профайл засах'), backgroundColor: C.bg, surfaceTintColor: Colors.transparent),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 32), children: [
                const SizedBox(height: 8),
                TextField(controller: _name, decoration: const InputDecoration(labelText: 'Нэр')),
                const SizedBox(height: 12),
                TextField(controller: _uni, decoration: const InputDecoration(labelText: 'Сургууль')),
                const SizedBox(height: 12),
                TextField(controller: _major, decoration: const InputDecoration(labelText: 'Мэргэжил')),
                const SizedBox(height: 12),
                TextField(controller: _year, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Курс (1-8)')),
                const SizedBox(height: 12),
                TextField(controller: _bio, maxLines: 3, maxLength: 200, decoration: const InputDecoration(labelText: 'Өөрийн тухай')),
                _label('Хобби, сонирхол'),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final h in _hobbies)
                    FilterChip(
                      label: Text(h['name']), selected: _hobbyIds.contains(h['id']),
                      onSelected: (v) => setState(() => v ? _hobbyIds.add(h['id']) : _hobbyIds.remove(h['id'])),
                    ),
                ]),
                _label('Боломжит цаг'),
                for (var d = 1; d <= 7; d++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(children: [
                      SizedBox(width: 32, child: Text(weekdayNames[d - 1], style: const TextStyle(color: C.muted, fontWeight: FontWeight.w600))),
                      for (final s in slotNames.entries)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Text(s.value, style: const TextStyle(fontSize: 12)), selected: _slots.contains('$d-${s.key}'),
                            visualDensity: VisualDensity.compact,
                            onSelected: (v) => setState(() => v ? _slots.add('$d-${s.key}') : _slots.remove('$d-${s.key}')),
                          ),
                        ),
                    ]),
                  ),
                _label('MBTI (заавал биш)'),
                DropdownButtonFormField<String?>(
                  value: _mbti, decoration: const InputDecoration(hintText: 'Сонгоогүй'),
                  items: [const DropdownMenuItem<String?>(value: null, child: Text('Сонгоогүй')), for (final t in _types) DropdownMenuItem<String?>(value: t, child: Text(t))],
                  onChanged: (v) => setState(() => _mbti = v),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text('MBTI нь шинжлэх ухаанаар батлагдсан нийцлийн хэмжүүр биш, зөвхөн нэмэлт сонирхол.', style: TextStyle(color: C.muted, fontSize: 12)),
                ),
                _label('Үнэт зүйлс (заавал биш, таслалаар тусгаарла)'),
                TextField(controller: _values, decoration: const InputDecoration(hintText: 'үнэнч байдал, өсөлт, найрсаг')),
                const SizedBox(height: 24),
                FilledButton(onPressed: _saving ? null : _save, child: const Text('Хадгалах')),
              ]),
      );
}

// ======================= Миний ур чадвар (CRUD) =======================
class SkillsScreen extends StatefulWidget {
  const SkillsScreen({super.key});
  @override
  State<SkillsScreen> createState() => _SkillsState();
}

class _SkillsState extends State<SkillsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this)..addListener(() => setState(() {}));
  int _rev = 0; // жагсаалтыг дахин ачаалах тоолуур

  String get _type => _tab.index == 0 ? 'offer' : 'want';

  Future<void> _add() async {
    final done = await showModalBottomSheet<bool>(
      context: context, isScrollControlled: true, showDragHandle: true,
      builder: (_) => _AddSkillSheet(type: _type),
    );
    if (done == true) setState(() => _rev++);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Миний ур чадвар'), backgroundColor: C.bg, surfaceTintColor: Colors.transparent),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _add, backgroundColor: C.primary, foregroundColor: Colors.white,
          icon: const Icon(Icons.add), label: const Text('Ур чадвар нэмэх'),
        ),
        body: Column(children: [
          Container(
            margin: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: C.border, borderRadius: BorderRadius.circular(14)),
            child: TabBar(
              controller: _tab, dividerColor: Colors.transparent, indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
              labelColor: C.text, unselectedLabelColor: C.muted, labelStyle: const TextStyle(fontWeight: FontWeight.w600),
              tabs: const [Tab(text: 'Заана', height: 36), Tab(text: 'Сурна', height: 36)],
            ),
          ),
          Expanded(
            child: TabBarView(controller: _tab, children: [
              _SkillList(key: ValueKey('offer$_rev'), type: 'offer', onChanged: () => setState(() => _rev++)),
              _SkillList(key: ValueKey('want$_rev'), type: 'want', onChanged: () => setState(() => _rev++)),
            ]),
          ),
        ]),
      );
}

class _SkillList extends StatelessWidget {
  final String type;
  final VoidCallback onChanged;
  const _SkillList({super.key, required this.type, required this.onChanged});

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(
        future: Db.mySkills(type),
        builder: (c, s) {
          if (s.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (s.hasError) return ErrorState(error: s.error!, onRetry: onChanged);
          final rows = s.data!;
          if (rows.isEmpty) {
            return EmptyState(
              icon: Icons.lightbulb_outline,
              title: type == 'offer' ? 'Заах ур чадвар нэмээгүй байна' : 'Сурахыг хүссэн ур чадвар нэмээгүй байна',
              subtitle: 'Доорх товчоор нэмээрэй.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final r = rows[i];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: cardDeco(),
                child: Row(children: [
                  Expanded(child: Text(r['skills']['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                  DropdownButton<String>(
                    value: r['level'], underline: const SizedBox(),
                    items: [for (final l in levelNames.entries) DropdownMenuItem(value: l.key, child: Text(l.value))],
                    onChanged: (v) async {
                      await Db.setSkillLevel(r['id'], v!);
                      onChanged();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: C.error),
                    onPressed: () async {
                      await Db.deleteUserSkill(r['id']);
                      onChanged();
                    },
                  ),
                ]),
              );
            },
          );
        },
      );
}

class _AddSkillSheet extends StatefulWidget {
  final String type;
  const _AddSkillSheet({required this.type});
  @override
  State<_AddSkillSheet> createState() => _AddSkillSheetState();
}

class _AddSkillSheetState extends State<_AddSkillSheet> {
  final _q = TextEditingController();
  String _level = 'beginner';
  List<Map<String, dynamic>> _all = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    Db.catalogSkills().then((v) => mounted ? setState(() => _all = v) : null);
  }

  Future<void> _pick(int id) async {
    setState(() => _busy = true);
    try {
      await Db.addUserSkill(id, widget.type, _level);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) snack(context, 'Алдаа: $e', error: true);
      setState(() => _busy = false);
    }
  }

  Future<void> _create() async {
    setState(() => _busy = true);
    try {
      await _pick(await Db.createSkill(_q.text));
    } catch (e) {
      if (mounted) snack(context, 'Алдаа: $e', error: true);
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _q.text.trim().toLowerCase();
    final list = _all.where((s) => q.isEmpty || (s['name'] as String).toLowerCase().contains(q)).toList();
    final exact = _all.any((s) => (s['name'] as String).toLowerCase() == q);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SizedBox(
        height: 440,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.type == 'offer' ? 'Заах ур чадвар нэмэх' : 'Сурахыг хүссэн ур чадвар нэмэх', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          TextField(controller: _q, onChanged: (_) => setState(() {}), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Хайх эсвэл шинээр бичих')),
          const SizedBox(height: 8),
          Row(children: [
            const Text('Түвшин:', style: TextStyle(color: C.muted)),
            const SizedBox(width: 8),
            for (final l in levelNames.entries)
              Padding(padding: const EdgeInsets.only(right: 6), child: ChoiceChip(label: Text(l.value), selected: _level == l.key, onSelected: (_) => setState(() => _level = l.key))),
          ]),
          Expanded(
            child: ListView(children: [
              for (final s in list) ListTile(contentPadding: EdgeInsets.zero, title: Text(s['name']), onTap: _busy ? null : () => _pick(s['id'])),
              if (q.isNotEmpty && !exact)
                ListTile(
                  contentPadding: EdgeInsets.zero, leading: const Icon(Icons.add_circle_outline, color: C.primary),
                  title: Text('“${_q.text.trim()}” шинээр нэмэх'), onTap: _busy ? null : _create,
                ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ======================= Тохиргоо =======================
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsState();
}

class _SettingsState extends State<SettingsScreen> {
  late Future<Map<String, dynamic>> _f = Db.myRow();
  late Future<List<Map<String, dynamic>>> _blocked = Db.blocked();

  Future<void> _set(String key, bool v) async {
    try {
      await Db.updateProfile({key: v});
      setState(() => _f = Db.myRow());
    } catch (e) {
      if (mounted) snack(context, 'Алдаа: $e', error: true);
    }
  }

  Widget _switch(Map<String, dynamic> row, String key, String label) => SwitchListTile(
        contentPadding: EdgeInsets.zero, title: Text(label), value: row[key] == true,
        activeColor: C.primary, onChanged: (v) => _set(key, v),
      );

  Widget _card(List<Widget> children) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), decoration: cardDeco(), child: Column(children: children));

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Тохиргоо'), backgroundColor: C.bg, surfaceTintColor: Colors.transparent),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _f,
          builder: (c, s) {
            if (!s.hasData) return const Center(child: CircularProgressIndicator());
            final row = s.data!;
            return ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 32), children: [
              const Text('Нууцлал', style: TextStyle(color: C.muted, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _card([
                _switch(row, 'mbti_public', 'MBTI харуулах'),
                _switch(row, 'values_public', 'Үнэт зүйл харуулах'),
                _switch(row, 'show_university', 'Сургуулиа харуулах'),
              ]),
              const Padding(
                padding: EdgeInsets.only(top: 8, bottom: 20),
                child: Text('Эмзэг мэдээлэл анхдагчаар бусдад харагдахгүй.', style: TextStyle(color: C.muted, fontSize: 13)),
              ),
              const Text('Блоклосон хэрэглэгчид', style: TextStyle(color: C.muted, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _blocked,
                builder: (c, b) {
                  final list = b.data ?? [];
                  if (list.isEmpty) return _card([const ListTile(contentPadding: EdgeInsets.zero, title: Text('Блоклосон хэрэглэгч байхгүй', style: TextStyle(color: C.muted)))]);
                  return _card([
                    for (final x in list)
                      ListTile(
                        contentPadding: EdgeInsets.zero, title: Text(x['blocked_name'] == '' ? 'Хэрэглэгч' : x['blocked_name']),
                        trailing: TextButton(
                          onPressed: () async {
                            await Db.unblock(x['blocked_id']);
                            setState(() => _blocked = Db.blocked());
                          },
                          child: const Text('Блок болих'),
                        ),
                      ),
                  ]);
                },
              ),
              const SizedBox(height: 20),
              const Text('Аюулгүй байдал', style: TextStyle(color: C.muted, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _card([
                ListTile(
                  contentPadding: EdgeInsets.zero, title: const Text('Нууц үг солих'), trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final email = sb.auth.currentUser?.email;
                    if (email == null) return;
                    try {
                      await sb.auth.resetPasswordForEmail(email);
                      if (mounted) snack(context, 'Нууц үг солих холбоос имэйлээр илгээлээ');
                    } catch (e) {
                      if (mounted) snack(context, 'Алдаа: $e', error: true);
                    }
                  },
                ),
              ]),
              const SizedBox(height: 24),
              OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: C.error),
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                },
                child: const Text('Гарах'),
              ),
            ]);
          },
        ),
      );
}
