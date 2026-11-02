import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:noche/widgets/post_shimmer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_transitions.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/post_card.dart';
import '../../widgets/stories_bar.dart';
import 'add_post_screen.dart';
import 'add_text_post_screen.dart';
import 'favorites_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'search_screen.dart';
import '../profile/profile_screen.dart';
import '../friends/friends_screen.dart';
import '../../services/friend_service.dart';
import '../../models/user_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../profile/user_profile_screen.dart';
import '../home/explorer_screen.dart';

final friendSuggestionsProvider =
    FutureProvider.family<List<UserModel>, String>((ref, userId) async {
  final firestore = FirebaseFirestore.instance;
  final userDoc = await firestore.collection('users').doc(userId).get();
  final friends = List<String>.from(userDoc.data()?['friends'] ?? []);
  friends.add(userId);
  final snapshot = await firestore.collection('users').limit(20).get();
  return snapshot.docs
      .map((doc) => UserModel.fromMap(doc.data()))
      .where((user) => !friends.contains(user.uid))
      .take(10)
      .toList();
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scrollController = ScrollController();
  final _refreshKey = GlobalKey<LiquidPullToRefreshState>();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(postsPaginationProvider.notifier).loadMore();
    }
  }

  Future<void> _refresh() async {
    await ref.read(postsPaginationProvider.notifier).loadInitial();
  }

  void refresh() {
    _refreshKey.currentState?.show();
  }

  Widget _buildSuggestions(
    BuildContext context,
    List<UserModel> suggestions,
    String currentUserId,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            'Personnes que vous pourriez connaître',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: isDark ? AppColors.textLight : AppColors.textDark,
            ),
          ),
        ),
        SizedBox(
          height: 170,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: suggestions.length,
            itemBuilder: (context, i) {
              final user = suggestions[i];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  AppTransitions.slideRight(
                      UserProfileScreen(userId: user.uid)),
                ),
                child: Container(
                  width: 110,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.primary,
                        backgroundImage: user.photoUrl != null
                            ? CachedNetworkImageProvider(user.photoUrl!)
                            : null,
                        child: user.photoUrl == null
                            ? Text(
                                user.username[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 20,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          user.username,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textLight
                                : AppColors.textDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () async {
                          final userProfile =
                              await ref.read(currentUserProvider.future);
                          await FriendService().sendFriendRequest(
                            senderId: currentUserId,
                            senderUsername: userProfile?.username ?? 'User',
                            senderPhotoUrl: userProfile?.photoUrl,
                            receiverId: user.uid,
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Demande envoyée à ${user.username}',
                                style: const TextStyle(fontFamily: 'Poppins'),
                              ),
                              backgroundColor: AppColors.primary,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Ajouter',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        const Divider(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final postsAsync = ref.watch(postsPaginationProvider);
    final currentUser = ref.watch(currentUserProvider);
    final currentUserId = ref.watch(authStateProvider).value?.uid ?? '';
    final suggestionsAsync =
        ref.watch(friendSuggestionsProvider(currentUserId));

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      drawer: Drawer(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                color: AppColors.primary.withOpacity(0.1),
                child: currentUser.when(
                  data: (user) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: AppColors.primary,
                        backgroundImage: user?.photoUrl != null
                            ? NetworkImage(user!.photoUrl!)
                            : null,
                        child: user?.photoUrl == null
                            ? Text(
                                (user?.username ?? 'U')[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user?.username ?? 'User',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color:
                              isDark ? AppColors.textLight : AppColors.textDark,
                        ),
                      ),
                      Text(
                        user?.email ?? '',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const SizedBox(),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading:
                    Icon(CupertinoIcons.house_fill, color: AppColors.primary),
                title: Text('Accueil',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.textLight : AppColors.textDark,
                    )),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: Icon(CupertinoIcons.search, color: AppColors.primary),
                title: Text('Recherche',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.textLight : AppColors.textDark,
                    )),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context, AppTransitions.slideRight(const SearchScreen()));
                },
              ),
              ListTile(
                leading:
                    Icon(CupertinoIcons.flame_fill, color: AppColors.primary),
                title: Text('Explorer',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                        color:
                            isDark ? AppColors.textLight : AppColors.textDark)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context,
                      AppTransitions.slideRight(const ExplorerScreen()));
                },
              ),
              ListTile(
                leading:
                    Icon(CupertinoIcons.person_fill, color: AppColors.primary),
                title: Text('Mon profil',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.textLight : AppColors.textDark,
                    )),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context,
                      AppTransitions.slideRight(const ProfileScreen()));
                },
              ),
              ListTile(
                leading: Icon(CupertinoIcons.person_2_fill,
                    color: AppColors.primary),
                title: Text('Mes amis',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.textLight : AppColors.textDark,
                    )),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context,
                      AppTransitions.slideRight(const FriendsScreen()));
                },
              ),
              ListTile(
                leading:
                    Icon(CupertinoIcons.heart_fill, color: AppColors.primary),
                title: Text('Mes favoris',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.textLight : AppColors.textDark,
                    )),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context,
                      AppTransitions.slideRight(const FavoritesScreen()));
                },
              ),
              ListTile(
                leading: Icon(
                  ref.watch(themeProvider) == ThemeMode.dark
                      ? CupertinoIcons.sun_max_fill
                      : CupertinoIcons.moon_fill,
                  color: AppColors.primary,
                ),
                title: Text(
                  ref.watch(themeProvider) == ThemeMode.dark
                      ? 'Mode clair'
                      : 'Mode sombre',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.textLight : AppColors.textDark,
                  ),
                ),
                onTap: () => ref.read(themeProvider.notifier).toggleTheme(),
              ),
              const Spacer(),
              ListTile(
                leading: const Icon(CupertinoIcons.square_arrow_right,
                    color: Colors.redAccent),
                title: const Text('Se déconnecter',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                      color: Colors.redAccent,
                    )),
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(authNotifierProvider.notifier).signOut();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        elevation: 0,
        title: Row(
          children: [
            Text(
              'Noche',
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
            onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
            icon: Icon(
              ref.watch(themeProvider) == ThemeMode.dark
                  ? CupertinoIcons.sun_max_fill
                  : CupertinoIcons.moon_fill,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
      body: postsAsync.when(
        data: (posts) {
          final hasSuggestions = suggestionsAsync.value != null &&
              suggestionsAsync.value!.isNotEmpty &&
              posts.length > 3;

          // Index layout :
          // 0 = StoriesBar
          // 1..N = posts (avec suggestions insérées à l'index 5)
          // si hasSuggestions ’ index 5 = suggestions, sinon posts normaux
          // dernier index = loader/fin

          // itemCount = 1 (stories) + posts.length + 1 (loader) + hasSuggestions ? 1 : 0
          final itemCount = 1 +
              (posts.isEmpty ? 1 : posts.length) +
              1 +
              (hasSuggestions ? 1 : 0);

          // Index où insérer les suggestions (après le 4ème post = index 5)
          const suggestionsIndex = 5;

          return LiquidPullToRefresh(
            key: _refreshKey,
            color: AppColors.primary,
            backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
            height: 80,
            animSpeedFactor: 2,
            showChildOpacityTransition: false,
            onRefresh: _refresh,
            child: ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: itemCount,
              padding: const EdgeInsets.only(bottom: 16),
              itemBuilder: (context, index) {
                // Index 0 = StoriesBar
                if (index == 0) {
                  return Column(
                    children: [
                      const StoriesBar(),
                      const Divider(height: 1),
                    ],
                  );
                }

                // Liste vide
                if (posts.isEmpty && index == 1) {
                  return SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.photo,
                              size: 64, color: AppColors.textGrey),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun post pour le moment',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              color: AppColors.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Suggestions après le 4ème post
                if (hasSuggestions && index == suggestionsIndex) {
                  return _buildSuggestions(
                    context,
                    suggestionsAsync.value!,
                    currentUserId,
                    isDark,
                  );
                }

                // Calculer le vrai index du post
                // index 1 = post 0, index 2 = post 1, etc.
                // Si suggestions insérées à index 5, décaler après
                int postIndex = index - 1;
                if (hasSuggestions && index > suggestionsIndex) {
                  postIndex = index - 2;
                }

                // Loader ou fin de liste
                if (postIndex >= posts.length) {
                  return ref.read(postsPaginationProvider.notifier).hasMore
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: Text(
                              'Plus aucun post <',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: AppColors.textGrey,
                              ),
                            ),
                          ),
                        );
                }

                if (postIndex < 0) return const SizedBox();
                return PostCard(post: posts[postIndex]);
              },
            ),
          );
        },
        loading: () => ListView.builder(
          itemCount: 6,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Column(
                children: [
                  const SizedBox(height: 100),
                  const Divider(height: 1),
                ],
              );
            }
            return const PostShimmer();
          },
        ),
        error: (e, _) => Center(child: Text('Erreur : $e')),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'text',
            onPressed: () {
              Navigator.push(
                context,
                AppTransitions.slideUp(const AddTextPostScreen()),
              );
            },
            backgroundColor: AppColors.primary,
            child: const Icon(CupertinoIcons.text_bubble, color: Colors.white),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'image',
            onPressed: () {
              Navigator.push(
                context,
                AppTransitions.slideUp(const AddPostScreen()),
              );
            },
            backgroundColor: AppColors.primary,
            child: const Icon(CupertinoIcons.photo, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
