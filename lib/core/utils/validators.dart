class Validators {
  static String? required(String? value, [String field = 'Campo']) {
    if (value == null || value.trim().isEmpty) return '$field requerido';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Correo requerido';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return 'Correo inválido';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Contraseña requerida';
    if (value.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }

  static String? username(String? value) {
    if (value == null || value.isEmpty) return 'Usuario requerido';
    if (value.length < 3) return 'Mínimo 3 caracteres';
    if (value.length > 20) return 'Máximo 20 caracteres';
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegex.hasMatch(value)) return 'Solo letras, números y _';
    return null;
  }

  static String? displayName(String? value) {
    if (value == null || value.isEmpty) return 'Nombre requerido';
    if (value.length < 2) return 'Mínimo 2 caracteres';
    if (value.length > 60) return 'Máximo 60 caracteres';
    return null;
  }

  static String? age(String? value) {
    if (value == null || value.isEmpty) return null; // Optional
    final age = int.tryParse(value);
    if (age == null) return 'Edad inválida';
    if (age < 13) return 'Debes tener al menos 13 años';
    if (age > 120) return 'Edad inválida';
    return null;
  }
}
