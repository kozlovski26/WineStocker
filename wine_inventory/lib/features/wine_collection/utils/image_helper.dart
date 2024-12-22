// // lib/features/wine_collection/utils/image_helper.dart
// import 'package:image_picker/image_picker.dart';
// import 'package:image_cropper/image_cropper.dart';
// import 'package:flutter/material.dart';

// class ImageHelper {
//   static Future<String?> pickAndCropImage(BuildContext context) async {
//     try {
//       final ImagePicker picker = ImagePicker();
//       final XFile? image = await _showImageSourceDialog(context, picker);

//       if (image != null) {
//         final CroppedFile? croppedFile = await _cropImage(context, image.path);
//         return croppedFile?.path;
//       }
//       return null;
//     } catch (e) {
//       _showErrorSnackBar(context, 'Failed to process image');
//       return null;
//     }
//   }

//   static Future<XFile?> _showImageSourceDialog(
//       BuildContext context, ImagePicker picker) {
//     return showModalBottomSheet<XFile?>(
//       context: context,
//       // Continuing lib/features/wine_collection/utils/image_helper.dart
//       backgroundColor: Theme.of(context).colorScheme.surface,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (BuildContext context) {
//         return SafeArea(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const SizedBox(height: 8),
//               Container(
//                 width: 40,
//                 height: 4,
//                 decoration: BoxDecoration(
//                   color: Colors.grey[600],
//                   borderRadius: BorderRadius.circular(2),
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Text(
//                   'For best results, position the bottle vertically and ensure it fills most of the frame',
//                   style: TextStyle(color: Colors.grey[400], fontSize: 12),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//               ListTile(
//                 leading: const Icon(Icons.camera_alt),
//                 title: const Text('Take Photo'),
//                 subtitle: const Text('Position bottle vertically'),
//                 onTap: () async {
//                   Navigator.pop(
//                     context,
//                     await picker.pickImage(
//                       source: ImageSource.camera,
//                       preferredCameraDevice: CameraDevice.rear,
//                       imageQuality: 85,
//                     ),
//                   );
//                 },
//               ),
//               ListTile(
//                 leading: const Icon(Icons.photo_library),
//                 title: const Text('Choose from Library'),
//                 subtitle: const Text('Select a vertical bottle photo'),
//                 onTap: () async {
//                   Navigator.pop(
//                     context,
//                     await picker.pickImage(
//                       source: ImageSource.gallery,
//                       imageQuality: 85,
//                     ),
//                   );
//                 },
//               ),
//               const SizedBox(height: 16),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   static Future<CroppedFile?> _cropImage(BuildContext context, String imagePath) {
//     return ImageCropper().cropImage(
//       sourcePath: imagePath,
//       aspectRatio: const CropAspectRatio(ratioX: 2, ratioY: 3),
//       compressQuality: 85,
//       maxHeight: 1920,
//       maxWidth: 1440,
//       cropStyle: CropStyle.rectangle,
//       compressFormat: ImageCompressFormat.jpg,
//       uiSettings: [
//         AndroidUiSettings(
//           toolbarTitle: 'Adjust Bottle Photo',
//           toolbarColor: Theme.of(context).colorScheme.surface,
//           toolbarWidgetColor: Theme.of(context).colorScheme.onSurface,
//           hideBottomControls: false,
//           statusBarColor: Theme.of(context).colorScheme.surface,
//           activeControlsWidgetColor: Theme.of(context).colorScheme.primary,
//           dimmedLayerColor: Colors.black.withOpacity(0.8),
//           cropGridColumnCount: 3,
//           cropGridRowCount: 4,
//           cropGridColor: Colors.white.withOpacity(0.5),
//           cropFrameColor: Colors.red[400]!,
//           cropFrameStrokeWidth: 2,
//           cropGridStrokeWidth: 1,
//           initAspectRatio: CropAspectRatioPreset.original,
//           showCropGrid: true,
//           lockAspectRatio: true,
//         ),
//         IOSUiSettings(
//           title: 'Adjust Bottle Photo',
//           doneButtonTitle: 'Done',
//           cancelButtonTitle: 'Cancel',
//           aspectRatioLockEnabled: true,
//           resetAspectRatioEnabled: false,
//           aspectRatioPickerButtonHidden: true,
//           rotateButtonsHidden: false,
//           rotateClockwiseButtonHidden: false,
//           minimumAspectRatio: 0.5,
//           rectX: 0,
//           rectY: 0,
//           rectWidth: 2,
//           rectHeight: 3,
//           showActivitySheetOnDone: false,
//           showCancelConfirmationDialog: false,
//           hidesNavigationBar: false,
//         ),
//       ],
//     );
//   }

//   static void _showErrorSnackBar(BuildContext context, String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red[400],
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//       ),
//     );
//   }

//   static void showSuccessMessage(BuildContext context) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: const Text(
//             'Photo added successfully! All bottle photos will maintain the same proportions for consistency.'),
//         backgroundColor: Colors.green[700],
//         duration: const Duration(seconds: 4),
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//       ),
//     );
//   }
// }