import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth.dart';
import 'screens/chat.dart';
import 'screens/home.dart';
import 'screens/profile.dart';
import 'screens/requests.dart';

/// Нэвтрэлтийн төлөв өөрчлөгдөхөд router-ийг дахин шалгуулна.
class _AuthRefresh extends ChangeNotifier {
  late final StreamSubscription _sub;
  _AuthRefresh() {
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((_) => notifyListeners());
  }
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final appRouter = GoRouter(
  initialLocation: '/splash',
  refreshListenable: _AuthRefresh(),
  redirect: (context, state) {
    final loggedIn = Supabase.instance.client.auth.currentSession != null;
    final loc = state.matchedLocation;
    if (loc == '/splash') return null;
    final isAuth = loc == '/login' || loc == '/register';
    if (!loggedIn && !isAuth) return '/login';
    if (loggedIn && isAuth) return '/home';
    return null;
  },
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
    ShellRoute(
      builder: (_, state, child) => MainShell(location: state.matchedLocation, child: child),
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/requests', builder: (_, __) => const RequestsScreen()),
        GoRoute(path: '/chats', builder: (_, __) => const ChatListScreen()),
        GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      ],
    ),
    GoRoute(
      path: '/chat/:id',
      builder: (_, s) => ChatScreen(
        requestId: int.parse(s.pathParameters['id']!),
        otherId: s.uri.queryParameters['other'] ?? '',
        otherName: s.uri.queryParameters['name'] ?? '',
      ),
    ),
    GoRoute(path: '/profile/edit', builder: (_, __) => const ProfileEditScreen()),
    GoRoute(path: '/skills', builder: (_, __) => const SkillsScreen()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
  ],
);

class MainShell extends StatelessWidget {
  final String location;
  final Widget child;
  const MainShell({super.key, required this.location, required this.child});

  static const _paths = ['/home', '/requests', '/chats', '/profile'];

  @override
  Widget build(BuildContext context) {
    final idx = _paths.indexWhere((p) => location.startsWith(p)).clamp(0, 3);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) => context.go(_paths[i]),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Нүүр'),
          NavigationDestination(icon: Icon(Icons.swap_horiz), label: 'Хүсэлт'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Чат'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Профайл'),
        ],
      ),
    );
  }
}
