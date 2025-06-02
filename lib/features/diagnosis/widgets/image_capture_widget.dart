// lib/features/diagnosis/screens/image_capture_guide_screen.dart
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:dental_ai_app/core/navigation/app_router.dart';
import 'package:dental_ai_app/core/providers/diagnosis_provider.dart';
import 'package:dental_ai_app/features/diagnosis/widgets/captured_image_thumbnail.dart';
import 'package:dental_ai_app/features/diagnosis/widgets/photo_guideline_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

// Lista de guías para las fotos
const List<PhotoGuideline> photoGuidelines = [
  PhotoGuideline(
      title: 'Foto 1: Frontal',
      instruction: 'Sonríe mostrando todos tus dientes frontales. Asegúrate de que haya buena iluminación y la imagen sea nítida.',
      icon: Icons.sentiment_very_satisfied_outlined),
  PhotoGuideline(
      title: 'Foto 2: Lateral Derecha',
      instruction: 'Gira ligeramente tu cabeza hacia la izquierda. Muestra los dientes del lado derecho, mordiendo normalmente.',
      icon: Icons.arrow_forward_ios_rounded),
  PhotoGuideline(
      title: 'Foto 3: Lateral Izquierda',
      instruction: 'Gira ligeramente tu cabeza hacia la derecha. Muestra los dientes del lado izquierdo, mordiendo normalmente.',
      icon: Icons.arrow_back_ios_rounded),
  PhotoGuideline(
      title: 'Foto 4: Oclusal Superior',
      instruction: 'Abre bien la boca e inclina la cabeza hacia atrás. Intenta capturar la superficie de masticación de tus dientes superiores.',
      icon: Icons.keyboard_arrow_up_rounded),
  // Podrías añadir una quinta para Oclusal Inferior si es necesario
  // PhotoGuideline(
  //     title: 'Foto 5: Oclusal Inferior',
  //     instruction: 'Abre bien la boca e inclina la cabeza hacia adelante. Intenta capturar la superficie de masticación de tus dientes inferiores.',
  //     icon: Icons.keyboard_arrow_down_rounded),
];

final availableCamerasProvider = FutureProvider<List<CameraDescription>>((ref) async {
  return await availableCameras();
});


class ImageCaptureGuideScreen extends ConsumerStatefulWidget {
  const ImageCaptureGuideScreen({super.key});

  @override
  ConsumerState<ImageCaptureGuideScreen> createState() => _ImageCaptureGuideScreenState();
}

class _ImageCaptureGuideScreenState extends ConsumerState<ImageCaptureGuideScreen>  with WidgetsBindingObserver {
  CameraController? _cameraController;
  int _currentStep = 0; // Índice de la guía actual
  final List<File> _capturedImages = [];
  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  String? _cameraError;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestCameraPermissionAndInitialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCameraController(cameraController.description);
    }
  }

  Future<void> _requestCameraPermissionAndInitialize() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      final camerasAsyncValue = ref.read(availableCamerasProvider);
      camerasAsyncValue.whenData((cameras) {
        if (cameras.isNotEmpty) {
          _initializeCameraController(cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.back, // Preferir cámara trasera
            orElse: () => cameras.first,
          ));
        } else {
           if (mounted) setState(() => _cameraError = "No se encontraron cámaras.");
        }
      });
    } else {
      if (mounted) {
        setState(() => _cameraError = "Permiso de cámara denegado.");
        // Mostrar diálogo para ir a ajustes si el permiso es permanentemente denegado
        if (status.isPermanentlyDenied) {
            _showPermissionDeniedDialog();
        }
      }
    }
  }

  Future<void> _initializeCameraController(CameraDescription cameraDescription) async {
    _cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.high, // Puedes ajustar la resolución
      enableAudio: false, // No necesitamos audio
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _cameraController!.addListener(() {
      if (mounted) setState(() {}); // Actualizar UI si el estado de la cámara cambia
      if (_cameraController!.value.hasError) {
         if (mounted) setState(() => _cameraError = 'Error de cámara: ${_cameraController!.value.errorDescription}');
      }
    });

    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _cameraError = null;
        });
      }
    } on CameraException catch (e) {
      if (mounted) setState(() => _cameraError = 'Error al inicializar cámara: ${e.description}');
      _showCameraErrorDialog(e.description);
    } catch (e) {
      if (mounted) setState(() => _cameraError = 'Error inesperado con la cámara: ${e.toString()}');
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permiso Denegado'),
        content: const Text('El permiso para usar la cámara fue denegado. Por favor, habilítalo en los ajustes de la aplicación para continuar.'),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Abrir Ajustes'),
            onPressed: () {
              openAppSettings();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  void _showCameraErrorDialog(String? message) {
     if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error de Cámara'),
        content: Text(message ?? "Ocurrió un error inesperado con la cámara."),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
              // Podrías intentar reinicializar o volver atrás
              if(context.canPop()) context.pop();
            },
          ),
        ],
      ),
    );
  }


  Future<void> _takePicture() async {
    if (!_isCameraInitialized || _cameraController == null || _cameraController!.value.isTakingPicture) {
      return;
    }
    setState(() => _isCapturing = true);

    try {
      final XFile imageXFile = await _cameraController!.takePicture();
      final File imageFile = File(imageXFile.path);

      if (mounted) {
        setState(() {
          // Si estamos retomando una foto, reemplazamos la existente
          if (_currentStep < _capturedImages.length) {
            _capturedImages[_currentStep] = imageFile;
          } else {
            _capturedImages.add(imageFile);
          }
          _isCapturing = false;
          
          // Guardar el ángulo de la foto en el formData del provider
          // Esto es para que Gemini sepa qué está viendo.
          // El nombre de la clave debe coincidir con lo que espera GeminiService.
          final diagnosisNotifier = ref.read(diagnosisNotifierProvider.notifier);
          diagnosisNotifier.updateFormData({
            'image_angle_description_$_currentStep': photoGuidelines[_currentStep].title,
          });


          // Avanzar al siguiente paso o finalizar si todas las fotos están tomadas
          if (_currentStep < photoGuidelines.length - 1) {
            // _currentStep++; // No avanzar automáticamente, permitir revisar y luego "Siguiente Foto"
          } else {
            // Todas las fotos tomadas, listo para procesar
            // _proceedToAnalysis(); // Se hará con el botón "Analizar"
          }
        });
      }
    } on CameraException catch (e) {
      if (mounted) {
        setState(() => _isCapturing = false);
        _showCameraErrorDialog('Error al tomar foto: ${e.description}');
      }
    }
  }
  
  void _retakePicture(int index) {
    if (_isCapturing) return;
    setState(() {
      _currentStep = index;
      // Opcional: eliminar la imagen anterior del provider si ya se había añadido
      // ref.read(diagnosisNotifierProvider.notifier).removeImageFile(_capturedImages[index]);
      // No es necesario eliminarla de _capturedImages aquí, se reemplazará.
    });
    // No es necesario reinicializar la cámara si ya está lista.
  }

  void _nextPhotoStep() {
    if (_currentStep < photoGuidelines.length - 1) {
      if (_currentStep < _capturedImages.length) { // Asegurarse que la foto actual fue tomada
        setState(() {
          _currentStep++;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, captura la foto actual primero.')),
        );
      }
    }
  }

  void _previousPhotoStep() {
     if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }


  Future<void> _proceedToAnalysis() async {
    if (_capturedImages.length < photoGuidelines.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Necesitas tomar las ${photoGuidelines.length} fotos requeridas.')),
      );
      return;
    }

    // Actualizar el provider con las imágenes capturadas
    final diagnosisNotifier = ref.read(diagnosisNotifierProvider.notifier);
    diagnosisNotifier.clearTemporaryImageData(); // Limpiar por si acaso
    for (final imgFile in _capturedImages) {
      diagnosisNotifier.addImageFile(imgFile);
    }

    // Navegar a la pantalla de resultados o iniciar el proceso de análisis
    // El análisis real se dispara en el provider, aquí solo navegamos
    // o mostramos un loader y luego navegamos.
    
    // Mostrar un loader mientras se procesa
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Analizando imágenes..."),
            ],
          ),
        );
      },
    );

    final reportId = await diagnosisNotifier.generateDiagnosisAndSaveReport();
    
    if (mounted) Navigator.of(context, rootNavigator: true).pop(); // Cerrar el diálogo de carga

    if (reportId != null) {
      if (mounted) context.goNamed(AppRoutes.diagnosisResult, pathParameters: {'reportId': reportId});
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ref.read(diagnosisNotifierProvider).errorMessage ?? 'Error al generar diagnóstico.')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final currentGuideline = photoGuidelines[_currentStep];
    final bool allPhotosTaken = _capturedImages.length == photoGuidelines.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Captura de Fotos (${_currentStep + 1}/${photoGuidelines.length})'),
         leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Preguntar si desea descartar las fotos
            if (_capturedImages.isNotEmpty) {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Descartar Fotos'),
                  content: const Text('¿Estás seguro de que quieres salir? Las fotos capturadas se perderán.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
                    TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        ref.read(diagnosisNotifierProvider.notifier).clearTemporaryImageData();
                        context.pop();
                      },
                      child: const Text('Salir', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: Column(
        children: <Widget>[
          // Área de la cámara
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.black,
              child: _buildCameraPreview(),
            ),
          ),
          // Guía y controles
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  PhotoGuidelineWidget(guideline: currentGuideline),
                  const SizedBox(height: 16),
                  if (_capturedImages.length > _currentStep) // Muestra si la foto actual ya fue tomada
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Text("Foto '${currentGuideline.title}' capturada.", style: const TextStyle(color: Colors.green)),
                      ],
                    ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios),
                        onPressed: _currentStep > 0 ? _previousPhotoStep : null,
                        iconSize: 30,
                        tooltip: "Foto Anterior",
                      ),
                      ElevatedButton.icon(
                        icon: _isCapturing 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Icon(_currentStep < _capturedImages.length ? Icons.refresh_outlined : Icons.camera_alt),
                        label: Text(_currentStep < _capturedImages.length ? 'Retomar Foto' : 'Capturar Foto'),
                        onPressed: (_isCameraInitialized && !_isCapturing) ? _takePicture : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          backgroundColor: _currentStep < _capturedImages.length ? Colors.orangeAccent : Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                       IconButton(
                        icon: const Icon(Icons.arrow_forward_ios),
                        onPressed: (_currentStep < photoGuidelines.length - 1 && _currentStep < _capturedImages.length) ? _nextPhotoStep : null,
                        iconSize: 30,
                        tooltip: "Siguiente Foto",
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Miniaturas y botón de finalizar
          if (_capturedImages.isNotEmpty) _buildThumbnailsSection(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: allPhotosTaken ? _proceedToAnalysis : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                 shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: const Text('Analizar Todas las Fotos'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_cameraError != null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text('Error de Cámara: $_cameraError', style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
      ));
    }
    if (!_isCameraInitialized || _cameraController == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final camera = _cameraController!;
    // Calcular la escala para la vista previa para evitar distorsión
    var scale = MediaQuery.of(context).size.aspectRatio * camera.value.aspectRatio;
    if (scale < 1) scale = 1 / scale;

    return ClipRect( // Para asegurar que la transformación no se salga de los bordes
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.center,
        child: CameraPreview(camera),
      ),
    );
  }

  Widget _buildThumbnailsSection() {
    return Container(
      height: 120, // Altura fija para la fila de miniaturas
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: photoGuidelines.length,
        itemBuilder: (context, index) {
          if (index < _capturedImages.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: SizedBox(
                width: 90,
                child: CapturedImageThumbnail(
                  imageFile: _capturedImages[index],
                  angleTitle: photoGuidelines[index].title.replaceFirst("Foto ${index+1}: ", ""),
                  onRetake: () => _retakePicture(index),
                ),
              ),
            );
          } else {
            // Placeholder para fotos no tomadas aún
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: SizedBox(
                width: 90,
                child: Card(
                  elevation: 1,
                  color: Colors.grey[300],
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_camera_back_outlined, color: Colors.grey[600], size: 24),
                        const SizedBox(height: 4),
                        Text(
                          photoGuidelines[index].title.replaceFirst("Foto ${index+1}: ", ""),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
