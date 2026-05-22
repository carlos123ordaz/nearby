import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../providers/profile_provider.dart';

const _allInterests = [
  'Música', 'Cine', 'Lectura', 'Deporte', 'Café', 'Arte', 'Tecnología',
  'Viajes', 'Gastronomía', 'Yoga', 'Fotografía', 'Gaming', 'Surf', 'Escalada',
  'Danza', 'Teatro', 'Moda', 'Naturaleza', 'Animales', 'Emprendimiento',
  'Fitness', 'Meditación', 'Idiomas', 'Historia', 'Ciencia',
];

class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _pageCtrl = PageController();
  int _currentPage = 0;

  // Step 1
  File? _avatarFile;
  final _displayNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();

  // Step 2
  final _bioCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();

  // Step 3
  final Set<String> _selectedInterests = {};

  bool _isLoading = false;

  @override
  void dispose() {
    _pageCtrl.dispose();
    _displayNameCtrl.dispose();
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() => _avatarFile = File(image.path));
    }
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage++);
    } else {
      _submit();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage--);
    }
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    final notifier = ref.read(profileNotifierProvider.notifier);

    try {
      // Upload avatar to storage first (no profile row yet, so don't call uploadAvatar
      // which internally calls updateProfile and would fail with 0 rows matched).
      String? avatarUrl;
      if (_avatarFile != null) {
        avatarUrl = await notifier.uploadAvatarFile(_avatarFile!);
      }

      await notifier.createProfile(
        username: _usernameCtrl.text.trim().toLowerCase(),
        displayName: _displayNameCtrl.text.trim(),
        avatarUrl: avatarUrl,
        bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
        age: int.tryParse(_ageCtrl.text),
        interests: _selectedInterests.toList(),
      );

      if (!mounted) return;
      context.go('/main');
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnack(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _canProceed() {
    if (_currentPage == 0) {
      return _displayNameCtrl.text.trim().length >= 2 &&
          _usernameCtrl.text.trim().length >= 3;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      onPressed: _prevPage,
                    )
                  else
                    const SizedBox(width: 48),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Paso ${_currentPage + 1} de 3',
                          style: AppTextStyles.labelSmall.copyWith(color: context.textFaintColor),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: List.generate(3, (i) {
                            return Expanded(
                              child: Container(
                                height: 3,
                                margin: EdgeInsets.only(left: i > 0 ? 4 : 0),
                                decoration: BoxDecoration(
                                  color: i <= _currentPage ? AppColors.accent : context.surface3Color,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _Step1(),
                  _Step2(),
                  _Step3(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: AppButton(
                label: _currentPage < 2
                    ? 'Continuar'
                    : _isLoading
                        ? 'Guardando...'
                        : 'Finalizar',
                onPressed: _canProceed() && !_isLoading ? _nextPage : null,
                isLoading: _isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _Step1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tu perfil',
            style: AppTextStyles.displayMedium.copyWith(color: context.textColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Así es como te verán otros usuarios',
            style: AppTextStyles.bodyMedium.copyWith(color: context.textDimColor),
          ),
          const SizedBox(height: 32),
          Center(
            child: GestureDetector(
              onTap: _pickAvatar,
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: context.surface2Color,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.darkBorderStrong),
                    ),
                    child: _avatarFile != null
                        ? ClipOval(
                            child: Image.file(_avatarFile!, fit: BoxFit.cover),
                          )
                        : const Icon(Icons.person_rounded, size: 48, color: AppColors.darkTextFaint),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          AppTextField(
            controller: _displayNameCtrl,
            label: 'Nombre visible',
            hint: 'Como quieres que te llamen',
            onChanged: (_) => setState(() {}),
            validator: (v) => v!.length < 2 ? 'Mínimo 2 caracteres' : null,
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _usernameCtrl,
            label: 'Usuario',
            hint: 'tu_usuario',
            onChanged: (_) => setState(() {}),
            validator: (v) => v!.length < 3 ? 'Mínimo 3 caracteres' : null,
          ),
          const SizedBox(height: 8),
          Text(
            'Solo letras, números y _. Mínimo 3 caracteres.',
            style: AppTextStyles.labelSmall.copyWith(color: context.textFaintColor),
          ),
        ],
      ),
    );
  }

  Widget _Step2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Cuéntanos de ti',
            style: AppTextStyles.displayMedium.copyWith(color: context.textColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Opcional pero recomendado',
            style: AppTextStyles.bodyMedium.copyWith(color: context.textDimColor),
          ),
          const SizedBox(height: 32),
          AppTextField(
            controller: _bioCtrl,
            label: 'Bio',
            hint: 'Cuéntanos algo sobre ti...',
            maxLines: 4,
            maxLength: 160,
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _ageCtrl,
            label: 'Edad (opcional)',
            hint: '25',
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _Step3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tus intereses',
            style: AppTextStyles.displayMedium.copyWith(color: context.textColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Selecciona los que te representen (máx. 10)',
            style: AppTextStyles.bodyMedium.copyWith(color: context.textDimColor),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allInterests.map((interest) {
              final selected = _selectedInterests.contains(interest);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (selected) {
                      _selectedInterests.remove(interest);
                    } else if (_selectedInterests.length < 10) {
                      _selectedInterests.add(interest);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.accentSoft : context.surface2Color,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? AppColors.accent : context.borderColor,
                    ),
                  ),
                  child: Text(
                    interest,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: selected ? AppColors.accent : context.textDimColor,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            '${_selectedInterests.length}/10 seleccionados',
            style: AppTextStyles.labelSmall.copyWith(color: context.textFaintColor),
          ),
        ],
      ),
    );
  }
}
