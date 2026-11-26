import 'package:flutter/material.dart';
import 'matching.dart';
import 'theme.dart';

void snack(BuildContext c, String msg, {bool error = false}) {
  ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(msg), backgroundColor: error ? C.error : C.text));
}

/// Ур чадвар / хоббигийн шошго
class SkillChip extends StatelessWidget {
  final String label;
  const SkillChip(this.label, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: C.primaryTint, borderRadius: BorderRadius.circular(100)),
        child: Text(label, style: const TextStyle(color: C.primary, fontSize: 13, fontWeight: FontWeight.w500)),
      );
}

class Avatar extends StatelessWidget {
  final String initial;
  final double size;
  final Color color;
  const Avatar(this.initial, {super.key, this.size = 48, this.color = C.primary});
  @override
  Widget build(BuildContext context) => Container(
        width: size, height: size, alignment: Alignment.center,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Text(initial, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: size * 0.4)),
      );
}

/// Нийцлийн хувь харуулах хэсэг (Compatibility Score)
class CompatBadge extends StatelessWidget {
  final double score;
  const CompatBadge(this.score, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: C.secondaryTint, borderRadius: BorderRadius.circular(16)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('${score.toInt()}%', style: const TextStyle(color: C.secondaryDark, fontWeight: FontWeight.w700, fontSize: 22)),
          const Text('нийцэл', style: TextStyle(color: C.secondaryDark, fontSize: 12, fontWeight: FontWeight.w500)),
        ]),
      );
}

BoxDecoration cardDeco({bool shadow = false}) => BoxDecoration(
      color: C.surface, borderRadius: BorderRadius.circular(24), border: shadow ? null : Border.all(color: C.border),
      boxShadow: shadow ? const [BoxShadow(color: Color(0x140F172A), blurRadius: 24, offset: Offset(0, 8))] : null,
    );

class ProfileCard extends StatelessWidget {
  final MatchResult m;
  final VoidCallback onSkip, onRequest;
  const ProfileCard({super.key, required this.m, required this.onSkip, required this.onRequest});

  Widget _panel(String title, Set<String> skills) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: C.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: C.muted, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (skills.isEmpty) const Text('—', style: TextStyle(color: C.muted)),
            Wrap(spacing: 6, runSpacing: 6, children: [for (final s in skills) SkillChip(s)]),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final o = m.other;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDeco(shadow: true),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Avatar(o.initial, size: 56),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(o.fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              if (o.subtitle.isNotEmpty) Text(o.subtitle, style: const TextStyle(color: C.muted, fontSize: 13)),
            ]),
          ),
          CompatBadge(m.score),
        ]),
        const SizedBox(height: 16),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _panel('Та заана', m.iTeach),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 30),
            child: CircleAvatar(radius: 16, backgroundColor: C.primary, child: Icon(Icons.swap_horiz, size: 18, color: Colors.white)),
          ),
          _panel('Тэр заана', m.theyTeach),
        ]),
        if (m.reasons.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Яагаад тохирч байна', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          for (final r in m.reasons)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Padding(padding: EdgeInsets.only(top: 6), child: CircleAvatar(radius: 4, backgroundColor: C.secondary)),
                const SizedBox(width: 8),
                Expanded(child: Text(r, style: const TextStyle(color: C.muted, fontSize: 14))),
              ]),
            ),
        ],
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: onSkip, child: const Text('Алгасах'))),
          const SizedBox(width: 12),
          Expanded(child: FilledButton(onPressed: onRequest, child: const Text('Хүсэлт илгээх'))),
        ]),
      ]),
    );
  }
}

/// Хоосон төлөв (Empty State)
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Widget? action;
  const EmptyState({super.key, required this.icon, required this.title, required this.subtitle, this.action});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 112, height: 112,
              decoration: const BoxDecoration(color: C.primaryTint, shape: BoxShape.circle),
              child: Icon(icon, size: 48, color: C.primary),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(color: C.muted), textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ]),
        ),
      );
}

/// Ачаалж байх төлөв (Loading skeleton)
class SkeletonList extends StatelessWidget {
  final int count;
  const SkeletonList({super.key, this.count = 2});
  Widget _bar(double w, double h) => Container(width: w, height: h, decoration: BoxDecoration(color: C.border, borderRadius: BorderRadius.circular(8)));
  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(20),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (var i = 0; i < count; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: cardDeco(),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(width: 56, height: 56, decoration: const BoxDecoration(color: C.border, shape: BoxShape.circle)),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_bar(140, 16), const SizedBox(height: 8), _bar(100, 12)]),
                ]),
                const SizedBox(height: 16),
                Container(height: 90, decoration: BoxDecoration(color: C.border, borderRadius: BorderRadius.circular(16))),
                const SizedBox(height: 12),
                _bar(220, 12),
              ]),
            ),
        ],
      );
}

class ErrorState extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const ErrorState({super.key, required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) => EmptyState(
        icon: Icons.wifi_off, title: 'Алдаа гарлаа', subtitle: '$error',
        action: OutlinedButton(onPressed: onRetry, child: const Text('Дахин оролдох')),
      );
}

class ScreenTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const ScreenTitle(this.text, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Row(children: [
          Expanded(child: Text(text, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700))),
          if (trailing != null) trailing!,
        ]),
      );
}
