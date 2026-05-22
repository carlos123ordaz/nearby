import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final notifier = ref.read(authNotifierProvider.notifier);
    final success = await notifier.resetPassword(_emailCtrl.text.trim());
    if (!mounted) return;

    if (success) {
      setState(() => _sent = true);
    } else {
      context.showErrorSnack('Error al enviar el correo');
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
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _sent ? _buildSuccess() : _buildForm(isLoading),
        ),
      ),
    );
  }

  Widget _buildForm(bool isLoading) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          Text(
            'Recuperar contraseña',
            style: AppTextStyles.displayMedium.copyWith(color: context.textColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Te enviaremos un enlace para restablecer tu contraseña',
            style: AppTextStyles.bodyMedium.copyWith(color: context.textDimColor),
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
          const SizedBox(height: 32),
          AppButton(
            label: 'Enviar enlace',
            onPressed: isLoading ? null : _send,
            isLoading: isLoading,
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.successSoft,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.email_rounded, color: AppColors.success, size: 40),
        ),
        const SizedBox(height: 24),
        Text(
          '¡Correo enviado!',
          style: AppTextStyles.headlineLarge.copyWith(color: context.textColor),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Revisa tu bandeja de entrada y sigue las instrucciones para restablecer tu contraseña.',
          style: AppTextStyles.bodyMedium.copyWith(color: context.textDimColor),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        AppButton(
          label: 'Volver al inicio',
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }
}
