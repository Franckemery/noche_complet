import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../core/constants/app_colors.dart';
import '../models/post_model.dart';
import '../providers/auth_provider.dart';
import '../providers/post_provider.dart';
import '../screens/home/image_viewer_screen.dart';
import '../screens/home/comments_screen.dart';
import '../core/constants/app_transitions.dart';
import '../screens/profile/user_profile_screen.dart';

class PostCard extends ConsumerWidget {
  final PostModel post;

  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postAsync = ref.watch(postStreamProvider(post.id));
    final livePost = postAsync.value ?? post;

    final authState = ref.watch(authStateProvider);
    final currentUserId = authState.value?.uid ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLiked = livePost.likes.contains(currentUserId);
    final isOwner = livePost.userId == currentUserId;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      AppTransitions.slideRight(
                        UserProfileScreen(userId: livePost.userId),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundImage: livePost.userPhotoUrl != null
                            ? CachedNetworkImageProvider(livePost.userPhotoUrl!)
                            : null,
                        backgroundColor: AppColors.primary,
                        child: livePost.userPhotoUrl == null
                            ? Text(
                                livePost.username[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            livePost.username,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: isDark
                                  ? AppColors.textLight
                                  : AppColors.textDark,
                            ),
                          ),
                          Text(
                            timeago.format(livePost.createdAt, locale: 'fr'),
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: AppColors.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (isOwner)
                  PopupMenuButton<String>(
                    icon: const Icon(CupertinoIcons.ellipsis,
                        color: AppColors.textGrey, size: 20),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    onSelected: (value) async {
                      if (value == 'delete') {
                        await ref
                            .read(postNotifierProvider.notifier)
                            .deletePost(livePost.id);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(CupertinoIcons.trash,
                                color: Colors.redAccent, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Supprimer',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Image OU Texte
          if (livePost.imageUrls.length > 1)
            _MultiImageGrid(imageUrls: livePost.imageUrls)
          else if (livePost.imageUrl.isNotEmpty)
            GestureDetector(
              onTap: () {
                Navigator.push(
                    context,
                    AppTransitions.fadeScale(
                        ImageViewerScreen(imageUrl: livePost.imageUrl)));
              },
              child: ClipRRect(
                child: SizedBox(
                  height: 300,
                  width: double.infinity,
                  child: CachedNetworkImage(
                    imageUrl: livePost.imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 300,
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 300,
                      color: AppColors.textGrey,
                      child: const Icon(Icons.error),
                    ),
                  ),
                ),
              ),
            )
          else
            _TextPostWidget(
              text: livePost.caption ?? '',
              isDark: isDark,
              textBackground: livePost.textBackground,
            ),

          // Caption uniquement si post image
          if (livePost.imageUrl.isNotEmpty &&
              livePost.caption != null &&
              livePost.caption!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${livePost.username} ',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color:
                            isDark ? AppColors.textLight : AppColors.textDark,
                      ),
                    ),
                    TextSpan(
                      text: livePost.caption,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color:
                            isDark ? AppColors.textLight : AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Like
                GestureDetector(
                  onTap: () async {
                    await ref
                        .read(postNotifierProvider.notifier)
                        .toggleLike(livePost.id, currentUserId);
                  },
                  child: Row(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, anim) =>
                            ScaleTransition(scale: anim, child: child),
                        child: Icon(
                          isLiked
                              ? CupertinoIcons.heart_fill
                              : CupertinoIcons.heart,
                          key: ValueKey(isLiked),
                          color:
                              isLiked ? Colors.redAccent : AppColors.textGrey,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${livePost.likes.length}',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color:
                              isDark ? AppColors.textLight : AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 20),

                // Commentaire
                GestureDetector(
                  onTap: () {
                    Navigator.push(context,
                        AppTransitions.slideUp(CommentsScreen(post: livePost)));
                  },
                  child: Row(
                    children: [
                      const Icon(
                        CupertinoIcons.chat_bubble_fill,
                        color: AppColors.textGrey,
                        size: 23,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${livePost.commentsCount}',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          color:
                              isDark ? AppColors.textLight : AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Partage
                GestureDetector(
                  onTap: () {
                    //variable non utiliser

                    
                    // final text = livePost.caption != null &&
                    //         livePost.caption!.isNotEmpty
                    //     ? '${livePost.username} : ${livePost.caption}'
                    //     : '${livePost.username} a partagé une image sur Noche <';

                    // else {
                    //   Share.share(text);
                    // }
                  },
                  child: const Icon(
                    Icons.share,
                    color: AppColors.textGrey,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _MultiImageGrid extends StatelessWidget {
  final List<String> imageUrls;

  const _MultiImageGrid({required this.imageUrls});

  @override
  Widget build(BuildContext context) {
    final count = imageUrls.length;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _MultiImageViewer(imageUrls: imageUrls),
          ),
        );
      },
      child: SizedBox(
        height: 300,
        child: count == 2
            ? Row(
                children: [
                  Expanded(child: _GridImage(url: imageUrls[0])),
                  const SizedBox(width: 2),
                  Expanded(child: _GridImage(url: imageUrls[1])),
                ],
              )
            : count == 3
                ? Row(
                    children: [
                      Expanded(child: _GridImage(url: imageUrls[0])),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(child: _GridImage(url: imageUrls[1])),
                            const SizedBox(height: 2),
                            Expanded(child: _GridImage(url: imageUrls[2])),
                          ],
                        ),
                      ),
                    ],
                  )
                : GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                    ),
                    itemCount: count > 4 ? 4 : count,
                    itemBuilder: (context, index) {
                      if (index == 3 && count > 4) {
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            _GridImage(url: imageUrls[3]),
                            Container(
                              color: Colors.black54,
                              child: Center(
                                child: Text(
                                  '+${count - 4}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                      return _GridImage(url: imageUrls[index]);
                    },
                  ),
      ),
    );
  }
}

class _GridImage extends StatelessWidget {
  final String url;

  const _GridImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: AppColors.textGrey.withOpacity(0.2),
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => Container(
        color: AppColors.textGrey,
        child: const Icon(Icons.error),
      ),
    );
  }
}

class _MultiImageViewer extends StatefulWidget {
  final List<String> imageUrls;

  const _MultiImageViewer({required this.imageUrls});

  @override
  State<_MultiImageViewer> createState() => _MultiImageViewerState();
}

class _MultiImageViewerState extends State<_MultiImageViewer> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(CupertinoIcons.xmark, color: Colors.white),
        ),
        title: Text(
          '${_currentIndex + 1} / ${widget.imageUrls.length}',
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: PageView.builder(
        itemCount: widget.imageUrls.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: CachedNetworkImage(
              imageUrl: widget.imageUrls[index],
              fit: BoxFit.contain,
              placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: Colors.white)),
              errorWidget: (context, url, error) =>
                  const Icon(Icons.error, color: Colors.white),
            ),
          );
        },
      ),
    );
  }
}

class _TextPostWidget extends StatefulWidget {
  final String text;
  final bool isDark;
  final String? textBackground;

  const _TextPostWidget({
    required this.text,
    required this.isDark,
    this.textBackground,
  });

  @override
  State<_TextPostWidget> createState() => _TextPostWidgetState();
}

class _TextPostWidgetState extends State<_TextPostWidget> {
  bool _expanded = false;
  static const int _maxLines = 5;

  BoxDecoration _getDecoration() {
    final bg = widget.textBackground;
    if (bg != null && bg.startsWith('gradient:')) {
      final parts = bg.split(':');
      final color1 = Color(int.parse(parts[1]));
      final color2 = Color(int.parse(parts[2]));
      return BoxDecoration(
        gradient: LinearGradient(
          colors: [color1, color2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    } else if (bg != null && bg.startsWith('color:')) {
      final parts = bg.split(':');
      return BoxDecoration(color: Color(int.parse(parts[1])));
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
    final bg = widget.textBackground;
    if (bg != null && bg.startsWith('color:')) {
      final parts = bg.split(':');
      final color = Color(int.parse(parts[1]));
      if (color == const Color(0xFFFFFFFF)) return AppColors.textDark;
      return Colors.white;
    }
    if (bg != null && bg.startsWith('gradient:')) {
      return Colors.white;
    }
    return widget.isDark ? AppColors.textLight : AppColors.textDark;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 120),
      padding: const EdgeInsets.all(20),
      decoration: _getDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.text,
            textAlign: TextAlign.center,
            maxLines: _expanded ? null : _maxLines,
            overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _getTextColor(),
              height: 1.5,
            ),
          ),
          if (widget.text.length > 200)
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _expanded ? 'Voir moins' : 'Voir plus',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: _getTextColor().withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
