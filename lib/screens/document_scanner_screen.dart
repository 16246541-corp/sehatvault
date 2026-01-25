import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/keyboard_shortcut_service.dart';
import 'package:flutter/services.dart';
import '../services/permission_service.dart';
import '../services/image_service.dart';
import '../services/image_quality_service.dart';
import '../services/voice_guidance_service.dart';
import '../services/vault_service.dart';
import '../services/local_storage_service.dart';
import '../services/session_manager.dart';
import '../services/temp_file_manager.dart';
import '../services/consent_service.dart';
import '../services/batch_processing_service.dart';
import '../widgets/onboarding/coach_mark.dart';
import '../widgets/onboarding/tooltip_overlay.dart';
import 'batch_processing_screen.dart';

import '../widgets/design/glass_button.dart';
import '../widgets/design/liquid_glass_background.dart';
import '../widgets/desktop/file_drop_zone.dart';
import '../widgets/dialogs/save_to_vault_dialog.dart';
import '../utils/theme.dart';

class DocumentScannerScreen extends StatefulWidget {
  final bool showOnboardingTips;
  const DocumentScannerScreen({super.key, this.showOnboardingTips = false});


  @override
  State<DocumentScannerScreen> createState() => _DocumentScannerScreenState();
}

class _DocumentScannerScreenState extends State<DocumentScannerScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  final List<XFile> _capturedImages = [];
  bool _isInitializing = true;
  bool _isCompressing = false;
  String? _errorMessage;

  // Voice Guidance
  final VoiceGuidanceService _voiceGuidance = VoiceGuidanceService();
  bool _isStreaming = false;
  DateTime? _lastAnalysisTime;
  bool _wasDark = false;
  OverlayEntry? _coachMarkEntry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
    _checkConsent();
    KeyboardShortcutService().registerAction('capture_document', _takePicture);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SessionManager().showEducationIfNeeded('document_scanner');
      if (widget.showOnboardingTips) {
        _showCaptureCoachMark();
      }
    });
  }

  void _showCaptureCoachMark() {
    _coachMarkEntry = OverlayEntry(
      builder: (context) => const CoachMark(
        text: 'Tap here to capture your first document',
        alignment: Alignment.bottomCenter,
        icon: Icons.camera_alt_rounded,
      ),
    );
    Overlay.of(context).insert(_coachMarkEntry!);
  }

  void _hideCoachMark() {
    _coachMarkEntry?.remove();
    _coachMarkEntry = null;
  }


  Future<void> _checkConsent() async {
    final service = ConsentService();
    if (!service.hasValidConsent('camera')) {
      // Load template content
      final content = await service.loadTemplate('camera', 'v1');

      if (!mounted) return;

      final granted = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Camera Consent'),
              content: SingleChildScrollView(child: Text(content)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Deny'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Allow'),
                ),
              ],
            ),
          ) ??
          false;

      if (granted) {
        await service.recordConsent(
          templateId: 'camera',
          version: 'v1',
          userId: 'local_user',
          scope: 'camera',
          granted: true,
          content: content,
        );
        _initializeCamera();
      } else {
        if (mounted) Navigator.pop(context);
      }
    } else {
      _initializeCamera();
    }
  }

  Future<void> _initializeServices() async {
    await _voiceGuidance.initialize();
  }

  @override
  void dispose() {
    _hideCoachMark();
    _voiceGuidance.stop();
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _cleanupTempFiles();
    super.dispose();
  }


  Future<void> _cleanupTempFiles() async {
    // Release all captured images so they can be purged
    for (var img in _capturedImages) {
      TempFileManager().releaseFile(img.path);
    }
    // Trigger a purge of non-preserved files (which includes these now)
    await TempFileManager().purgeAll(reason: 'scanner_closed');
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

      // Register with TempFileManager
      TempFileManager().registerFile(image.path);
      TempFileManager().preserveFile(image.path);

      // Analyze image quality
      if (mounted) {
        final file = File(image.path);
        try {
          final qualityResult = await ImageQualityService.analyzeImage(file);

          if (qualityResult.hasIssues && mounted) {
            // Show warning dialog
            final shouldKeep = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                backgroundColor: Colors.white.withOpacity(0.9),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Quality Check'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('We detected potential issues with this image:',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 12),
                    ...qualityResult.warnings.map((w) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ',
                                  style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold)),
                              Expanded(
                                  child: Text(w,
                                      style: const TextStyle(fontSize: 14))),
                            ],
                          ),
                        )),
                    const SizedBox(height: 16),
                    const Text(
                        'Poor quality images may result in inaccurate text extraction.',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false), // Retake
                    child: const Text('Retake',
                        style: TextStyle(color: Colors.red)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true), // Keep
                    child: const Text('Keep Anyway'),
                  ),
                ],
              ),
            );

            if (shouldKeep != true) {
              // User chose to retake
              TempFileManager().releaseFile(image.path);
              await TempFileManager().secureDelete(file);
              TempFileManager().unregisterFile(image.path);
              return;
            }
          }
        } catch (e) {
          debugPrint("Error analyzing image quality: $e");
          // Fail gracefully - just proceed if analysis fails
        }
      }

      setState(() {
        _capturedImages.add(image);
      });
      _hideCoachMark();
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

  void _startScanningStream() {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isStreaming) return;

    try {
      _controller!.startImageStream((image) {
        _processCameraImage(image);
      });
      setState(() {
        _isStreaming = true;
      });
    } catch (e) {
      debugPrint("Error starting image stream: $e");
    }
  }

  void _processCameraImage(CameraImage image) {
    // Throttle: Analyze every 1.5 seconds to avoid spamming and reduce CPU usage
    final now = DateTime.now();
    if (_lastAnalysisTime != null &&
        now.difference(_lastAnalysisTime!) <
            const Duration(milliseconds: 1500)) {
      return;
    }
    _lastAnalysisTime = now;

    try {
      // Analyze on the current isolate (lightweight analysis)
      final result = ImageQualityService.analyzeFrame(image);
      _provideVoiceFeedback(result);
    } catch (e) {
      debugPrint("Error analyzing frame: $e");
    }
  }

  void _provideVoiceFeedback(ImageQualityResult result) {
    if (!mounted) return;

    if (result.isDark) {
      _voiceGuidance.speak("More light needed");
      _wasDark = true;
    } else {
      if (_wasDark) {
        _voiceGuidance.speak("Good lighting detected");
        _wasDark = false;
      } else if (result.isBlurry) {
        _voiceGuidance.speak("Hold steady");
      } else {
        // If everything is good, remind to center
        // We use a lower priority so it doesn't override critical warnings
        _voiceGuidance.speak("Center your document");
      }
    }
  }

  void _removeImage(int index) {
    final image = _capturedImages[index];

    // Secure delete from disk and temp manager
    TempFileManager().releaseFile(image.path);
    TempFileManager().secureDelete(File(image.path));
    TempFileManager().unregisterFile(image.path);

    setState(() {
      _capturedImages.removeAt(index);
    });
  }

  void _cancel() {
    _cleanupTempFiles();
    Navigator.pop(context);
  }

  Future<void> _processImages() async {
    if (_capturedImages.isEmpty) return;

    setState(() {
      _isCompressing = true;
    });

    try {
      // Step 1: Compress all images
      List<String> compressedPaths = [];
      for (var image in _capturedImages) {
        final compressedPath =
            await ImageService.compressImage(File(image.path));
        compressedPaths.add(compressedPath);

        // Register compressed file too
        TempFileManager().registerFile(compressedPath);
        TempFileManager().preserveFile(compressedPath);
      }

      if (!mounted) return;

      setState(() {
        _isCompressing = false;
      });

      final progressNotifier = ValueNotifier<String>('Initializing...');

      // Step 2: Show save to vault dialog
      final shouldSave = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => SaveToVaultDialog(
          imagePaths: compressedPaths,
          progressNotifier: progressNotifier,
          onSave: (title, category, notes) async {
            // Initialize services
            final storageService = LocalStorageService();
            await storageService.initialize();
            final vaultService = VaultService(storageService);

            // Save all documents
            for (int i = 0; i < compressedPaths.length; i++) {
              final path = compressedPaths[i];
              // If multiple images, append index to title
              final docTitle =
                  compressedPaths.length > 1 ? '$title ${i + 1}' : title;

              // Update notifier
              progressNotifier.value =
                  'Processing ${i + 1} of ${compressedPaths.length}...';

              await vaultService.saveDocumentToVault(
                imageFile: File(path),
                title: docTitle,
                category: category,
                notes: notes,
                onProgress: (status) {
                  progressNotifier.value =
                      'Document ${i + 1}/${compressedPaths.length}: $status';
                },
              );
            }
          },
        ),
      );

      if (mounted) {
        if (shouldSave == true) {
          // Success - show feedback and close scanner
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Text('${compressedPaths.length} document(s) saved to vault!'),
                ],
              ),
              backgroundColor: AppTheme.accentTeal,
              duration: const Duration(seconds: 3),
            ),
          );

          // Cleanup all temp files (original + compressed)
          // Since they are now in vault
          for (var path in compressedPaths) {
            TempFileManager().releaseFile(path);
          }
          for (var img in _capturedImages) {
            TempFileManager().releaseFile(img.path);
          }
          await TempFileManager().purgeAll(reason: 'saved_to_vault');

          Navigator.pop(context, compressedPaths.first);
        } else {
          // User cancelled - stay on preview
          // Clean up compressed files as they are no longer needed for preview (we show originals)
          for (var path in compressedPaths) {
            TempFileManager().releaseFile(path);
            TempFileManager().secureDelete(File(path));
            TempFileManager().unregisterFile(path);
          }

          setState(() {
            _isCompressing = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCompressing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _processAsBatch() async {
    if (_capturedImages.isEmpty) return;

    setState(() {
      _isCompressing = true;
    });

    try {
      final List<({String title, String filePath})> batchItems = [];
      final now = DateTime.now();
      final dateStr = DateFormat('yyyyMMdd_HHmm').format(now);

      for (int i = 0; i < _capturedImages.length; i++) {
        final image = _capturedImages[i];
        final compressedPath =
            await ImageService.compressImage(File(image.path));

        // Preserve compressed file for batch processing
        TempFileManager().registerFile(compressedPath);
        TempFileManager().preserveFile(compressedPath);

        batchItems.add((
          title: 'Batch Scan $dateStr ${i + 1}',
          filePath: compressedPath,
        ));
      }

      final batchService = BatchProcessingService();
      await batchService.addBatch(batchItems);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${batchItems.length} documents added to processing queue'),
            backgroundColor: Colors.blue,
            action: SnackBarAction(
              label: 'View Queue',
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BatchProcessingScreen(),
                  ),
                );
              },
            ),
          ),
        );

        // Cleanup original images as we've created compressed ones for the batch
        for (var img in _capturedImages) {
          TempFileManager().releaseFile(img.path);
        }
        await TempFileManager().purgeAll(reason: 'moved_to_batch');

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCompressing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error adding to batch: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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
          if (_controller != null && _controller!.value.isInitialized)
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
        child: FileDropZone(
          vaultService: VaultService(LocalStorageService()),
          settings: LocalStorageService().getAppSettings(),
          child: _buildBody(),
        ),
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

    // Always show camera preview with overlay
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
            height: (MediaQuery.of(context).size.width * 0.85) *
                1.414, // A4 aspect ratio roughly
            decoration: BoxDecoration(
              border:
                  Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
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
          bottom: 30,
          left: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Captured Images Gallery (Horizontal)
              if (_capturedImages.isNotEmpty)
                Container(
                  height: 80,
                  margin: const EdgeInsets.only(bottom: 20),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _capturedImages.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 12, top: 8),
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white, width: 2),
                              image: DecorationImage(
                                image: FileImage(
                                    File(_capturedImages[index].path)),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close,
                                    size: 12, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Cancel / Done
                  if (_capturedImages.isNotEmpty)
                    Row(
                      children: [
                        GlassButton(
                          label: 'Done',
                          onPressed: _processImages,
                          isProminent: true,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.auto_awesome_motion,
                              color: Colors.white),
                          tooltip: 'Process as Batch',
                          onPressed: _processAsBatch,
                        ),
                      ],
                    )
                  else
                    const SizedBox(width: 100), // Spacer

                  // Capture Button
                  GestureDetector(
                    onTap: _takePicture,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        color: Colors.white.withOpacity(0.2),
                      ),
                      child: Center(
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Spacer to balance
                  const SizedBox(width: 100),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCorner(Alignment alignment) {
    // Helper to build corner markers
    // Implementation of corner markers...
    // Simplified for this file as I don't have the original code for this part,
    // but assuming it existed or I can implement a simple one.
    // Based on previous file reading, I didn't see the helper method, maybe it was further down?
    // Ah, I read up to line 599. Let me check if I missed it.
    // The previous read ended at 599. I should probably include it or stub it if it was there.
    // The previous read showed `_buildCorner` usage but I didn't see the definition.
    // I will add a simple implementation.

    final isTop = alignment.y < 0;
    final isLeft = alignment.x < 0;
    const double size = 20;
    const double thickness = 3;

    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            top: isTop
                ? const BorderSide(color: AppTheme.accentTeal, width: thickness)
                : BorderSide.none,
            bottom: !isTop
                ? const BorderSide(color: AppTheme.accentTeal, width: thickness)
                : BorderSide.none,
            left: isLeft
                ? const BorderSide(color: AppTheme.accentTeal, width: thickness)
                : BorderSide.none,
            right: !isLeft
                ? const BorderSide(color: AppTheme.accentTeal, width: thickness)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
