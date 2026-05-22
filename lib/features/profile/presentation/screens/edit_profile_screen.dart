import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../providers/profile_provider.dart';

const _allInterests = [
  'Música', 'Cine', 'Lectura', 'Deporte', 'Café', 'Arte', 'Tecnología',
  'Viajes', 'Gastronomía', 'Yoga', 'Fotografía', 'Gaming', 'Surf', 'Escalada',
  'Danza', 'Teatro', 'Moda', 'Naturaleza', 'Animales', 'Emprendimiento',
  'Fitness', 'Meditación', 'Idiomas', 'Historia', 'Ciencia',
];

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final Set<String> _selectedInterests = {};
  File? _avatarFile;
  bool _initialized = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  void _initFromProfile() {
    if (_initialized) return;
    final profileAsync = ref.read(profileNotifierProvider);
    profileAsync.whenData((profile) {
      if (profile != null) {
        _displayNameCtrl.text = profile.displayName;
        _usernameCtrl.text = profile.username;
        _bioCtrl.text = profile.bio ?? '';
        _ageCtrl.text = profile.age?.toString() ?? '';
        _selectedInterests.addAll(profile.interests);
        _initialized = true;
      }
    });
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final notifier = ref.read(profileNotifierProvider.notifier);

    String? newAvatarUrl;
    if (_avatarFile != null) {
      newAvatarUrl = await notifier.uploadAvatar(_avatarFile!);
    }

    final success = await notifier.updateProfile(
      displayName: _displayNameCtrl.text.trim(),
      username: _usernameCtrl.text.trim().toLowerCase(),
      bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
      age: int.tryParse(_ageCtrl.text),
      interests: _selectedInterests.toList(),
    );

    setState(() => _isSaving = false);
    if (!mounted) return;

    if (success) {
      context.showSuccessSnack('Perfil actualizado');
      context.pop();
    } else {
      context.showErrorSnack('Error al guardar');
    }
  }

  @override
  Widget build(BuildContext context) {
    _initFromProfile();
    final profileAsync = ref.watch(profileNotifierProvider);
    final profile = profileAsync.value;

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: const Text('Editar perfil'),
        backgroundColor: context.bgColor,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: Text(
              'Guardar',
              style: AppTextStyles.titleSmall.copyWith(color: AppColors.accent),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar
              Center(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: _pickAvatar,
                      child: _avatarFile != null
                          ? ClipOval(
                              child: Image.file(
                                _avatarFile!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            )
                          : AppAvatar(
                              imageUrl: profile?.avatarUrl,
                              name: profile?.displayName ?? '',
                              size: AvatarSize.xl,
                            ),
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
              const SizedBox(height: 32),
              AppTextField(
                controller: _displayNameCtrl,
                label: 'Nombre visible',
                hint: 'Tu nombre',
                validator: (v) => v!.length < 2 ? 'Mínimo 2 caracteres' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _usernameCtrl,
                label: 'Usuario',
                hint: 'tu_usuario',
                validator: (v) => v!.length < 3 ? 'Mínimo 3 caracteres' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _bioCtrl,
                label: 'Bio',
                hint: 'Cuéntanos sobre ti...',
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
              const SizedBox(height: 24),
              Text(
                'Intereses',
                style: AppTextStyles.titleMedium.copyWith(color: context.textColor),
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
