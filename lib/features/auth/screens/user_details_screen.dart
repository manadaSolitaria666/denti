// lib/features/auth/screens/user_details_screen.dart
import 'package:dental_ai_app/core/models/user_model.dart'; // Para el enum Sex
import 'package:dental_ai_app/core/providers/user_data_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dental_ai_app/features/auth/widgets/auth_form_field.dart';
// import 'package:go_router/go_router.dart'; // GoRouter se encargará de la redirección

class UserDetailsScreen extends ConsumerStatefulWidget {
  const UserDetailsScreen({super.key});

  @override
  ConsumerState<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends ConsumerState<UserDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _ageController = TextEditingController();

  Sex? _selectedSex;
  bool _termsAccepted = false;
  bool _isLoading = false;

  final _surnameFocusNode = FocusNode();
  final _ageFocusNode = FocusNode();

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _ageController.dispose();
    _surnameFocusNode.dispose();
    _ageFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveDetails() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedSex == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, selecciona tu sexo.')),
        );
        return;
      }
      if (!_termsAccepted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debes aceptar los términos y condiciones.')),
        );
        return;
      }

      setState(() => _isLoading = true);
      try {
        await ref.read(userProfileNotifierProvider.notifier).updateUserDetails(
              name: _nameController.text.trim(),
              surname: _surnameController.text.trim(),
              age: int.parse(_ageController.text.trim()),
              sex: _selectedSex!.toString().split('.').last, // "male", "female", "other"
              termsAccepted: _termsAccepted,
            );
        // GoRouter debería redirigir automáticamente a home si el perfil está completo.
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar datos: ${e.toString()}')),
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
    // Escuchar el estado del UserProfileNotifier para isLoading
    ref.listen<AsyncValue<UserModel?>>(userProfileNotifierProvider, (_, next) {
      if (mounted) {
        setState(() {
          _isLoading = next is AsyncLoading;
        });
      }
    });


    return Scaffold(
      appBar: AppBar(
        title: const Text('Completa tu Perfil'),
        automaticallyImplyLeading: false, // No queremos botón de atrás si es flujo obligatorio
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Unos pocos detalles más',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Necesitamos esta información para personalizar tu experiencia.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              AuthFormField(
                controller: _nameController,
                labelText: 'Nombre(s)',
                prefixIcon: Icons.person_outline,
                validator: (value) => value == null || value.isEmpty ? 'Ingresa tu nombre' : null,
                onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_surnameFocusNode),
              ),
              AuthFormField(
                controller: _surnameController,
                labelText: 'Apellidos',
                prefixIcon: Icons.people_alt_outlined,
                focusNode: _surnameFocusNode,
                validator: (value) => value == null || value.isEmpty ? 'Ingresa tus apellidos' : null,
                onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_ageFocusNode),
              ),
              AuthFormField(
                controller: _ageController,
                labelText: 'Edad',
                prefixIcon: Icons.cake_outlined,
                focusNode: _ageFocusNode,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Ingresa tu edad';
                  if (int.tryParse(value) == null || int.parse(value) <= 0 || int.parse(value) > 120) {
                    return 'Ingresa una edad válida';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next, // Para pasar al dropdown o al botón
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Sex>(
                decoration: InputDecoration(
                  labelText: 'Sexo',
                  prefixIcon: Icon(Icons.wc_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface.withAlpha(150),
                ),
                value: _selectedSex,
                items: Sex.values
                    .map((sex) => DropdownMenuItem(
                          value: sex,
                          child: Text(sex.toString().split('.').last.replaceFirstMapped(
                                RegExp(r'^[a-z]'), (match) => match.group(0)!.toUpperCase()
                              ) // Capitaliza la primera letra
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSex = value;
                  });
                },
                validator: (value) => value == null ? 'Selecciona tu sexo' : null,
              ),
              const SizedBox(height: 16),
              FormField<bool>(
                builder: (state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: <Widget>[
                          Checkbox(
                            value: _termsAccepted,
                            onChanged: (value) {
                              setState(() {
                                _termsAccepted = value!;
                                state.didChange(value);
                              });
                            },
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                // TODO: Mostrar diálogo/pantalla con términos y condiciones
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Términos y Condiciones'),
                                    content: const SingleChildScrollView(
                                      child: Text(
                                        'Aquí va el texto completo de los términos y condiciones...\n\n'
                                        '1. Aceptación de los términos...\n'
                                        '2. Uso de la aplicación...\n'
                                        '3. Privacidad de los datos...\n'
                                        '   La información proporcionada, incluyendo imágenes dentales y datos del formulario, será utilizada por un modelo de Inteligencia Artificial (Gemini de Google) para generar un análisis preliminar. Este análisis no constituye un diagnóstico médico definitivo y no reemplaza la consulta con un profesional dental calificado.\n'
                                        '4. Limitación de responsabilidad...\n'
                                        // ... más texto ...
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: const Text('Cerrar'),
                                      )
                                    ],
                                  )
                                );
                              },
                              child: const Text.rich(
                                TextSpan(
                                  text: 'He leído y acepto los ',
                                  children: <TextSpan>[
                                    TextSpan(
                                      text: 'Términos y Condiciones',
                                      style: TextStyle(
                                        decoration: TextDecoration.underline,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (state.hasError)
                        Padding(
                          padding: const EdgeInsets.only(left: 12.0, top: 5.0),
                          child: Text(
                            state.errorText!,
                            style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                          ),
                        ),
                    ],
                  );
                },
                validator: (value) {
                  if (!_termsAccepted) {
                    return 'Debes aceptar los términos y condiciones.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _saveDetails,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                         shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                      ),
                      child: const Text('Guardar y Continuar'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}