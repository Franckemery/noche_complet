import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import '../../widgets/post_card.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = ref.watch(authStateProvider).value;
    final favoritesAsync = ref.watch(
      favoritePostsStreamProvider(currentUser?.uid ?? ''),
    );

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        elevation: 0,
        title: Text(
          'Mes favoris',
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
      ),
      body: favoritesAsync.when(
        data: (posts) {
          if (posts.isEmpty) {
            return LiquidPullToRefresh(
              color: AppColors.primary,
              backgroundColor:
                  isDark ? AppColors.darkCard : AppColors.lightCard,
              height: 80,
              animSpeedFactor: 2,
              showChildOpacityTransition: false,
              onRefresh: () async {
                ref.invalidate(
                    favoritePostsStreamProvider(currentUser?.uid ?? ''));
              },
              child: ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.heart,
                              size: 64, color: AppColors.textGrey),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun favori pour le moment',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              color: AppColors.textGrey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Like des posts pour les retrouver ici',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              color: AppColors.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return LiquidPullToRefresh(
            color: AppColors.primary,
            backgroundColor:
                isDark ? AppColors.darkCard : AppColors.lightCard,
            height: 80,
            animSpeedFactor: 2,
            showChildOpacityTransition: false,
            onRefresh: () async {
              ref.invalidate(
                  favoritePostsStreamProvider(currentUser?.uid ?? ''));
            },
            child: ListView.builder(
              itemCount: posts.length,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (context, index) {
                return PostCard(post: posts[index]);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
      ),
    );
  }
}