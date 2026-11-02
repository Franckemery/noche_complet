import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';

class ImageViewerScreen extends StatelessWidget {
  final String imageUrl;

  const ImageViewerScreen({super.key, required this.imageUrl});
  Future<void> _downloadImage(BuildContext context) async {
    try {
      PermissionStatus status = await Permission.mediaLibrary.request();

      if (status.isPermanentlyDenied) {
        // Ouvre les paramètres du téléphone pour activer manuellement
        await openAppSettings();
        return;
      }

      if (status.isGranted || status.isLimited) {
        final response = await Dio().get(
          imageUrl,
          options: Options(responseType: ResponseType.bytes),
        );
        await SaverGallery.saveImage(
          Uint8List.fromList(response.data),
          quality: 100,
          fileName: 'noche_${DateTime.now().millisecondsSinceEpoch}',
          androidRelativePath: 'Pictures/Noche',
          skipIfExists: false,
        );
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Image sauvegardée dans la galerie'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        // Demande la permission une deuxième fois si refusée
        status = await Permission.photos.request();
        if (!context.mounted) return;
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  'Autorise l\'accès aux photos dans les paramètres'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              action: SnackBarAction(
                label: 'Paramètres',
                textColor: Colors.white,
                onPressed: () => openAppSettings(),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  // Future<void> _downloadImage(BuildContext context) async {
  //   try {
  //       final status = await Permission.photos.request();

  //       if (status.isGranted || status.isLimited) {
  //         final response = await Dio().get(
  //           imageUrl,
  //           options: Options(responseType: ResponseType.bytes),
  //         );
  //       await SaverGallery.saveImage(
  //         Uint8List.fromList(response.data),
  //         quality: 100,
  //         fileName: 'noche_${DateTime.now().millisecondsSinceEpoch}',
  //         androidRelativePath: 'Pictures/Noche',
  //         skipIfExists: false,
  //       );
  //       if (!context.mounted) return;
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: const Text('Image sauvegardée dans la galerie '),
  //           backgroundColor: Colors.green.shade600,
  //           behavior: SnackBarBehavior.floating,
  //           shape:
  //               RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //         ),
  //       );
  //     } else {
  //       if (!context.mounted) return;
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: const Text('Permission refusée'),
  //           backgroundColor: Colors.redAccent,
  //           behavior: SnackBarBehavior.floating,
  //           shape:
  //               RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     if (!context.mounted) return;
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(e.toString()),
  //         backgroundColor: Colors.redAccent,
  //         behavior: SnackBarBehavior.floating,
  //         shape:
  //             RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //       ),
  //     );
  //   }}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () => _downloadImage(context),
            icon: const Icon(
              CupertinoIcons.cloud_download,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            placeholder: (context, url) => const CircularProgressIndicator(
              color: Colors.white,
            ),
            errorWidget: (context, url, error) => const Icon(
              Icons.error,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
