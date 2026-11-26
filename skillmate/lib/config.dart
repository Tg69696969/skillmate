/// Supabase төслийн тохиргоо. Ажиллуулахдаа:
/// flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://YOUR-PROJECT.supabase.co');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'YOUR-ANON-KEY');

/// Бүртгүүлэхэд зөвшөөрөх их сургуулийн имэйлийн төгсгөл (өгөгдлийн сан дээр бас шалгана).
const allowedEmailSuffix = '.edu.mn';
