import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/post_provider.dart';
import '../../services/storage_service.dart';
import '../../widgets/post_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  bool _editing = false;
  bool _loading = false;
  File? _newPhoto;

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _newPhoto = File(picked.path));
    }
  }

  Future<void> _saveProfile() async {
    if (_usernameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Le nom d\'utilisateur ne peut pas être vide'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final user = ref.read(authStateProvider).value!;
      String? photoUrl;

      if (_newPhoto != null) {
        final storageService = StorageService();
        photoUrl =
            await storageService.uploadProfileImage(_newPhoto!, user.uid);
      }

      final Map<String, dynamic> data = {
        'username': _usernameController.text.trim(),
        'bio': _bioController.text.trim(),
      };
      if (photoUrl != null) data['photoUrl'] = photoUrl;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(data);

      if (!mounted) return;
      setState(() {
        _editing = false;
        _newPhoto = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profil mis à jour '),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : ${e.toString()}'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Future<void> _saveProfile() async {
  //   setState(() => _loading = true);
  //   try {
  //     final user = ref.read(authStateProvider).value!;
  //     String? photoUrl;

  //     if (_newPhoto != null) {
  //       final storageService = StorageService();
  //       photoUrl =
  //           await storageService.uploadProfileImage(_newPhoto!, user.uid);
  //     }

  //     await ref.read(userNotifierProvider.notifier).updateProfile(
  //           uid: user.uid,
  //           username: _usernameController.text.trim().isNotEmpty
  //               ? _usernameController.text.trim()
  //               : null,
  //           bio: _bioController.text.trim().isNotEmpty
  //               ? _bioController.text.trim()
  //               : null,
  //           photoUrl: photoUrl,
  //         );

  //     if (!mounted) return;
  //     setState(() {
  //       _editing = false;
  //       _newPhoto = null;
  //     });

  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: const Text('Profil mis à jour '),
  //         backgroundColor: Colors.green.shade600,
  //         behavior: SnackBarBehavior.floating,
  //         shape:
  //             RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //       ),
  //     );
  //   } catch (e) {
  //     if (!mounted) return;
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(e.toString()),
  //         backgroundColor: Colors.redAccent,
  //         behavior: SnackBarBehavior.floating,
  //         shape:
  //             RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //       ),
  //     );
  //   } finally {
  //     if (mounted) setState(() => _loading = false);
  //   }
  // }//

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = ref.watch(currentUserProvider);
    final postsAsync = ref.watch(postsPaginationProvider);
    final authUser = ref.watch(authStateProvider).value;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        elevation: 0,
        title: Text(
          'Mon profil',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: isDark ? AppColors.textLight : AppColors.textDark,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(CupertinoIcons.back,
              color: isDark ? AppColors.textLight : AppColors.textDark),
        ),
        actions: [
          IconButton(
            onPressed: () {
              currentUser.whenData((user) {
                _usernameController.text = user?.username ?? '';
                _bioController.text = user?.bio ?? '';
              });
              setState(() => _editing = !_editing);
            },
            icon: Icon(
              _editing ? CupertinoIcons.xmark : CupertinoIcons.pencil,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
      body: currentUser.when(
        data: (user) {
          return SingleChildScrollView(
            child: Column(
              children: [
                // Header profil
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Photo
                      GestureDetector(
                        onTap: _editing ? _pickPhoto : null,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 48,
                              backgroundColor: AppColors.primary,
                              backgroundImage: _newPhoto != null
                                  ? FileImage(_newPhoto!)
                                  : user?.photoUrl != null
                                      ? NetworkImage(user!.photoUrl!)
                                          as ImageProvider
                                      : null,
                              child: user?.photoUrl == null && _newPhoto == null
                                  ? Text(
                                      (user?.username ?? 'U')[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w700,
                                      ),
                                    )
                                  : null,
                            ),
                            if (_editing)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.camera_fill,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Username
                      if (_editing)
                        TextField(
                          controller: _usernameController,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            color: isDark
                                ? AppColors.textLight
                                : AppColors.textDark,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Nom d\'utilisateur',
                            hintStyle:
                                const TextStyle(color: AppColors.textGrey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        )
                      else
                        Text(
                          user?.username ?? 'User',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 22,
                            color: isDark
                                ? AppColors.textLight
                                : AppColors.textDark,
                          ),
                        ),

                      const SizedBox(height: 8),

                      // Bio
                      if (_editing)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: TextField(
                            controller: _bioController,
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              color: isDark
                                  ? AppColors.textLight
                                  : AppColors.textDark,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Ta bio...',
                              hintStyle:
                                  const TextStyle(color: AppColors.textGrey),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        )
                      else if (user?.bio != null && user!.bio!.isNotEmpty)
                        Text(
                          user.bio!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: AppColors.textGrey,
                          ),
                        ),

                      const SizedBox(height: 8),

                      Text(
                        user?.email ?? '',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: AppColors.textGrey,
                        ),
                      ),

                      // Bouton sauvegarder
                      if (_editing)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _loading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : const Text(
                                      'Sauvegarder',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const Divider(),

                // Posts de l'user
                postsAsync.when(
                  data: (posts) {
                    final myPosts =
                        posts.where((p) => p.userId == authUser?.uid).toList();

                    if (myPosts.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(CupertinoIcons.photo,
                                size: 48, color: AppColors.textGrey),
                            const SizedBox(height: 12),
                            Text(
                              'Aucun post pour le moment',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: AppColors.textGrey,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: myPosts.length,
                      itemBuilder: (context, index) {
                        return PostCard(post: myPosts[index]);
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Erreur : $e')),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
      ),
    );
  }
}
