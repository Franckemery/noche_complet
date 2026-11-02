import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import '../../providers/user_provider.dart';

class AddTextPostScreen extends ConsumerStatefulWidget {
  const AddTextPostScreen({super.key});

  @override
  ConsumerState<AddTextPostScreen> createState() => _AddTextPostScreenState();
}

class _AddTextPostScreenState extends ConsumerState<AddTextPostScreen> {
  final _textController = TextEditingController();
  bool _loading = false;
  int _selectedBg = 0;

  final List<Map<String, dynamic>> _backgrounds = [
    {
      'name': 'Défaut',
      'gradient': null,
      'color': null,
    },
    {
      'name': 'Noche',
      'gradient': [const Color(0xFF6C63FF), const Color(0xFF3B36CC)],
      'color': null,
    },
    {
      'name': 'Sunset',
      'gradient': [const Color(0xFFFF6B6B), const Color(0xFFFFE66D)],
      'color': null,
    },
    {
      'name': 'Ocean',
      'gradient': [const Color(0xFF00B4DB), const Color(0xFF0083B0)],
      'color': null,
    },
    {
      'name': 'Forest',
      'gradient': [const Color(0xFF11998E), const Color(0xFF38EF7D)],
      'color': null,
    },
    {
      'name': 'Rose',
      'gradient': [const Color(0xFFFF416C), const Color(0xFFFF4B2B)],
      'color': null,
    },
    {
      'name': 'Purple',
      'gradient': [const Color(0xFF8E2DE2), const Color(0xFF4A00E0)],
      'color': null,
    },
    {
      'name': 'Gold',
      'gradient': [const Color(0xFFF7971E), const Color(0xFFFFD200)],
      'color': null,
    },
    {
      'name': 'Noir',
      'gradient': null,
      'color': const Color(0xFF0D0D0D),
    },
    {
      'name': 'Blanc',
      'gradient': null,
      'color': const Color(0xFFFFFFFF),
    },
  ];

  String _getBgString() {
    final bg = _backgrounds[_selectedBg];
    if (bg['gradient'] != null) {
      final colors = bg['gradient'] as List<Color>;
      return 'gradient:${colors[0].toARGB32()}:${colors[1].toARGB32()}';
    } else if (bg['color'] != null) {
      return 'color:${(bg['color'] as Color).toARGB32()}';
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
    if (bg['color'] == const Color(0xFFFFFFFF)) {
      return AppColors.textDark;
    }
    if (bg['gradient'] != null || bg['color'] != null) {
      return Colors.white;
    }
    return AppColors.primary;
  }

  Future<void> _post() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Écris quelque chose d\'abord'),
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

      await ref.read(postNotifierProvider.notifier).createPost(
            userId: user.uid,
            username: userProfile?.username ?? 'User',
            userPhotoUrl: userProfile?.photoUrl,
            imageUrl: '',
            caption: _textController.text.trim(),
            textBackground: _getBgString(),
          );

      if (!mounted) return;
      Navigator.pop(context);
      ref.read(postsPaginationProvider.notifier).loadInitial();
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
        title: Text(
          'Nouveau texte',
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
      body: Column(
        children: [
          // Preview
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
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
                    height: 1.5,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Quoi de neuf ?',
                    hintStyle: TextStyle(
                      fontFamily: 'Poppins',
                      color: _getTextColor().withOpacity(0.5),
                      fontSize: 20,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ),

          // Sélecteur de backgrounds
          Container(
            height: 80,
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
                    width: 48,
                    height: 48,
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
                        color:
                            isSelected ? AppColors.primary : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.4),
                                blurRadius: 8,
                              )
                            ]
                          : [],
                    ),
                    child: isSelected
                        ? const Icon(
                            CupertinoIcons.checkmark,
                            color: Colors.white,
                            size: 18,
                          )
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
