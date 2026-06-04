import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../utils/theme.dart';
import 'records_screen.dart';
import 'appointments_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final _screens = const [RecordsScreen(), AppointmentsScreen()];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(_currentIndex == 0 ? 'السجلات الطبية' : 'طلب موعد'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: PopupMenuButton<String>(
              offset: const Offset(0, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              icon: CircleAvatar(
                backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                child: Text(
                  user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'م',
                  style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700),
                ),
              ),
              itemBuilder: (_) => [
                PopupMenuItem(
                  enabled: false,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(user?.name ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    Text(user?.email ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ]),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(value: 'logout', child: Row(children: [
                  Icon(Icons.logout_rounded, color: AppTheme.danger, size: 18),
                  SizedBox(width: 10),
                  Text('تسجيل الخروج', style: TextStyle(color: AppTheme.danger)),
                ])),
              ],
              onSelected: (v) async {
                if (v == 'logout') {
                  await context.read<AuthProvider>().signOut();
                  if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                }
              },
            ),
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          boxShadow: [BoxShadow(color: AppTheme.cardShadow.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              _navItem(0, Icons.folder_outlined, Icons.folder_rounded, 'السجلات'),
              _navItem(1, Icons.calendar_today_outlined, Icons.calendar_today_rounded, 'المواعيد'),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, IconData activeIcon, String label) {
    final isActive = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primary.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(isActive ? activeIcon : icon, color: isActive ? AppTheme.primary : AppTheme.textSecondary, size: 26),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: isActive ? AppTheme.primary : AppTheme.textSecondary, fontSize: 12, fontWeight: isActive ? FontWeight.w700 : FontWeight.w400)),
          ]),
        ),
      ),
    );
  }
}
