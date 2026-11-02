import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_transitions.dart';
import '../../models/post_model.dart';
import '../../widgets/post_card.dart';

final explorerPostsProvider =
    FutureProvider<List<PostModel>>((ref) async {
  final snap = await FirebaseFirestore.instance
      .collection('posts')
      .orderBy('likes', descending: true)
      .limit(30)
      .get();

  return snap.docs
      .map((d) => PostModel.fromMap(d.data()))
      .toList();
});

class ExplorerScreen extends ConsumerWidget {
  const ExplorerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final postsAsync = ref.watch(explorerPostsProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(CupertinoIcons.back,
              color: isDark ? AppColors.textLight : AppColors.textDark),
        ),
        title: Row(
          children: [
            const Icon(CupertinoIcons.flame_fill,
                color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Explorer',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: isDark ? AppColors.textLight : AppColors.textDark,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => ref.refresh(explorerPostsProvider),
            icon: const Icon(CupertinoIcons.refresh,
                color: AppColors.primary),
          ),
        ],
      ),
      body: postsAsync.when(
        data: (posts) {
          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.flame,
                      size: 64, color: AppColors.textGrey),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun post populaire pour le moment',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: AppColors.textGrey,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            );
          }

          // Séparer posts image et posts texte
          final imagePosts =
              posts.where((p) => p.imageUrl.isNotEmpty || p.imageUrls.isNotEmpty).toList();
          final textPosts =
              posts.where((p) => p.imageUrl.isEmpty && p.imageUrls.isEmpty).toList();

          return CustomScrollView(
            slivers: [
              // Grille images
              if (imagePosts.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.photo_fill_on_rectangle_fill,
                            color: AppColors.primary, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Posts populaires',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: isDark
                                ? AppColors.textLight
                                : AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final post = imagePosts[index];
                        final imageUrl = post.imageUrls.isNotEmpty
                            ? post.imageUrls.first
                            : post.imageUrl;

                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            AppTransitions.fadeScale(
                              _PostDetailScreen(post: post),
                            ),
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: isDark
                                  ? AppColors.darkCard
                                  : AppColors.lightCard,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: isDark
                                          ? AppColors.darkCard
                                          : AppColors.lightCard,
                                    ),
                                    errorWidget: (context, url, error) =>
                                        const Icon(Icons.error),
                                  ),
                                  // Badge likes
                                  Positioned(
                                    bottom: 6,
                                    left: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                              CupertinoIcons.heart_fill,
                                              color: Colors.white,
                                              size: 12),
                                          const SizedBox(width: 3),
                                          Text(
                                            '${post.likes.length}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontFamily: 'Poppins',
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Badge multi-images
                                  if (post.imageUrls.length > 1)
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          CupertinoIcons.square_stack,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: imagePosts.length,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                    ),
                  ),
                ),
              ],

              // Posts texte populaires
              if (textPosts.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.text_bubble_fill,
                            color: AppColors.primary, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Posts texte populaires',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: isDark
                                ? AppColors.textLight
                                : AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        PostCard(post: textPosts[index]),
                    childCount: textPosts.length,
                  ),
                ),
              ],

              const SliverToBoxAdapter(
                  child: SizedBox(height: 32)),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(child: Text('Erreur : $e')),
      ),
    );
  }
}

class _PostDetailScreen extends StatelessWidget {
  final PostModel post;

  const _PostDetailScreen({required this.post});

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
          icon: Icon(CupertinoIcons.back,
              color: isDark ? AppColors.textLight : AppColors.textDark),
        ),
        title: Text(
          'Post',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textLight : AppColors.textDark,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: PostCard(post: post),
      ),
    );
  }
}