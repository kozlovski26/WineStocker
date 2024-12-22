import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

class WinePhotoScreen extends StatefulWidget {
  const WinePhotoScreen({super.key});

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
      ResolutionPreset.medium, // Adjusted to avoid high zoom effect
      enableAudio: false,
    );

    try {
      await _controller?.initialize();
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
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: CameraPreview(_controller!),
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
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
        imageQuality: 100,
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
        compressQuality: 85,
        maxHeight: 800,
        maxWidth: 800,
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
}
