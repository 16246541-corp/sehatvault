import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/permission_service.dart';
import '../services/image_service.dart';
import '../widgets/design/glass_button.dart';
import '../widgets/design/liquid_glass_background.dart';
import '../utils/theme.dart';

class DocumentScannerScreen extends StatefulWidget {
  const DocumentScannerScreen({super.key});

  @override
  State<DocumentScannerScreen> createState() => _DocumentScannerScreenState();
}

class _DocumentScannerScreenState extends State<DocumentScannerScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  XFile? _capturedImage;
  bool _isInitializing = true;
  bool _isCompressing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    try {
      final hasPermission = await PermissionService.requestCameraPermission();
      if (!hasPermission) {
        setState(() {
          _errorMessage = 'Camera permission denied';
          _isInitializing = false;
        });
        return;
      }

      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _errorMessage = 'No cameras found';
          _isInitializing = false;
        });
        return;
      }

      // Try to find the back camera
      final backCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      _controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error initializing camera: $e';
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final newMode = _controller!.value.flashMode == FlashMode.torch
          ? FlashMode.off
          : FlashMode.torch;
      await _controller!.setFlashMode(newMode);
      setState(() {});
    } catch (e) {
      debugPrint('Error toggling flash: $e');
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    if (_controller!.value.isTakingPicture) {
      return;
    }

    try {
      final XFile image = await _controller!.takePicture();
      setState(() {
        _capturedImage = image;
      });
      // Turn off flash torch if it was on
      if (_controller!.value.flashMode == FlashMode.torch) {
        await _controller!.setFlashMode(FlashMode.off);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking picture: $e')),
        );
      }
    }
  }

  void _retake() {
    setState(() {
      _capturedImage = null;
    });
  }

  void _cancel() {
    Navigator.pop(context);
  }

  Future<void> _usePicture() async {
    if (_capturedImage == null) return;

    setState(() {
      _isCompressing = true;
    });

    try {
      final compressedPath = await ImageService.compressImage(File(_capturedImage!.path));
      if (mounted) {
        Navigator.pop(context, compressedPath);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCompressing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error compressing image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: _cancel,
        ),
        title: const Text(
          'Document Scanner',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_controller != null && _controller!.value.isInitialized && _capturedImage == null)
            IconButton(
              icon: Icon(
                _controller!.value.flashMode == FlashMode.torch
                    ? Icons.flash_on
                    : Icons.flash_off,
                color: Colors.white,
              ),
              onPressed: _toggleFlash,
            ),
        ],
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: LiquidGlassBackground(
        showTexture: false,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isInitializing || _isCompressing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppTheme.accentTeal),
            if (_isCompressing) ...[
              const SizedBox(height: 20),
              const Text(
                'Optimizing for processing...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GlassButton(
              label: 'Retry',
              onPressed: _initializeCamera,
              isProminent: true,
            ),
          ],
        ),
      );
    }

    if (_capturedImage != null) {
      return _buildImagePreview();
    }

    return _buildCameraPreview();
  }

  Widget _buildCameraPreview() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        // Camera Preview
        Positioned.fill(
          child: OverflowBox(
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: 1,
                height: 1 / _controller!.value.aspectRatio,
                child: CameraPreview(_controller!),
              ),
            ),
          ),
        ),

        // Scanner Overlay (Subtle frame)
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            height: (MediaQuery.of(context).size.width * 0.85) * 1.414, // A4 aspect ratio roughly
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                // Corner markers
                _buildCorner(Alignment.topLeft),
                _buildCorner(Alignment.topRight),
                _buildCorner(Alignment.bottomLeft),
                _buildCorner(Alignment.bottomRight),
                
                // Guidance text
                const Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: Text(
                      'Align document within frame',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Controls
        Positioned(
          bottom: 60,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GlassButton(
                label: 'Cancel',
                onPressed: _cancel,
                icon: Icons.close,
              ),
              _buildCaptureButton(),
              const SizedBox(width: 80), // For symmetry
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCorner(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border(
            top: alignment == Alignment.topLeft || alignment == Alignment.topRight
                ? const BorderSide(color: Colors.white, width: 4)
                : BorderSide.none,
            bottom: alignment == Alignment.bottomLeft || alignment == Alignment.bottomRight
                ? const BorderSide(color: Colors.white, width: 4)
                : BorderSide.none,
            left: alignment == Alignment.topLeft || alignment == Alignment.bottomLeft
                ? const BorderSide(color: Colors.white, width: 4)
                : BorderSide.none,
            right: alignment == Alignment.topRight || alignment == Alignment.bottomRight
                ? const BorderSide(color: Colors.white, width: 4)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildCaptureButton() {
    return GestureDetector(
      onTap: _takePicture,
      child: Container(
        height: 84,
        width: 84,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: Center(
          child: Container(
            height: 68,
            width: 68,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: const Icon(Icons.camera_alt, color: Colors.black45, size: 30),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            color: Colors.black,
            child: Image.file(
              File(_capturedImage!.path),
              fit: BoxFit.contain,
            ),
          ),
        ),
        Positioned(
          bottom: 60,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GlassButton(
                label: 'Retake',
                onPressed: _retake,
                icon: Icons.refresh,
              ),
              GlassButton(
                label: 'Use Photo',
                onPressed: _usePicture,
                icon: Icons.check,
                isProminent: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
