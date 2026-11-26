# SkillMate – оюутнуудын ур чадвар солилцох мобайл апп

Технологи: **Flutter (Dart)** + **Supabase (PostgreSQL, Auth, Realtime)**. Дизайн: Figma (SkillMate – UI/UX дизайн).

## Төслийн бүтэц
```
lib/
  main.dart, router.dart, config.dart, theme.dart   # эхлүүлэлт, чиглүүлэлт, Figma-ийн өнгө
  models.dart                                       # өгөгдлийн загварууд
  matching.dart                                     # Нийцлийн алгоритм (40/25/15/10/10)
  data.dart                                         # Supabase-тэй харьцах бүх үйлдэл
  widgets.dart                                      # Profile Card, Compat Badge, Empty/Loading төлөв
  screens/ auth.dart home.dart requests.dart chat.dart profile.dart
supabase/schema.sql                                 # хүснэгт, FK, индекс, RLS, анхны өгөгдөл
test/matching_test.dart                             # алгоритмын unit тест
```

## Ажиллуулах заавар
1. **Flutter SDK** суулгана (https://docs.flutter.dev/get-started/install), `flutter doctor` шалгана.
2. Төслийн хавтсанд платформын файлуудыг үүсгэнэ:
   `flutter create . --project-name skillmate`
   (`test/widget_test.dart` файл үүсвэл устгана, учир нь энэ нь манай аппыг мэдэхгүй.)
   Android дээр `android/app/src/main/AndroidManifest.xml`-д
   `<uses-permission android:name="android.permission.INTERNET"/>` нэмнэ.
3. https://supabase.com дээр төсөл үүсгээд **SQL Editor** дээр `supabase/schema.sql`-ийг бүтнээр нь ажиллуулна.
4. Supabase → **Authentication → Providers → Email**: хөгжүүлэлтийн үед "Confirm email"-ийг унтрааж болно.
   Туршихдаа `.edu.mn` имэйл байхгүй бол `drop trigger on_auth_user_domain on auth.users;` ажиллуулна.
5. Supabase → **Project Settings → API**-аас URL болон anon key-г авч ажиллуулна:
   ```
   flutter pub get
   flutter run --dart-define=SUPABASE_URL=https://xxxx.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ...
   ```
6. Тест: `flutter test`

## Аюулгүй байдлын шийдлүүд
- Нууц үгийг Supabase Auth (bcrypt) hash хийж хадгална; апп нууц үг хадгалахгүй.
- Бүх хүснэгтэд **Row Level Security**: хэрэглэгч зөвхөн өөрийн өгөгдлийг өөрчилнө.
- `profiles.role`, `is_verified`-ийг хэрэглэгч өөрчилж чадахгүй (column-level эрх).
- Бусдын профайлыг `public_profiles` view-ээр л үзнэ: MBTI, үнэт зүйл, сургуулийг эзэмшигч зөвшөөрөөгүй бол нуугдана, блоклосон хэрэглэгч харагдахгүй.
- Мессеж зөвхөн зөвшөөрөгдсөн хүсэлттэй хоёр хэрэглэгчийн хооронд, блоклоогүй үед л бичигдэнэ.
- SQL Injection: Supabase клиент параметрчилсэн query ашигладаг; оролтыг апп дээр бас шалгана.

## MVP-д орсон / ороогүй
Орсон: бүртгэл/нэвтрэлт, имэйл баталгаажуулалт, профайл, ур чадвар CRUD, хобби, боломжит цаг, нийцлийн алгоритм,
хүсэлт илгээх/зөвшөөрөх/татгалзах, бодит цагийн чат, блок, мэдээлэх, нууцлалын тохиргоо.
Орооогүй (дараагийн шат): админ Dashboard, сургалтын цаг товлолт, үнэлгээ/badge, профайл зураг оруулах, push мэдэгдэл.
