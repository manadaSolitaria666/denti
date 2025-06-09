// lib/features/diagnosis/screens/image_capture_guide_screen.dart
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:dental_ai_app/core/navigation/app_router.dart';
import 'package:dental_ai_app/core/providers/diagnosis_provider.dart';
import 'package:dental_ai_app/features/diagnosis/widgets/captured_image_thumbnail.dart';
import 'package:dental_ai_app/features/diagnosis/widgets/photo_guideline_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

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
];

final availableCamerasProvider = FutureProvider.autoDispose<List<CameraDescription>>((ref) async {
  return await availableCameras();
});


class ImageCaptureGuideScreen extends ConsumerStatefulWidget {
  const ImageCaptureGuideScreen({super.key});

  @override
  ConsumerState<ImageCaptureGuideScreen> createState() => _ImageCaptureGuideScreenState();
}

class _ImageCaptureGuideScreenState extends ConsumerState<ImageCaptureGuideScreen>  with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = -1;
  int _currentStep = 0; 
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
    } else if (state == AppLifecycleState.resumed && _selectedCameraIndex != -1) {
      _initializeCameraController(_cameras[_selectedCameraIndex]);
    }
  }

  Future<void> _requestCameraPermissionAndInitialize() async {
    final status = await Permission.camera.request();
    if (!mounted) return;

    if (status.isGranted) {
      try {
        _cameras = await ref.read(availableCamerasProvider.future);
        if (!mounted) return;
        if (_cameras.isNotEmpty) {
          _selectedCameraIndex = _cameras.indexWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front
          );
          if (_selectedCameraIndex == -1) {
            _selectedCameraIndex = 0;
          }
          _initializeCameraController(_cameras[_selectedCameraIndex]);
        } else {
           setState(() => _cameraError = "No se encontraron cámaras disponibles.");
        }
      } catch (error) {
        if (mounted) setState(() => _cameraError = "Error al listar cámaras: $error");
      }
    } else {
      setState(() => _cameraError = "Permiso de cámara denegado.");
      if (status.isPermanentlyDenied) {
          _showPermissionDeniedDialog();
      }
    }
  }

  Future<void> _initializeCameraController(CameraDescription cameraDescription) async {
    if (_cameraController?.description.name == cameraDescription.name && _cameraController?.value.isInitialized == true) {
      return;
    }
    
    if (_cameraController != null) {
      await _cameraController!.dispose();
    }

    _cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.high, 
      enableAudio: false, 
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _cameraController!.addListener(() {
      if (mounted) {
        if (_cameraController!.value.hasError) {
           setState(() => _cameraError = 'Error de cámara: ${_cameraController!.value.errorDescription}');
        }
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

  void _switchCamera() {
    if (_cameras.length < 2 || _isCapturing) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    final newCamera = _cameras[_selectedCameraIndex];
    _initializeCameraController(newCamera);
  }

  void _showPermissionDeniedDialog() {
    if(!mounted) return;
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
              if(context.canPop()) context.pop();
            },
          ),
        ],
      ),
    );
  }


  Future<void> _takePicture() async {
    if (!_isCameraInitialized || _cameraController == null || !_cameraController!.value.isInitialized || _cameraController!.value.isTakingPicture) {
      return;
    }
    if (!mounted) return;
    setState(() => _isCapturing = true);

    try {
      final XFile imageXFile = await _cameraController!.takePicture();
      final File imageFile = File(imageXFile.path);

      if (mounted) {
        setState(() {
          if (_currentStep < _capturedImages.length) {
            _capturedImages[_currentStep] = imageFile;
          } else {
            _capturedImages.add(imageFile);
          }
          _isCapturing = false;
          
          final diagnosisNotifier = ref.read(diagnosisNotifierProvider.notifier);
          diagnosisNotifier.updateFormData({
            'image_angle_description_$_currentStep': photoGuidelines[_currentStep].title,
          });
        });
      }
    } on CameraException catch (e) {
      if (mounted) {
        setState(() => _isCapturing = false);
        _showCameraErrorDialog('Error al tomar foto: ${e.description}');
      }
    } catch (e) {
        if (mounted) {
            setState(() => _isCapturing = false);
            _showCameraErrorDialog('Error inesperado al tomar foto: ${e.toString()}');
        }
    }
  }
  
  void _retakePicture(int index) {
    if (_isCapturing) return;
    setState(() {
      _currentStep = index;
    });
  }

  void _nextPhotoStep() {
    if (_currentStep < photoGuidelines.length - 1) {
      if (_currentStep < _capturedImages.length && _capturedImages[_currentStep].existsSync()) { 
        if (mounted) {
          setState(() {
            _currentStep++;
          });
        }
      } else {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Por favor, captura la foto actual primero.')),
          );
        }
      }
    }
  }

  void _previousPhotoStep() {
     if (_currentStep > 0) {
      if (mounted) {
        setState(() {
          _currentStep--;
        });
      }
    }
  }

  Future<void> _proceedToAnalysis() async {
    if (_capturedImages.length < photoGuidelines.length) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Necesitas tomar las ${photoGuidelines.length} fotos requeridas.')),
        );
      }
      return;
    }

    final diagnosisNotifier = ref.read(diagnosisNotifierProvider.notifier);
    diagnosisNotifier.clearTemporaryImageData(); 
    for (final imgFile in _capturedImages) {
      diagnosisNotifier.addImageFile(imgFile);
    }
    
    if(!mounted) return;
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
    
    if (mounted) Navigator.of(context, rootNavigator: true).pop(); 

    if (reportId != null) {
      if (mounted) context.goNamed(AppRoutes.diagnosisResult, pathParameters: {'reportId': reportId});
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ref.read(diagnosisNotifierProvider).errorMessage ?? 'Error desconocido al generar diagnóstico.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool allPhotosTakenAndExist = _capturedImages.length == photoGuidelines.length && 
                                     _capturedImages.every((file) => file.existsSync());

    return Scaffold(
      appBar: AppBar(
        title: Text('Captura de Fotos (${_currentStep + 1}/${photoGuidelines.length})'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
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
        actions: [
          if (_cameras.length > 1)
            IconButton(
              icon: const Icon(Icons.flip_camera_ios_outlined),
              onPressed: _isCapturing ? null : _switchCamera,
              tooltip: 'Cambiar cámara',
            ),
        ],
      ),
      persistentFooterButtons: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: allPhotosTakenAndExist ? _proceedToAnalysis : null, 
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: const Text('Analizar Todas las Fotos'),
            ),
          ),
        )
      ],
      // CORRECCIÓN PRINCIPAL: El body es ahora una Columna con un Expanded para la cámara
      // y un Container de tamaño fijo para los controles, evitando el overflow.
      body: Column(
        children: <Widget>[
          // El preview de la cámara ahora tomará todo el espacio flexible disponible
          Expanded(
            child: Container(
              color: Colors.black, 
              child: _buildCameraPreview(),
            ),
          ),
          
          // La sección de miniaturas
          if (_capturedImages.isNotEmpty) _buildThumbnailsSection(),

          // La sección de controles y guías, ahora con tamaño flexible y compacto
          Container(
            padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Column(
              mainAxisSize: MainAxisSize.min, // La columna toma solo el espacio que necesita
              children: [
                PhotoGuidelineWidget(guideline: photoGuidelines[_currentStep]),
                const SizedBox(height: 8),
                // Contenedor con altura fija para el mensaje de confirmación para estabilizar el layout
                SizedBox(
                  height: 24,
                  child: (_currentStep < _capturedImages.length && _capturedImages[_currentStep].existsSync())
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 18),
                            const SizedBox(width: 8),
                            const Text("Foto capturada", style: TextStyle(color: Colors.green, fontSize: 12)),
                          ],
                        )
                      : null, // No mostrar nada si no hay foto
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios),
                      onPressed: _currentStep > 0 ? _previousPhotoStep : null,
                      iconSize: 28, // Tamaño reducido
                      tooltip: "Foto Anterior",
                    ),
                    ElevatedButton.icon(
                      icon: _isCapturing 
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Icon(_currentStep < _capturedImages.length ? Icons.refresh_outlined : Icons.camera_alt, size: 20),
                      label: Text(
                          _currentStep < _capturedImages.length ? 'Retomar' : 'Capturar',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      onPressed: (_isCameraInitialized && !_isCapturing && _cameraController != null && _cameraController!.value.isInitialized) ? _takePicture : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), // Padding reducido
                        backgroundColor: _currentStep < _capturedImages.length ? Colors.orangeAccent : Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                      ),
                    ),
                     IconButton(
                      icon: const Icon(Icons.arrow_forward_ios),
                      onPressed: (_currentStep < photoGuidelines.length - 1 && _currentStep < _capturedImages.length && _capturedImages[_currentStep].existsSync()) ? _nextPhotoStep : null,
                      iconSize: 28, // Tamaño reducido
                      tooltip: "Siguiente Foto",
                    ),
                  ],
                ),
              ],
            ),
          )
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
    if (!_isCameraInitialized || _cameraController == null || !_cameraController!.value.isInitialized) { 
      return const Center(child: CircularProgressIndicator());
    }
    final camera = _cameraController!;
    
    final mediaSize = MediaQuery.of(context).size;
    var scale = 1.0;
    if (camera.value.isInitialized && camera.value.aspectRatio != 0 && !camera.value.aspectRatio.isNaN && mediaSize.width != 0 && mediaSize.height !=0) {
      scale = mediaSize.aspectRatio * camera.value.aspectRatio;
    }
    
    if (scale.isNaN || scale.isInfinite) {
        scale = 1.0;
    } else if (scale < 1) {
        scale = 1 / scale;
    }

    return ClipRect( 
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.center,
        child: CameraPreview(camera),
      ),
    );
  }

  Widget _buildThumbnailsSection() {
    return Container(
      height: 120, 
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: photoGuidelines.length, 
        itemBuilder: (context, index) {
          if (index < _capturedImages.length && _capturedImages[index].existsSync()) {
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
            String placeholderTitle = photoGuidelines[index].title.replaceFirst("Foto ${index+1}: ", "");
            if (index < _capturedImages.length && !_capturedImages[index].existsSync()){
            }
            return _buildPlaceholderThumbnail(index, placeholderTitle);
          }
        },
      ),
    );
  }

  Widget _buildPlaceholderThumbnail(int index, String title) {
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
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2, 
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
