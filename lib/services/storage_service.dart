import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final _cloudinary = CloudinaryPublic('doe5u85xe', 'noche_upload', cache: false);
  final _uuid = const Uuid();

  // Compresser l'image avant upload
  Future<File> _compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath = '${dir.path}/${_uuid.v4()}.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 70,
      minWidth: 1080,
      minHeight: 1080,
    );

    return File(result!.path);
  }

  // Upload image de post
  Future<String> uploadPostImage(File file, String userId) async {
    final compressed = await _compressImage(file);
    final response = await _cloudinary.uploadFile(
      CloudinaryFile.fromFile(
        compressed.path,
        folder: 'posts/$userId',
        resourceType: CloudinaryResourceType.Image,
      ),
    );
    return response.secureUrl;
  }

  // Upload image de profil
  Future<String> uploadProfileImage(File file, String userId) async {
    final compressed = await _compressImage(file);
    final response = await _cloudinary.uploadFile(
      CloudinaryFile.fromFile(
        compressed.path,
        folder: 'profiles/$userId',
        resourceType: CloudinaryResourceType.Image,
      ),
    );
    return response.secureUrl;
  }
}