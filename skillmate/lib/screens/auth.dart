import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config.dart';
import '../theme.dart';
import '../widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashState();
}

class _SplashState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) context.go('/home'); // нэвтрээгүй бол router /login руу шилжүүлнэ
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: C.primary,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 96, height: 96, alignment: Alignment.center,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Text('S', style: TextStyle(color: C.primary, fontSize: 44, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 16),
            const Text('SkillMate', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Зааж өг. Суралц. Холбогд.', style: TextStyle(color: C.primaryTint, fontSize: 16)),
          ]),
        ),
      );
}

String authError(Object e) {
  final m = e is AuthException ? e.message : e.toString();
  if (m.contains('Email not confirmed')) return 'Имэйлээ баталгаажуулаагүй байна. Имэйл дэх холбоос дээр дарна уу.';
  if (m.contains('Invalid login credentials')) return 'Имэйл эсвэл нууц үг буруу байна.';
  if (m.contains('already registered')) return 'Энэ имэйл бүртгэлтэй байна.';
  if (m.contains('.edu.mn')) return 'Зөвхөн их сургуулийн (.edu.mn) имэйлээр бүртгүүлнэ.';
  return m;
}

class _AuthScaffold extends StatelessWidget {
  final String title, subtitle;
  final List<Widget> children;
  const _AuthScaffold({required this.title, required this.subtitle, required this.children});
  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: ListView(padding: const EdgeInsets.fromLTRB(24, 32, 24, 24), children: [
            const Align(alignment: Alignment.centerLeft, child: Avatar('S', size: 48)),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(color: C.muted, fontSize: 15)),
            const SizedBox(height: 24),
            ...children,
          ]),
        ),
      );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginState();
}

class _LoginState extends State<LoginScreen> {
  final _key = GlobalKey<FormState>();
  final _email = TextEditingController(), _pass = TextEditingController();
  bool _busy = false;

  Future<void> _login() async {
    if (!_key.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(email: _email.text.trim(), password: _pass.text);
    } catch (e) {
      if (mounted) snack(context, authError(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    final email = _email.text.trim();
    if (!email.contains('@')) return snack(context, 'Эхлээд имэйлээ бичнэ үү', error: true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (mounted) snack(context, 'Нууц үг сэргээх холбоос илгээлээ');
    } catch (e) {
      if (mounted) snack(context, authError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) => _AuthScaffold(
        title: 'Тавтай морил',
        subtitle: 'Их сургуулийн имэйлээрээ нэвтэрнэ үү',
        children: [
          Form(
            key: _key,
            child: Column(children: [
              TextFormField(
                controller: _email, keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Имэйл', hintText: 'name@university.edu.mn'),
                validator: (v) => (v == null || !v.contains('@')) ? 'Имэйл буруу байна' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pass, obscureText: true,
                decoration: const InputDecoration(labelText: 'Нууц үг'),
                validator: (v) => (v == null || v.isEmpty) ? 'Нууц үгээ оруулна уу' : null,
              ),
            ]),
          ),
          Align(alignment: Alignment.centerLeft, child: TextButton(onPressed: _reset, child: const Text('Нууц үгээ мартсан уу?'))),
          const SizedBox(height: 8),
          FilledButton(onPressed: _busy ? null : _login, child: _busy ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Нэвтрэх')),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('Бүртгэлгүй юу?', style: TextStyle(color: C.muted)),
            TextButton(onPressed: () => context.go('/register'), child: const Text('Бүртгүүлэх')),
          ]),
        ],
      );
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterState();
}

class _RegisterState extends State<RegisterScreen> {
  final _key = GlobalKey<FormState>();
  final _name = TextEditingController(), _email = TextEditingController(), _pass = TextEditingController();
  bool _busy = false;

  Future<void> _register() async {
    if (!_key.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await Supabase.instance.client.auth.signUp(
        email: _email.text.trim(), password: _pass.text, data: {'full_name': _name.text.trim()},
      );
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Имэйлээ баталгаажуулна уу'),
          content: Text('${_email.text.trim()} хаяг руу илгээсэн холбоос дээр дарж бүртгэлээ баталгаажуулсны дараа нэвтэрнэ үү.'),
          actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Ойлголоо'))],
        ),
      );
      if (mounted) context.go('/login');
    } catch (e) {
      if (mounted) snack(context, authError(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _AuthScaffold(
        title: 'Бүртгүүлэх',
        subtitle: 'Ур чадвараа солилцох аяллаа эхлүүл',
        children: [
          Form(
            key: _key,
            child: Column(children: [
              TextFormField(
                controller: _name, textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Нэр'),
                validator: (v) => (v == null || v.trim().length < 2) ? 'Нэрээ оруулна уу' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _email, keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Их сургуулийн имэйл', hintText: 'name@university.edu.mn'),
                validator: (v) => (v == null || !v.trim().toLowerCase().endsWith(allowedEmailSuffix)) ? 'Зөвхөн $allowedEmailSuffix имэйл зөвшөөрнө' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pass, obscureText: true,
                decoration: const InputDecoration(labelText: 'Нууц үг', hintText: 'Дор хаяж 8 тэмдэгт'),
                validator: (v) => (v == null || v.length < 8) ? 'Дор хаяж 8 тэмдэгт байна' : null,
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: C.secondaryTint, borderRadius: BorderRadius.circular(12)),
            child: const Text('Баталгаажуулах холбоос таны сургуулийн имэйлээр ирнэ.',
                style: TextStyle(color: C.secondaryDark, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _busy ? null : _register, child: _busy ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Бүртгүүлэх')),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('Бүртгэлтэй юу?', style: TextStyle(color: C.muted)),
            TextButton(onPressed: () => context.go('/login'), child: const Text('Нэвтрэх')),
          ]),
        ],
      );
}
