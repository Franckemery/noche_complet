import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noche/providers/user_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/post_card.dart';
import '../../services/friend_service.dart';

final userProfileProvider =
    FutureProvider.family<UserModel?, String>((ref, userId) async {
  final doc =
      await FirebaseFirestore.instance.collection('users').doc(userId).get();
  if (!doc.exists) return null;
  return UserModel.fromMap(doc.data()!);
});

final userPostsProvider =
    StreamProvider.family<List<PostModel>, String>((ref, userId) {
  return FirebaseFirestore.instance
      .collection('posts')
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) =>
          snap.docs.map((doc) => PostModel.fromMap(doc.data())).toList());
});

final friendStatusProvider =
    FutureProvider.family<String, Map<String, String>>((ref, params) async {
  return FriendService().getFriendStatus(
    currentUserId: params['currentUserId']!,
    otherUserId: params['otherUserId']!,
  );
});

class UserProfileScreen extends ConsumerWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userAsync = ref.watch(userProfileProvider(userId));
    final postsAsync = ref.watch(userPostsProvider(userId));
    final currentUserId = ref.watch(authStateProvider).value?.uid ?? '';
    final isMe = currentUserId == userId;

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
        title: userAsync.when(
          data: (user) => Text(
            user?.username ?? 'Profil',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: isDark ? AppColors.textLight : AppColors.textDark,
            ),
          ),
          loading: () => const SizedBox(),
          error: (_, __) => const SizedBox(),
        ),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Utilisateur introuvable'));
          }
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
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: AppColors.primary,
                        backgroundImage: user.photoUrl != null
                            ? CachedNetworkImageProvider(user.photoUrl!)
                            : null,
                        child: user.photoUrl == null
                            ? Text(
                                user.username[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      // Username
                      Text(
                        user.username,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                          color:
                              isDark ? AppColors.textLight : AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Bio
                      if (user.bio != null && user.bio!.isNotEmpty)
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
                      // Email
                      Text(
                        user.email,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: AppColors.textGrey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Stats posts
                      postsAsync.when(
                        data: (posts) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkCard
                                : AppColors.lightCard,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    '${posts.length}',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 20,
                                      color: isDark
                                          ? AppColors.textLight
                                          : AppColors.textDark,
                                    ),
                                  ),
                                  const Text(
                                    'Posts',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 13,
                                      color: AppColors.textGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        loading: () => const SizedBox(),
                        error: (_, __) => const SizedBox(),
                      ),

                      const SizedBox(height: 12),

                      if (!isMe)
                        Consumer(
                          builder: (context, ref, _) {
                            final statusAsync = ref.watch(friendStatusProvider({
                              'currentUserId': currentUserId,
                              'otherUserId': userId,
                            }));

                            return statusAsync.when(
                              data: (status) {
                                if (status == 'friends') {
                                  return OutlinedButton.icon(
                                    onPressed: () async {
                                      await FriendService()
                                          .removeFriend(currentUserId, userId);
                                      ref.invalidate(friendStatusProvider);
                                    },
                                    icon: const Icon(
                                        CupertinoIcons.person_badge_minus,
                                        color: Colors.redAccent),
                                    label: const Text(
                                      'Retirer ami',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                          color: Colors.redAccent),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                  );
                                } else if (status == 'sent') {
                                  return OutlinedButton.icon(
                                    onPressed: null,
                                    icon: const Icon(CupertinoIcons.clock,
                                        color: AppColors.textGrey),
                                    label: const Text(
                                      'Demande envoyée',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        color: AppColors.textGrey,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                          color: AppColors.textGrey),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                  );
                                } else if (status == 'received') {
                                  return ElevatedButton.icon(
                                    onPressed: () async {
                                      final requests = await FirebaseFirestore
                                          .instance
                                          .collection('friend_requests')
                                          .where('senderId', isEqualTo: userId)
                                          .where('receiverId',
                                              isEqualTo: currentUserId)
                                          .where('status', isEqualTo: 'pending')
                                          .get();
                                      if (requests.docs.isNotEmpty) {
                                        await FriendService()
                                            .acceptFriendRequest(
                                                requests.docs.first.id);
                                        ref.invalidate(friendStatusProvider);
                                      }
                                    },
                                    icon: const Icon(
                                        CupertinoIcons.person_badge_plus,
                                        color: Colors.white),
                                    label: const Text(
                                      'Accepter la demande',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        color: Colors.white,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                  );
                                } else {
                                  return ElevatedButton.icon(
                                    onPressed: () async {
                                      final userProfile = await ref
                                          .read(currentUserProvider.future);
                                      await FriendService().sendFriendRequest(
                                        senderId: currentUserId,
                                        senderUsername:
                                            userProfile?.username ?? 'User',
                                        senderPhotoUrl: userProfile?.photoUrl,
                                        receiverId: userId,
                                      );
                                      ref.invalidate(friendStatusProvider);
                                    },
                                    icon: const Icon(
                                        CupertinoIcons.person_badge_plus,
                                        color: Colors.white),
                                    label: const Text(
                                      'Ajouter en ami',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        color: Colors.white,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                  );
                                }
                              },
                              loading: () => const CircularProgressIndicator(),
                              error: (_, __) => const SizedBox(),
                            );
                          },
                        ),
                    ],
                  ),
                ),

                const Divider(),

                // Posts
                postsAsync.when(
                  data: (posts) {
                    if (posts.isEmpty) {
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
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        return PostCard(post: posts[index]);
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
