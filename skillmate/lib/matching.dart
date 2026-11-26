import 'dart:math';
import 'models.dart';

/// Нийцлийн оноонд оролцох үзүүлэлтүүдийн жин (нийт 1.0)
const wSkill = 0.40; // Ур чадварын харилцан нийцэл
const wHobby = 0.25; // Нийтлэг хобби
const wMbti = 0.15; // MBTI (зөвхөн нэмэлт, шинжлэх ухааны хэмжүүр БИШ)
const wValues = 0.10; // Нийтлэг үнэт зүйлс
const wAvail = 0.10; // Цаг ба байршил

class MatchResult {
  final UserProfile other;
  final double score; // 0..100
  final List<String> reasons;
  final Set<String> iTeach; // Би заана, тэр сурахыг хүснэ
  final Set<String> theyTeach; // Тэр заана, би сурахыг хүснэ
  const MatchResult(this.other, this.score, this.reasons, this.iTeach, this.theyTeach);
}

double jaccard<T>(Set<T> a, Set<T> b) {
  final u = a.union(b);
  return u.isEmpty ? 0 : a.intersection(b).length / u.length;
}

final _mbtiRe = RegExp(r'^[EI][NS][TF][JP]$');

/// MBTI-ийн энгийн эвристик нийцэл. Аль нэг нь бөглөөгүй бол төвийг сахисан 0.5.
double mbtiScore(String? a, String? b) {
  if (a == null || b == null || !_mbtiRe.hasMatch(a) || !_mbtiRe.hasMatch(b)) return 0.5;
  var s = 0.0;
  if (a[1] == b[1]) s += 0.4; // ижил мэдрэхүйн хэв маяг (N/S)
  if (a[2] == b[2]) s += 0.2; // шийдвэр гаргах хэв маяг (T/F)
  if (a[0] != b[0]) s += 0.2; // I/E нөхөн дэмжинэ
  if (a[3] == b[3]) s += 0.2; // J/P
  return s;
}

String slotLabel(String key) {
  final p = key.split('-');
  return '${weekdayNames[int.parse(p[0]) - 1]} ${slotNames[p[1]]?.toLowerCase()}';
}

/// Хоёр хэрэглэгчийн нийцлийг жинлэсэн оноогоор тооцно.
MatchResult computeMatch(UserProfile me, UserProfile o) {
  final reasons = <String>[];

  // 1) Ур чадварын харилцан нийцэл (40%)
  final iTeach = me.offers.keys.toSet().intersection(o.wants.keys.toSet());
  final theyTeach = o.offers.keys.toSet().intersection(me.wants.keys.toSet());
  final sa = o.wants.isEmpty ? 0.0 : iTeach.length / o.wants.length;
  final sb = me.wants.isEmpty ? 0.0 : theyTeach.length / me.wants.length;
  final skill = (sa + sb) / 2;
  if (iTeach.isNotEmpty && theyTeach.isNotEmpty) {
    reasons.add('Харилцан солилцох ${iTeach.length + theyTeach.length} ур чадвар таарна');
  } else if (iTeach.isNotEmpty) {
    reasons.add('Та заах: ${iTeach.join(', ')}');
  } else if (theyTeach.isNotEmpty) {
    reasons.add('Тэр заах: ${theyTeach.join(', ')}');
  }

  // 2) Нийтлэг хобби (25%)
  final hobby = jaccard(me.hobbies, o.hobbies);
  final commonH = me.hobbies.intersection(o.hobbies);
  if (commonH.isNotEmpty) reasons.add('Нийтлэг хобби: ${commonH.join(', ')}');

  // 3) MBTI (15%)
  final mbti = mbtiScore(me.mbti, o.mbti);

  // 4) Үнэт зүйл (10%) – хоёулаа нээлттэй болгосон үед л өгөгдөл ирнэ
  Set<String> norm(List<String> l) => l.map((e) => e.trim().toLowerCase()).where((e) => e.isNotEmpty).toSet();
  final values = jaccard(norm(me.values), norm(o.values));

  // 5) Цаг ба байршил (10%)
  final common = me.slots.intersection(o.slots);
  final sameUni = me.university != null && me.university == o.university;
  final avail = 0.7 * min(1.0, common.length / 3) + 0.3 * (sameUni ? 1 : 0);
  if (sameUni) reasons.add('Ижил сургууль');
  if (common.isNotEmpty) reasons.add('Давхцсан цаг: ${common.length} (жишээ нь ${slotLabel(common.first)})');

  final total = wSkill * skill + wHobby * hobby + wMbti * mbti + wValues * values + wAvail * avail;
  return MatchResult(o, (total * 100).roundToDouble(), reasons, iTeach, theyTeach);
}

/// Нэр дэвшигчдийг нийцлээр нь буурахаар эрэмбэлнэ.
List<MatchResult> rankMatches(UserProfile me, List<UserProfile> candidates) {
  final r = candidates.map((c) => computeMatch(me, c)).toList()..sort((a, b) => b.score.compareTo(a.score));
  return r;
}
