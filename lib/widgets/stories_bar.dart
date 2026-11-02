import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_transitions.dart';
import '../models/story_model.dart';
import '../providers/auth_provider.dart';
import '../services/story_service.dart';
import '../screens/story/add_story_screen.dart';
import '../screens/story/story_viewer_screen.dart';

final storiesProvider =
    StreamProvider<Map<String, List<StoryModel>>>((ref) {
  return StoryService().getGroupedStoriesStream();
});

class StoriesBar extends ConsumerWidget {
  const StoriesBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUserId = ref.watch(authStateProvider).value?.uid ?? '';
    final storiesAsync = ref.watch(storiesProvider);

    return SizedBox(
      height: 110,
      child: storiesAsync.when(
        data: (grouped) {
          final userIds = grouped.keys.toList();

          // Trier : stories non vues en premier
          userIds.sort((a, b) {
            final aViewed = grouped[a]!
                .every((s) => s.viewedBy.contains(currentUserId));
            final bViewed = grouped[b]!
                .every((s) => s.viewedBy.contains(currentUserId));
            if (aViewed && !bViewed) return 1;
            if (!aViewed && bViewed) return -1;
            return 0;
          });

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: userIds.length + 1,
            itemBuilder: (context, index) {
              // Bouton ajouter story
              if (index == 0) {
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    AppTransitions.slideUp(const AddStoryScreen()),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 70,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkCard
                                : AppColors.lightCard,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.4),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.15),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            CupertinoIcons.add,
                            color: AppColors.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Ma story',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.textLight
                                : AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final userId = userIds[index - 1];
              final stories = grouped[userId]!;
              final firstStory = stories.first;
              final allViewed = stories
                  .every((s) => s.viewedBy.contains(currentUserId));
              final isMe = userId == currentUserId;

              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  AppTransitions.fadeScale(
                    StoryViewerScreen(stories: stories),
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  width: 70,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: allViewed
                              ? null
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFF6C63FF),
                                    Color(0xFFFF416C),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                          color: allViewed
                              ? AppColors.textGrey.withOpacity(0.3)
                              : null,
                          boxShadow: allViewed
                              ? []
                              : [
                                  BoxShadow(
                                    color:
                                        AppColors.primary.withOpacity(0.3),
                                    blurRadius: 8,
                                  ),
                                ],
                        ),
                        padding: const EdgeInsets.all(3),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? AppColors.darkBackground
                                : AppColors.lightBackground,
                          ),
                          padding: const EdgeInsets.all(2),
                          child: CircleAvatar(
                            radius: 26,
                            backgroundColor: AppColors.primary,
                            backgroundImage: firstStory.userPhotoUrl != null
                                ? CachedNetworkImageProvider(
                                    firstStory.userPhotoUrl!)
                                : null,
                            child: firstStory.userPhotoUrl == null
                                ? Text(
                                    firstStory.username[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 68,
                        child: Text(
                          isMe ? 'Ma story' : firstStory.username,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: allViewed
                                ? FontWeight.normal
                                : FontWeight.w600,
                            color: allViewed
                                ? AppColors.textGrey
                                : (isDark
                                    ? AppColors.textLight
                                    : AppColors.textDark),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },

        // Shimmer loading
        loading: () => ListView.builder(
          scrollDirection: Axis.horizontal,
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: 6,
          itemBuilder: (context, index) => _StoryShimmer(isDark: isDark),
        ),

        error: (e, _) => ListView.builder(
          scrollDirection: Axis.horizontal,
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: 1,
          itemBuilder: (context, index) => GestureDetector(
            onTap: () => Navigator.push(
              context,
              AppTransitions.slideUp(const AddStoryScreen()),
            ),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              width: 70,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color:
                          isDark ? AppColors.darkCard : AppColors.lightCard,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.4),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      CupertinoIcons.add,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ma story',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color:
                          isDark ? AppColors.textLight : AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StoryShimmer extends StatefulWidget {
  final bool isDark;
  const _StoryShimmer({required this.isDark});

  @override
  State<_StoryShimmer> createState() => _StoryShimmerState();
}

class _StoryShimmerState extends State<_StoryShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final color = widget.isDark
            ? Colors.white.withOpacity(_animation.value * 0.2)
            : Colors.black.withOpacity(_animation.value * 0.1);

        return Container(
          margin: const EdgeInsets.only(right: 12),
          width: 70,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 50,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}