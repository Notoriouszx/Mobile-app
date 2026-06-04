import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../utils/theme.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePass = true;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    Future.delayed(const Duration(milliseconds: 100), () => _fadeCtrl.forward());
  }

  @override
  void dispose() { _fadeCtrl.dispose(); _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.signIn(_emailCtrl.text.trim(), _passCtrl.text);
    if (success && mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),

                  // Logo
                  Center(
                    child: Container(
                      width: 90, height: 90,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 10))],
                      ),
                      child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 46),
                    ),
                  ),

                  const SizedBox(height: 32),
                  const Text('مرحباً بك', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppTheme.textPrimary), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  const Text('سجّل دخولك للوصول إلى ملفاتك الطبية', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14), textAlign: TextAlign.center),
                  const SizedBox(height: 48),

                  // Email
                  const Align(alignment: Alignment.centerRight, child: Text('البريد الإلكتروني', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary))),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textDirection: TextDirection.ltr,
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.email_outlined, color: AppTheme.primary), hintText: 'example@email.com'),
                    validator: (v) { if (v == null || v.isEmpty) return 'أدخل البريد الإلكتروني'; if (!v.contains('@')) return 'بريد غير صحيح'; return null; },
                  ),

                  const SizedBox(height: 20),

                  // Password
                  const Align(alignment: Alignment.centerRight, child: Text('كلمة المرور', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary))),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscurePass,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primary),
                      hintText: '••••••••',
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppTheme.textSecondary),
                        onPressed: () => setState(() => _obscurePass = !_obscurePass),
                      ),
                    ),
                    validator: (v) { if (v == null || v.isEmpty) return 'أدخل كلمة المرور'; if (v.length < 6) return 'كلمة المرور قصيرة'; return null; },
                  ),

                  const SizedBox(height: 12),

                  // Error
                  Consumer<AuthProvider>(
                    builder: (_, auth, __) {
                      if (auth.error == null) return const SizedBox.shrink();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.danger.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.error_outline, color: AppTheme.danger, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(auth.error!, style: const TextStyle(color: AppTheme.danger, fontSize: 13))),
                        ]),
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  // Button
                  Consumer<AuthProvider>(
                    builder: (_, auth, __) {
                      final isLoading = auth.status == AuthStatus.loading;
                      return SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _handleLogin,
                          child: isLoading
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                              : const Text('تسجيل الدخول', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
                    ),
                    child: const Row(children: [
                      Icon(Icons.info_outline, color: AppTheme.primary, size: 20),
                      SizedBox(width: 10),
                      Expanded(child: Text('هذا التطبيق مخصص للمرضى فقط.', style: TextStyle(color: AppTheme.primary, fontSize: 13))),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
