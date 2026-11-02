import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_transitions.dart';
import '../../models/friend_request_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/friend_service.dart';
import '../chat/chat_screen.dart';
import '../profile/user_profile_screen.dart';

final friendServiceProvider = Provider<FriendService>((ref) => FriendService());

final pendingRequestsProvider =
    StreamProvider.family<List<FriendRequestModel>, String>((ref, userId) {
  return ref.read(friendServiceProvider).getPendingRequestsStream(userId);
});

final friendsListProvider =
    StreamProvider.family<List<UserModel>, String>((ref, userId) {
  return ref.read(friendServiceProvider).getFriendsStream(userId);
});

class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = ref.watch(authStateProvider).value;
    if (currentUser == null) return const SizedBox();

    final pendingAsync = ref.watch(pendingRequestsProvider(currentUser.uid));
    final friendsAsync = ref.watch(friendsListProvider(currentUser.uid));

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
          'Amis',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: isDark ? AppColors.textLight : AppColors.textDark,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Demandes en attente
            pendingAsync.when(
              data: (requests) {
                if (requests.isEmpty) return const SizedBox();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          Text(
                            'Demandes d\'amis',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: isDark
                                  ? AppColors.textLight
                                  : AppColors.textDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${requests.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        final request = requests[index];
                        return _RequestCard(
                          request: request,
                          isDark: isDark,
                        );
                      },
                    ),
                    const Divider(),
                  ],
                );
              },
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),

            // Liste d'amis
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Mes amis',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: isDark ? AppColors.textLight : AppColors.textDark,
                ),
              ),
            ),
            friendsAsync.when(
              data: (friends) {
                if (friends.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(CupertinoIcons.person_2,
                              size: 48, color: AppColors.textGrey),
                          const SizedBox(height: 12),
                          Text(
                            'Aucun ami pour le moment',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: AppColors.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: friends.length,
                  itemBuilder: (context, index) {
                    final friend = friends[index];
                    return ListTile(
                      onTap: () => Navigator.push(
                        context,
                        AppTransitions.slideRight(
                          UserProfileScreen(userId: friend.uid),
                        ),
                      ),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primary,
                        backgroundImage: friend.photoUrl != null
                            ? CachedNetworkImageProvider(friend.photoUrl!)
                            : null,
                        child: friend.photoUrl == null
                            ? Text(
                                friend.username[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            : null,
                      ),
                      title: Text(
                        friend.username,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          color:
                              isDark ? AppColors.textLight : AppColors.textDark,
                        ),
                      ),
                      subtitle: friend.bio != null && friend.bio!.isNotEmpty
                          ? Text(
                              friend.bio!,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                color: AppColors.textGrey,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                      trailing: Consumer(
                        builder: (context, ref, _) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  AppTransitions.slideRight(
                                    ChatScreen(friend: friend),
                                  ),
                                );
                              },
                              icon: const Icon(
                                CupertinoIcons.chat_bubble_fill,
                                color: AppColors.primary,
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                await ref
                                    .read(friendServiceProvider)
                                    .removeFriend(currentUser.uid, friend.uid);
                              },
                              child: const Text(
                                'Retirer',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Colors.redAccent,
                                  fontSize: 13,
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
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur : $e')),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestCard extends ConsumerWidget {
  final FriendRequestModel request;
  final bool isDark;

  const _RequestCard({required this.request, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary,
            backgroundImage: request.senderPhotoUrl != null
                ? CachedNetworkImageProvider(request.senderPhotoUrl!)
                : null,
            child: request.senderPhotoUrl == null
                ? Text(
                    request.senderUsername[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              request.senderUsername,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textLight : AppColors.textDark,
              ),
            ),
          ),
          // Accepter
          GestureDetector(
            onTap: () async {
              await ref
                  .read(friendServiceProvider)
                  .acceptFriendRequest(request.id);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Accepter',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Refuser
          GestureDetector(
            onTap: () async {
              await ref
                  .read(friendServiceProvider)
                  .rejectFriendRequest(request.id);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.textGrey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Refuser',
                style: TextStyle(
                  color: AppColors.textGrey,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
