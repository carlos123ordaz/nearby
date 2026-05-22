import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
      ),
      alignment: Alignment.center,
      child: const Text(
        'G',
        style: TextStyle(
          color: Color(0xFF4285F4),
          fontSize: 13,
          fontWeight: FontWeight.bold,
          height: 1,
        ),
      ),
    );
  }
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    await ref.read(authNotifierProvider.notifier).signInWithGoogle();
    if (!mounted) return;
    final error = ref.read(authNotifierProvider).error;
    if (error != null) {
      context.showErrorSnack(error.toString());
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final notifier = ref.read(authNotifierProvider.notifier);
    final success = await notifier.signIn(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );

    if (!mounted) return;

    if (success) {
      context.go('/main');
    } else {
      final error = ref.read(authNotifierProvider).error;
      context.showErrorSnack(error?.toString() ?? 'Error al iniciar sesión');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/welcome'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Text(
                  'Bienvenido de vuelta',
                  style: AppTextStyles.displayMedium.copyWith(
                    color: context.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Inicia sesión para continuar',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: context.textDimColor,
                  ),
                ),
                const SizedBox(height: 40),
                AppTextField(
                  controller: _emailCtrl,
                  label: 'Correo electrónico',
                  hint: 'tu@correo.com',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Campo requerido';
                    if (!v.isValidEmail) return 'Correo inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _passwordCtrl,
                  label: 'Contraseña',
                  hint: '••••••••',
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: context.textFaintColor,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Campo requerido';
                    if (v.length < 6) return 'Mínimo 6 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.go('/forgot-password'),
                    child: Text(
                      '¿Olvidaste tu contraseña?',
                      style: AppTextStyles.labelLarge.copyWith(color: AppColors.accent),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                AppButton(
                  label: 'Iniciar sesión',
                  onPressed: isLoading ? null : _login,
                  isLoading: isLoading,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'o continúa con',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: context.textFaintColor,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: isLoading ? null : _signInWithGoogle,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    foregroundColor: context.textColor,
                    side: BorderSide(color: context.borderColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const _GoogleIcon(),
                      const SizedBox(width: 12),
                      Text(
                        'Continuar con Google',
                        style: AppTextStyles.titleSmall.copyWith(
                          color: context.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '¿No tienes cuenta? ',
                      style: AppTextStyles.bodyMedium.copyWith(color: context.textDimColor),
                    ),
                    TextButton(
                      onPressed: () => context.go('/register'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Regístrate',
                        style: AppTextStyles.titleSmall.copyWith(color: AppColors.accent),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
