
// lib/features/user_profile/screens/edit_profile_screen.dart
import 'package:dental_ai_app/core/models/user_model.dart';
import 'package:dental_ai_app/core/providers/user_data_provider.dart';
import 'package:dental_ai_app/features/auth/widgets/auth_form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _surnameController;
  late TextEditingController _ageController;

  Sex? _selectedSex;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Inicializar los controladores con los datos actuales del usuario
    final user = ref.read(currentUserProfileProvider);
    _nameController = TextEditingController(text: user?.name ?? '');
    _surnameController = TextEditingController(text: user?.surname ?? '');
    _ageController = TextEditingController(text: user?.age?.toString() ?? '');
    
    if (user?.sex != null) {
      try {
        _selectedSex = Sex.values.firstWhere((e) => e.toString().split('.').last == user!.sex);
      } catch (e) {
        _selectedSex = null; // En caso de que el valor guardado no sea válido
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedSex == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, selecciona tu sexo.')),
        );
        return;
      }

      setState(() => _isLoading = true);
      try {
        await ref.read(userProfileNotifierProvider.notifier).updateUserDetails(
              name: _nameController.text.trim(),
              surname: _surnameController.text.trim(),
              age: int.parse(_ageController.text.trim()),
              sex: _selectedSex!.toString().split('.').last,
              termsAccepted: true, // Asumimos que los términos ya fueron aceptados
            );
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perfil actualizado con éxito.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al actualizar: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Escuchar el estado del perfil por si cambia desde otro lado
    ref.listen(userProfileNotifierProvider, (_, next) {
      if (next is AsyncData && next.value != null) {
        final user = next.value!;
        _nameController.text = user.name ?? '';
        _surnameController.text = user.surname ?? '';
        _ageController.text = user.age?.toString() ?? '';
         if (user.sex != null) {
          try {
            _selectedSex = Sex.values.firstWhere((e) => e.toString().split('.').last == user.sex);
          } catch (e) {
            _selectedSex = null;
          }
        }
        if (mounted) setState(() {});
      }
    });

    return Scaffold(
      // No necesita AppBar si está dentro de un TabBarView de un Scaffold con AppBar
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 16),
              AuthFormField(
                controller: _nameController,
                labelText: 'Nombre(s)',
                prefixIcon: Icons.person_outline,
                validator: (value) => value == null || value.isEmpty ? 'Ingresa tu nombre' : null,
              ),
              AuthFormField(
                controller: _surnameController,
                labelText: 'Apellidos',
                prefixIcon: Icons.people_alt_outlined,
                validator: (value) => value == null || value.isEmpty ? 'Ingresa tus apellidos' : null,
              ),
              AuthFormField(
                controller: _ageController,
                labelText: 'Edad',
                prefixIcon: Icons.cake_outlined,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Ingresa tu edad';
                  if (int.tryParse(value) == null || int.parse(value) <= 0 || int.parse(value) > 120) {
                    return 'Ingresa una edad válida';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Sex>(
                decoration: InputDecoration(
                  labelText: 'Sexo',
                  prefixIcon: const Icon(Icons.wc_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                  filled: true,
                ),
                value: _selectedSex,
                items: Sex.values
                    .map((sex) => DropdownMenuItem(
                          value: sex,
                          child: Text(sex.toString().split('.').last.replaceFirstMapped(
                                RegExp(r'^[a-z]'), (match) => match.group(0)!.toUpperCase()
                              )),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSex = value;
                  });
                },
                validator: (value) => value == null ? 'Selecciona tu sexo' : null,
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Guardar Cambios'),
                      onPressed: _updateProfile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
