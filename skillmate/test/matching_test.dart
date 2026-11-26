import 'package:flutter_test/flutter_test.dart';
import 'package:skillmate/matching.dart';
import 'package:skillmate/models.dart';

UserProfile p(String id, {Map<String, int> offers = const {}, Map<String, int> wants = const {}, Set<String> hobbies = const {}, String? mbti, String uni = 'ШУТИС', Set<String> slots = const {}}) =>
    UserProfile(id: id, fullName: id, university: uni, offers: offers, wants: wants, hobbies: hobbies, mbti: mbti, slots: slots);

void main() {
  test('жин нийлбэр 1.0', () {
    expect(wSkill + wHobby + wMbti + wValues + wAvail, closeTo(1.0, 1e-9));
  });

  test('Харилцан ур чадвар солилцох хоёр хэрэглэгч өндөр оноо авна', () {
    final a = p('A', offers: {'Guitar': 1, 'Python': 2}, wants: {'Photoshop': 3, 'Chess': 4}, hobbies: {'Кино'}, slots: {'1-evening'});
    final b = p('B', offers: {'Photoshop': 3, 'Chess': 4}, wants: {'Guitar': 1, 'Python': 2}, hobbies: {'Кино'}, slots: {'1-evening'});
    final r = computeMatch(a, b);
    expect(r.iTeach, {'Guitar', 'Python'});
    expect(r.theyTeach, {'Photoshop', 'Chess'});
    expect(r.score, greaterThan(70));
  });

  test('Ур чадвар огт таарахгүй бол оноо бага', () {
    final a = p('A', offers: {'Guitar': 1}, wants: {'Chess': 4});
    final b = p('B', offers: {'Python': 2}, wants: {'Photoshop': 3}, uni: 'ӨӨР');
    expect(computeMatch(a, b).score, lessThan(15));
  });

  test('MBTI бөглөөгүй бол төвийг сахисан 0.5', () {
    expect(mbtiScore(null, 'INTJ'), 0.5);
    expect(mbtiScore('INTJ', 'буруу'), 0.5);
  });

  test('Эрэмбэлэлт: өндөр нийцэлтэй нь эхэнд', () {
    final me = p('me', offers: {'Guitar': 1}, wants: {'Chess': 4});
    final good = p('good', offers: {'Chess': 4}, wants: {'Guitar': 1});
    final bad = p('bad', offers: {'Python': 2}, wants: {'Photoshop': 3});
    expect(rankMatches(me, [bad, good]).first.other.id, 'good');
  });
}
