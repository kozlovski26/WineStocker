import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

class WinePhotoScreen extends StatefulWidget {
  final bool isPro;

  const WinePhotoScreen({
    super.key,
    this.isPro = false,
  });

  @override
  WinePhotoScreenState createState() => WinePhotoScreenState();
}

class WinePhotoScreenState extends State<WinePhotoScreen> {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isLoading = false;
  FlashMode _flashMode = FlashMode.auto;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _controller = CameraController(
      cameras.first,
      ResolutionPreset.max,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _controller?.initialize();
      await _controller?.lockCaptureOrientation(DeviceOrientation.portraitUp);
      await _controller?.setFocusMode(FocusMode.auto);
      await _controller?.setExposureMode(ExposureMode.auto);
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_isInitialized && _controller != null)
            Center(
              child: Transform.scale(
                scale: _getPreviewScale(),
                child: CameraPreview(_controller!),
              ),
            ),
          // Add capture frame guide
          if (_isInitialized && _controller != null)
            Center(
              child: _buildCaptureFrameGuide(),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  
                  // Add instructional overlay
                  _buildInstructionalOverlay(),
                  
                  const Spacer(),
                  _buildBottomControls(),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  double _getPreviewScale() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return 1.0;
    }
    
    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / size.height;
    final previewRatio = _controller!.value.aspectRatio;
    
    if (deviceRatio < 1.0) {
      return 1 / (previewRatio * deviceRatio);
    }
    return 1 / previewRatio;
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        IconButton(
          icon: Icon(
            _flashMode == FlashMode.torch
                ? Icons.flash_on
                : _flashMode == FlashMode.auto
                    ? Icons.flash_auto
                    : Icons.flash_off,
            color: Colors.white,
            size: 28,
          ),
          onPressed: _toggleFlash,
        ),
      ],
    );
  }

  Widget _buildInstructionalOverlay() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline, 
                color: Colors.tealAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                widget.isPro ? 'Wine AI Analysis' : 'Wine Photo Capture',
                style: TextStyle(
                  color: Colors.tealAccent.shade100,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.isPro)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.tealAccent.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'PRO',
                    style: TextStyle(
                      color: Colors.tealAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.isPro
                ? '1. Take a clear photo or upload a photo of the wine label'
                : '1. Take a clear photo of the wine bottle label or upload a photo',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.isPro
                ? '2. AI will analyze the image and extract details'
                : '2. Enter the wine details manually in the next screen',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '3. Review and save the wine to your collection',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          if (!widget.isPro)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Upgrade to Pro to unlock AI label analysis!',
                      style: TextStyle(
                        color: Colors.amber[300],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Text(
            widget.isPro
                ? 'For best results, ensure the label is well-lit and visible'
                : 'Position the wine bottle clearly in the frame',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildControlButton(
              icon: Icons.photo_library,
              label: 'Gallery',
              onPressed: _pickFromGallery,
            ),
            FloatingActionButton(
              onPressed: _takePicture,
              backgroundColor: Colors.white,
              child: const Icon(Icons.camera_alt, color: Colors.black, size: 32),
            ),
            _buildControlButton(
              icon: Icons.flip_camera_ios,
              label: 'Flip',
              onPressed: _switchCamera,
            ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.white, size: 32),
          onPressed: onPressed,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12),
        ),
      ],
    );
  }

  Future<void> _toggleFlash() async {
    if (_controller == null) return;

    try {
      final newMode = _flashMode == FlashMode.off
          ? FlashMode.auto
          : _flashMode == FlashMode.auto
              ? FlashMode.torch
              : FlashMode.off;

      await _controller!.setFlashMode(newMode);
      setState(() {
        _flashMode = newMode;
      });
    } catch (e) {
      print('Error toggling flash: $e');
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isLoading) {
      return;
    }

    try {
      setState(() => _isLoading = true);
      final image = await _controller!.takePicture();
      final croppedImage = await _cropImage(image.path);
      if (croppedImage != null && mounted) {
        Navigator.pop(context, croppedImage.path);
      }
    } catch (e) {
      print('Error taking picture: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      setState(() => _isLoading = true);

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        final croppedImage = await _cropImage(image.path);
        if (croppedImage != null && mounted) {
          Navigator.pop(context, croppedImage.path);
        }
      }
    } catch (e) {
      print('Error picking image: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_controller == null) return;

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final currentCameraIndex = cameras.indexOf(_controller!.description);
      final newCameraIndex = (currentCameraIndex + 1) % cameras.length;

      await _controller?.dispose();

      _controller = CameraController(
        cameras[newCameraIndex],
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller?.initialize();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error switching camera: $e');
    }
  }

  Future<CroppedFile?> _cropImage(String imagePath) async {
    try {
      return await ImageCropper().cropImage(
        sourcePath: imagePath,
        aspectRatio: const CropAspectRatio(ratioX: 3, ratioY: 4),
        compressQuality: 70,
        maxHeight: 600,
        maxWidth: 600,
        compressFormat: ImageCompressFormat.jpg,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Adjust Bottle Photo',
            toolbarColor: Theme.of(context).colorScheme.surface,
            toolbarWidgetColor: Theme.of(context).colorScheme.onSurface,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: 'Adjust Bottle Photo',
            doneButtonTitle: 'Done',
            cancelButtonTitle: 'Cancel',
            aspectRatioLockEnabled: true,
          ),
        ],
      );
    } catch (e) {
      print('Error cropping image: $e');
      return null;
    }
  }

  Widget _buildCaptureFrameGuide() {
    final size = MediaQuery.of(context).size;
    final width = size.width * 0.8;
    final height = width * 1.5; // 3:4.5 aspect ratio for wine label
    
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.tealAccent.withOpacity(0.7),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // Corner marks
          Positioned(
            top: 0,
            left: 0,
            child: _buildCornerMark(isTopLeft: true),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: _buildCornerMark(isTopRight: true),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            child: _buildCornerMark(isBottomLeft: true),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: _buildCornerMark(isBottomRight: true),
          ),
          
          // Center text
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Position wine label here',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCornerMark({
    bool isTopLeft = false,
    bool isTopRight = false,
    bool isBottomLeft = false,
    bool isBottomRight = false,
  }) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(
        painter: CornerMarkPainter(
          isTopLeft: isTopLeft,
          isTopRight: isTopRight,
          isBottomLeft: isBottomLeft,
          isBottomRight: isBottomRight,
        ),
      ),
    );
  }
}

class CornerMarkPainter extends CustomPainter {
  final bool isTopLeft;
  final bool isTopRight;
  final bool isBottomLeft;
  final bool isBottomRight;
  
  CornerMarkPainter({
    this.isTopLeft = false,
    this.isTopRight = false,
    this.isBottomLeft = false,
    this.isBottomRight = false,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.tealAccent.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    final length = size.width * 0.8;
    
    if (isTopLeft) {
      canvas.drawLine(Offset.zero, Offset(length, 0), paint);
      canvas.drawLine(Offset.zero, Offset(0, length), paint);
    } else if (isTopRight) {
      canvas.drawLine(Offset(size.width, 0), Offset(size.width - length, 0), paint);
      canvas.drawLine(Offset(size.width, 0), Offset(size.width, length), paint);
    } else if (isBottomLeft) {
      canvas.drawLine(Offset(0, size.height), Offset(length, size.height), paint);
      canvas.drawLine(Offset(0, size.height), Offset(0, size.height - length), paint);
    } else if (isBottomRight) {
      canvas.drawLine(Offset(size.width, size.height), Offset(size.width - length, size.height), paint);
      canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - length), paint);
    }
  }
  
  @override
  bool shouldRepaint(CornerMarkPainter oldDelegate) => false;
}
