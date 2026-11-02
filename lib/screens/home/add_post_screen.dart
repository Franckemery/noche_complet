import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/storage_service.dart';

class AddPostScreen extends ConsumerStatefulWidget {
  const AddPostScreen({super.key});

  @override
  ConsumerState<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends ConsumerState<AddPostScreen> {
  final _captionController = TextEditingController();
  List<File> _imageFiles = [];
  bool _loading = false;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        _imageFiles = picked.map((e) => File(e.path)).toList();
      });
    }
  }

  void _removeImage(int index) {
    setState(() => _imageFiles.removeAt(index));
  }

  Future<void> _post() async {
    if (_imageFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Choisis au moins une image'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final user = ref.read(authStateProvider).value!;
      final userProfile = await ref.read(currentUserProvider.future);
      final storageService = StorageService();

      // Upload toutes les images
      final List<String> imageUrls = [];
      for (final file in _imageFiles) {
        final url = await storageService.uploadPostImage(file, user.uid);
        imageUrls.add(url);
      }

      await ref.read(postNotifierProvider.notifier).createPost(
            userId: user.uid,
            username: userProfile?.username ?? 'User',
            userPhotoUrl: userProfile?.photoUrl,
            imageUrl: imageUrls.first,
            imageUrls: imageUrls,
            caption: _captionController.text.trim(),
          );

      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.pop(context);
      ref.read(postsPaginationProvider.notifier).loadInitial();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        elevation: 0,
        title: Text(
          'Nouveau post',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textLight : AppColors.textDark,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(CupertinoIcons.xmark,
              color: isDark ? AppColors.textLight : AppColors.textDark),
        ),
        actions: [
          TextButton(
            onPressed: _loading ? null : _post,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Text(
                    'Publier',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Grille d'images
            if (_imageFiles.isEmpty)
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.photo_on_rectangle,
                          size: 48, color: AppColors.primary),
                      const SizedBox(height: 12),
                      Text(
                        'Appuie pour choisir des images',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: AppColors.textGrey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tu peux en choisir plusieurs',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: [
                  // Grille des images sélectionnées
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemCount: _imageFiles.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _imageFiles.length) {
                        // Bouton ajouter plus
                        return GestureDetector(
                          onTap: _pickImages,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkCard
                                  : AppColors.lightCard,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              CupertinoIcons.add,
                              color: AppColors.primary,
                              size: 32,
                            ),
                          ),
                        );
                      }
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _imageFiles[index],
                              fit: BoxFit.cover,
                            ),
                          ),
                          // Bouton supprimer
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  CupertinoIcons.xmark,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                          ),
                          // Badge numéro
                          Positioned(
                            bottom: 4,
                            left: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Compteur
                  Text(
                    '${_imageFiles.length} image${_imageFiles.length > 1 ? 's' : ''} sélectionnée${_imageFiles.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: AppColors.textGrey,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 20),

            // Caption
            TextField(
              controller: _captionController,
              maxLines: 3,
              style: TextStyle(
                fontFamily: 'Poppins',
                color: isDark ? AppColors.textLight : AppColors.textDark,
              ),
              decoration: InputDecoration(
                hintText: 'Écris une légende...',
                hintStyle: const TextStyle(
                  fontFamily: 'Poppins',
                  color: AppColors.textGrey,
                ),
                filled: true,
                fillColor:
                    isDark ? AppColors.darkCard : AppColors.lightCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



// import 'dart:io';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:image_picker/image_picker.dart';
// import '../../core/constants/app_colors.dart';
// import '../../providers/auth_provider.dart';
// import '../../providers/post_provider.dart';
// import '../../providers/user_provider.dart';
// import '../../services/storage_service.dart';

// class AddPostScreen extends ConsumerStatefulWidget {
//   const AddPostScreen({super.key});

//   @override
//   ConsumerState<AddPostScreen> createState() => _AddPostScreenState();
// }

// class _AddPostScreenState extends ConsumerState<AddPostScreen> {
//   final _captionController = TextEditingController();
//   File? _imageFile;
//   bool _loading = false;

//   @override
//   void dispose() {
//     _captionController.dispose();
//     super.dispose();
//   }

//   Future<void> _pickImage() async {
//     final picker = ImagePicker();
//     final picked = await picker.pickImage(source: ImageSource.gallery);
//     if (picked != null) {
//       setState(() => _imageFile = File(picked.path));
//     }
//   }

//   Future<void> _post() async {
//     if (_imageFile == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: const Text('Choisis une image d\'abord'),
//           backgroundColor: Colors.redAccent,
//           behavior: SnackBarBehavior.floating,
//           shape:
//               RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         ),
//       );
//       return;
//     }

//     setState(() => _loading = true);

//     try {
//       final user = ref.read(authStateProvider).value!;
//       final userProfile = await ref.read(currentUserProvider.future);
//       final storageService = StorageService();

//       final imageUrl =
//           await storageService.uploadPostImage(_imageFile!, user.uid);

//       await ref.read(postNotifierProvider.notifier).createPost(
//             userId: user.uid,
//             username: userProfile?.username ?? 'User',
//             userPhotoUrl: userProfile?.photoUrl,
//             imageUrl: imageUrl,
//             caption: _captionController.text.trim(),
//           );
//       if (!mounted) return;
//       setState(() => _loading = false);
//       Navigator.pop(context);
//       ref.read(postsPaginationProvider.notifier).loadInitial();

//       // if (!mounted) return;
//       // Navigator.pop(context);
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(e.toString()),
//           backgroundColor: Colors.redAccent,
//           behavior: SnackBarBehavior.floating,
//           shape:
//               RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         ),
//       );
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     return Scaffold(
//       backgroundColor:
//           isDark ? AppColors.darkBackground : AppColors.lightBackground,
//       appBar: AppBar(
//         backgroundColor:
//             isDark ? AppColors.darkBackground : AppColors.lightBackground,
//         elevation: 0,
//         title: Text(
//           'Nouveau post',
//           style: TextStyle(
//             fontFamily: 'Poppins',
//             fontWeight: FontWeight.w600,
//             color: isDark ? AppColors.textLight : AppColors.textDark,
//           ),
//         ),
//         leading: IconButton(
//           onPressed: () => Navigator.pop(context),
//           icon: Icon(CupertinoIcons.xmark,
//               color: isDark ? AppColors.textLight : AppColors.textDark),
//         ),
//         actions: [
//           TextButton(
//             onPressed: _loading ? null : _post,
//             child: _loading
//                 ? const SizedBox(
//                     width: 20,
//                     height: 20,
//                     child: CircularProgressIndicator(
//                       strokeWidth: 2,
//                       color: AppColors.primary,
//                     ),
//                   )
//                 : const Text(
//                     'Publier',
//                     style: TextStyle(
//                       fontFamily: 'Poppins',
//                       fontWeight: FontWeight.w600,
//                       color: AppColors.primary,
//                       fontSize: 16,
//                     ),
//                   ),
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             // Zone image
//             GestureDetector(
//               onTap: _pickImage,
//               child: Container(
//                 width: double.infinity,
//                 height: 300,
//                 decoration: BoxDecoration(
//                   color: isDark ? AppColors.darkCard : AppColors.lightCard,
//                   borderRadius: BorderRadius.circular(16),
//                   border: Border.all(
//                     color: AppColors.primary.withOpacity(0.3),
//                     width: 2,
//                   ),
//                 ),
//                 child: _imageFile != null
//                     ? ClipRRect(
//                         borderRadius: BorderRadius.circular(14),
//                         child: Image.file(_imageFile!, fit: BoxFit.cover),
//                       )
//                     : Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(CupertinoIcons.photo,
//                               size: 48, color: AppColors.primary),
//                           const SizedBox(height: 12),
//                           Text(
//                             'Appuie pour choisir une image',
//                             style: TextStyle(
//                               fontFamily: 'Poppins',
//                               color: AppColors.textGrey,
//                             ),
//                           ),
//                         ],
//                       ),
//               ),
//             ),

//             const SizedBox(height: 20),

//             // Caption
//             TextField(
//               controller: _captionController,
//               maxLines: 3,
//               style: TextStyle(
//                 fontFamily: 'Poppins',
//                 color: isDark ? AppColors.textLight : AppColors.textDark,
//               ),
//               decoration: InputDecoration(
//                 hintText: 'Écris une légende...',
//                 hintStyle: const TextStyle(
//                   fontFamily: 'Poppins',
//                   color: AppColors.textGrey,
//                 ),
//                 filled: true,
//                 fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(14),
//                   borderSide: BorderSide.none,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
