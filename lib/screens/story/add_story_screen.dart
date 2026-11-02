import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/storage_service.dart';
import '../../services/story_service.dart';

class AddStoryScreen extends ConsumerStatefulWidget {
  const AddStoryScreen({super.key});

  @override
  ConsumerState<AddStoryScreen> createState() => _AddStoryScreenState();
}

class _AddStoryScreenState extends ConsumerState<AddStoryScreen> {
  final _textController = TextEditingController();
  List<File> _imageFiles = [];
  bool _loading = false;
  int _selectedDuration = 24;
  int _selectedBg = 0;
  bool _isTextMode = false;

  final List<int> _durations = [12, 24, 48];

  final List<Map<String, dynamic>> _backgrounds = [
    {'name': 'Défaut', 'gradient': null, 'color': null},
    {
      'name': 'Noche',
      'gradient': [const Color(0xFF6C63FF), const Color(0xFF3B36CC)],
      'color': null
    },
    {
      'name': 'Sunset',
      'gradient': [const Color(0xFFFF6B6B), const Color(0xFFFFE66D)],
      'color': null
    },
    {
      'name': 'Ocean',
      'gradient': [const Color(0xFF00B4DB), const Color(0xFF0083B0)],
      'color': null
    },
    {
      'name': 'Forest',
      'gradient': [const Color(0xFF11998E), const Color(0xFF38EF7D)],
      'color': null
    },
    {
      'name': 'Rose',
      'gradient': [const Color(0xFFFF416C), const Color(0xFFFF4B2B)],
      'color': null
    },
    {
      'name': 'Purple',
      'gradient': [const Color(0xFF8E2DE2), const Color(0xFF4A00E0)],
      'color': null
    },
    {
      'name': 'Gold',
      'gradient': [const Color(0xFFF7971E), const Color(0xFFFFD200)],
      'color': null
    },
    {'name': 'Noir', 'gradient': null, 'color': const Color(0xFF0D0D0D)},
    {'name': 'Blanc', 'gradient': null, 'color': const Color(0xFFFFFFFF)},
  ];

  String _getBgString() {
    final bg = _backgrounds[_selectedBg];
    if (bg['gradient'] != null) {
      final colors = bg['gradient'] as List<Color>;
      return 'gradient:${colors[0].value}:${colors[1].value}';
    } else if (bg['color'] != null) {
      return 'color:${(bg['color'] as Color).value}';
    }
    return '';
  }

  BoxDecoration _getPreviewDecoration() {
    final bg = _backgrounds[_selectedBg];
    if (bg['gradient'] != null) {
      final colors = bg['gradient'] as List<Color>;
      return BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    } else if (bg['color'] != null) {
      return BoxDecoration(color: bg['color'] as Color);
    }
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          AppColors.primary.withOpacity(0.15),
          AppColors.primary.withOpacity(0.05),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }

  Color _getTextColor() {
    final bg = _backgrounds[_selectedBg];
    if (bg['color'] == const Color(0xFFFFFFFF)) return AppColors.textDark;
    if (bg['gradient'] != null || bg['color'] != null) return Colors.white;
    return AppColors.primary;
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        _imageFiles = picked.map((e) => File(e.path)).toList();
        _isTextMode = false;
      });
    }
  }

  Future<void> _publish() async {
    if (_imageFiles.isEmpty && _textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Ajoute une image ou du texte'),
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
      final userProfile = await ref.read(currentUserProvider.future);
      final storyService = StoryService();

      // Supprimer les stories expirées
      await storyService.deleteExpiredStories();

      if (_imageFiles.isNotEmpty) {
        // Publier plusieurs stories image
        final storageService = StorageService();
        for (final file in _imageFiles) {
          final imageUrl = await storageService.uploadPostImage(file, user.uid);
          await storyService.createStory(
            userId: user.uid,
            username: userProfile?.username ?? 'User',
            userPhotoUrl: userProfile?.photoUrl,
            imageUrl: imageUrl,
            text: _textController.text.trim().isNotEmpty
                ? _textController.text.trim()
                : null,
            duration: _selectedDuration,
          );
        }
      } else {
        // Story texte
        await storyService.createStory(
          userId: user.uid,
          username: userProfile?.username ?? 'User',
          userPhotoUrl: userProfile?.photoUrl,
          text: _textController.text.trim(),
          textBackground: _getBgString(),
          duration: _selectedDuration,
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
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
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(CupertinoIcons.xmark,
              color: isDark ? AppColors.textLight : AppColors.textDark),
        ),
        title: Text(
          'Nouvelle story',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textLight : AppColors.textDark,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _loading ? null : _publish,
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
      body: Column(
        children: [
          // Sélecteur durée
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Text(
                  'Durée :',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textLight : AppColors.textDark,
                  ),
                ),
                const SizedBox(width: 12),
                ..._durations.map((d) => GestureDetector(
                      onTap: () => setState(() => _selectedDuration = d),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: _selectedDuration == d
                              ? AppColors.primary
                              : AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${d}h',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: _selectedDuration == d
                                ? Colors.white
                                : AppColors.primary,
                          ),
                        ),
                      ),
                    )),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Boutons mode
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_isTextMode
                            ? AppColors.primary
                            : AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.photo,
                              color: !_isTextMode
                                  ? Colors.white
                                  : AppColors.primary,
                              size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Photo',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              color: !_isTextMode
                                  ? Colors.white
                                  : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isTextMode = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isTextMode
                            ? AppColors.primary
                            : AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.text_bubble,
                              color: _isTextMode
                                  ? Colors.white
                                  : AppColors.primary,
                              size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Texte',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              color: _isTextMode
                                  ? Colors.white
                                  : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Preview
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _imageFiles.isNotEmpty
                  ? GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                      ),
                      itemCount: _imageFiles.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _imageFiles.length) {
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
                              child: const Icon(CupertinoIcons.add,
                                  color: AppColors.primary, size: 32),
                            ),
                          );
                        }
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(_imageFiles[index],
                                  fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _imageFiles.removeAt(index)),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(CupertinoIcons.xmark,
                                      color: Colors.white, size: 12),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    )
                  : _isTextMode
                      ? Container(
                          width: double.infinity,
                          decoration: _getPreviewDecoration().copyWith(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.all(24),
                          child: TextField(
                            controller: _textController,
                            maxLines: null,
                            autofocus: true,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: _getTextColor(),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Écris ta story...',
                              hintStyle: TextStyle(
                                fontFamily: 'Poppins',
                                color: _getTextColor().withOpacity(0.5),
                                fontSize: 20,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        )
                      : GestureDetector(
                          onTap: _pickImages,
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkCard
                                  : AppColors.lightCard,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(CupertinoIcons.photo_on_rectangle,
                                    size: 64, color: AppColors.primary),
                                const SizedBox(height: 16),
                                Text(
                                  'Appuie pour choisir des photos',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: AppColors.textGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
            ),
          ),

          // Sélecteur background (mode texte)
          if (_isTextMode)
            Container(
              height: 72,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _backgrounds.length,
                itemBuilder: (context, index) {
                  final bg = _backgrounds[index];
                  final isSelected = _selectedBg == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedBg = index),
                    child: Container(
                      width: 42,
                      height: 42,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: bg['gradient'] != null
                            ? LinearGradient(
                                colors: bg['gradient'] as List<Color>,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: bg['color'] as Color? ??
                            (bg['gradient'] == null
                                ? AppColors.primary.withOpacity(0.15)
                                : null),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(CupertinoIcons.checkmark,
                              color: Colors.white, size: 16)
                          : null,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
