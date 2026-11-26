/// Өгөгдлийн загварууд (Supabase-ээс ирсэн мэдээллийг хадгална)
class UserProfile {
  final String id;
  final String fullName;
  final String? university, major, bio, mbti;
  final int? year;
  final List<String> values;
  final Map<String, int> offers; // ур чадварын нэр -> skill id (зааж чадах)
  final Map<String, int> wants; // сурахыг хүссэн
  final Map<String, String> levels; // "offer:Guitar" -> intermediate
  final Set<String> hobbies;
  final Set<String> slots; // "1-evening" (1=Даваа ... 7=Ням)

  const UserProfile({
    required this.id,
    required this.fullName,
    this.university,
    this.major,
    this.bio,
    this.mbti,
    this.year,
    this.values = const [],
    this.offers = const {},
    this.wants = const {},
    this.levels = const {},
    this.hobbies = const {},
    this.slots = const {},
  });

  String get initial => fullName.trim().isEmpty ? '?' : String.fromCharCode(fullName.trim().runes.first).toUpperCase();
  String get subtitle => [
        if (university != null && university!.isNotEmpty) university!,
        if (year != null) '$year-р курс',
      ].join(' · ');
}

class RequestItem {
  final int id;
  final String status; // pending | accepted | declined
  final bool incoming;
  final String otherId, otherName;
  final String offered, wanted; // илгээгч заана / илгээгч сурна
  final String? message;
  const RequestItem({
    required this.id,
    required this.status,
    required this.incoming,
    required this.otherId,
    required this.otherName,
    required this.offered,
    required this.wanted,
    this.message,
  });
}

const weekdayNames = ['Да', 'Мя', 'Лх', 'Пү', 'Ба', 'Бя', 'Ня'];
const slotNames = {'morning': 'Өглөө', 'afternoon': 'Өдөр', 'evening': 'Орой'};
const levelNames = {'beginner': 'Анхан', 'intermediate': 'Дунд', 'advanced': 'Ахисан'};
