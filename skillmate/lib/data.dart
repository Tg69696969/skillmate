import 'package:supabase_flutter/supabase_flutter.dart';
import 'models.dart';

SupabaseClient get sb => Supabase.instance.client;
String get myId => sb.auth.currentUser!.id;

const _cols = 'id,full_name,university,major,year,bio,mbti,values_list';

/// Supabase-тэй харьцах бүх үйлдэл нэг газар төвлөрсөн.
class Db {
  // ---------- Профайл ----------
  static Future<Map<String, dynamic>> myRow() async =>
      await sb.from('profiles').select().eq('id', myId).single();

  static Future<UserProfile> me() async {
    final row = await sb.from('profiles').select(_cols).eq('id', myId).single();
    return (await _assemble([row])).first;
  }

  static Future<void> updateProfile(Map<String, dynamic> data) async =>
      await sb.from('profiles').update(data).eq('id', myId);

  /// Нэр дэвшигчид: өөрөөс бусад, блоклоогүй, хүсэлт өмнө нь солилцоогүй хүмүүс.
  static Future<List<UserProfile>> candidates() async {
    final rows = await sb.from('public_profiles').select(_cols).neq('id', myId).limit(200);
    final reqs = await sb.from('requests').select('sender_id,receiver_id').or('sender_id.eq.$myId,receiver_id.eq.$myId');
    final seen = <String>{for (final r in reqs) r['sender_id'] == myId ? r['receiver_id'] as String : r['sender_id'] as String};
    return _assemble(rows.where((r) => !seen.contains(r['id'])).toList());
  }

  static Future<List<UserProfile>> _assemble(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return [];
    final ids = rows.map((r) => r['id'] as String).toList();
    final us = await sb.from('user_skills').select('user_id,type,level,skill_id,skills(name)').inFilter('user_id', ids);
    final uh = await sb.from('user_hobbies').select('user_id,hobbies(name)').inFilter('user_id', ids);
    final av = await sb.from('availability').select('user_id,weekday,slot').inFilter('user_id', ids);
    return rows.map((r) {
      final id = r['id'] as String;
      final offers = <String, int>{}, wants = <String, int>{}, levels = <String, String>{};
      for (final s in us.where((s) => s['user_id'] == id)) {
        final name = s['skills']['name'] as String;
        (s['type'] == 'offer' ? offers : wants)[name] = s['skill_id'] as int;
        levels['${s['type']}:$name'] = s['level'] as String;
      }
      return UserProfile(
        id: id,
        fullName: r['full_name'] ?? '',
        university: r['university'],
        major: r['major'],
        bio: r['bio'],
        mbti: r['mbti'],
        year: r['year'],
        values: List<String>.from(r['values_list'] ?? []),
        offers: offers, wants: wants, levels: levels,
        hobbies: {for (final h in uh.where((h) => h['user_id'] == id)) h['hobbies']['name'] as String},
        slots: {for (final a in av.where((a) => a['user_id'] == id)) '${a['weekday']}-${a['slot']}'},
      );
    }).toList();
  }

  // ---------- Ур чадвар ----------
  static Future<List<Map<String, dynamic>>> catalogSkills() async =>
      await sb.from('skills').select('id,name').order('name');

  static Future<int> createSkill(String name) async {
    final r = await sb.from('skills').upsert({'name': name.trim()}, onConflict: 'name').select('id').single();
    return r['id'] as int;
  }

  static Future<List<Map<String, dynamic>>> mySkills(String type) async =>
      await sb.from('user_skills').select('id,level,skills(name)').eq('user_id', myId).eq('type', type).order('id');

  static Future<void> addUserSkill(int skillId, String type, String level) async =>
      await sb.from('user_skills').upsert({'user_id': myId, 'skill_id': skillId, 'type': type, 'level': level},
          onConflict: 'user_id,skill_id,type');

  static Future<void> setSkillLevel(int id, String level) async =>
      await sb.from('user_skills').update({'level': level}).eq('id', id);

  static Future<void> deleteUserSkill(int id) async => await sb.from('user_skills').delete().eq('id', id);

  // ---------- Хобби, цаг ----------
  static Future<List<Map<String, dynamic>>> catalogHobbies() async =>
      await sb.from('hobbies').select('id,name').order('name');

  static Future<Set<int>> myHobbyIds() async {
    final r = await sb.from('user_hobbies').select('hobby_id').eq('user_id', myId);
    return {for (final x in r) x['hobby_id'] as int};
  }

  static Future<void> setHobbies(Set<int> ids) async {
    await sb.from('user_hobbies').delete().eq('user_id', myId);
    if (ids.isNotEmpty) await sb.from('user_hobbies').insert([for (final h in ids) {'user_id': myId, 'hobby_id': h}]);
  }

  static Future<void> setAvailability(Set<String> slots) async {
    await sb.from('availability').delete().eq('user_id', myId);
    if (slots.isNotEmpty) {
      await sb.from('availability').insert([
        for (final s in slots) {'user_id': myId, 'weekday': int.parse(s.split('-')[0]), 'slot': s.split('-')[1]}
      ]);
    }
  }

  // ---------- Хүсэлт ----------
  static Future<void> sendRequest({required String to, required int offered, required int wanted, String? message}) async =>
      await sb.from('requests').insert({
        'sender_id': myId, 'receiver_id': to, 'offered_skill_id': offered, 'wanted_skill_id': wanted,
        if (message != null && message.trim().isNotEmpty) 'message': message.trim(),
      });

  static Future<void> respond(int id, String status) async =>
      await sb.from('requests').update({'status': status}).eq('id', id);

  /// [filter]: 'incoming' | 'outgoing' | 'accepted'
  static Future<List<RequestItem>> requests(String filter) async {
    var q = sb.from('requests').select(
        'id,status,message,sender_id,receiver_id,offered:skills!requests_offered_skill_id_fkey(name),wanted:skills!requests_wanted_skill_id_fkey(name)');
    final List<Map<String, dynamic>> rows;
    if (filter == 'incoming') {
      rows = await q.eq('receiver_id', myId).order('created_at', ascending: false);
    } else if (filter == 'outgoing') {
      rows = await q.eq('sender_id', myId).order('created_at', ascending: false);
    } else {
      rows = await q.eq('status', 'accepted').or('sender_id.eq.$myId,receiver_id.eq.$myId').order('created_at', ascending: false);
    }
    final otherIds = rows.map((r) => (r['sender_id'] == myId ? r['receiver_id'] : r['sender_id']) as String).toSet().toList();
    final names = <String, String>{};
    if (otherIds.isNotEmpty) {
      final ps = await sb.from('public_profiles').select('id,full_name').inFilter('id', otherIds);
      for (final p in ps) {
        names[p['id']] = p['full_name'];
      }
    }
    return rows.map((r) {
      final incoming = r['receiver_id'] == myId;
      final other = (incoming ? r['sender_id'] : r['receiver_id']) as String;
      return RequestItem(
        id: r['id'], status: r['status'], incoming: incoming, otherId: other,
        otherName: names[other] ?? 'Хэрэглэгч',
        offered: r['offered']['name'], wanted: r['wanted']['name'], message: r['message'],
      );
    }).toList();
  }

  // ---------- Чат ----------
  static Stream<List<Map<String, dynamic>>> messages(int requestId) =>
      sb.from('messages').stream(primaryKey: ['id']).eq('request_id', requestId).order('created_at', ascending: true);

  static Future<void> sendMessage(int requestId, String text) async =>
      await sb.from('messages').insert({'request_id': requestId, 'sender_id': myId, 'content': text.trim()});

  // ---------- Блок, мэдээлэх ----------
  static Future<void> block(String id, String name) async =>
      await sb.from('blocks').upsert({'blocker_id': myId, 'blocked_id': id, 'blocked_name': name});

  static Future<void> unblock(String id) async =>
      await sb.from('blocks').delete().eq('blocker_id', myId).eq('blocked_id', id);

  static Future<List<Map<String, dynamic>>> blocked() async =>
      await sb.from('blocks').select('blocked_id,blocked_name').eq('blocker_id', myId);

  static Future<void> report(String id, String reason) async =>
      await sb.from('reports').insert({'reporter_id': myId, 'reported_id': id, 'reason': reason});
}
