import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../models/story_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/chat_service.dart';
import '../../services/story_service.dart';

class StoryViewerScreen extends ConsumerStatefulWidget {
  final List<StoryModel> stories;
  final int initialIndex;

  const StoryViewerScreen({
    super.key,
    required this.stories,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<StoryViewerScreen> createState() =>
      _StoryViewerScreenState();
}

class _StoryViewerScreenState extends ConsumerState<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  int _currentIndex = 0;
  bool _isPaused = false;
  bool _imageLoaded = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _markAsViewed();
    _loadStory();
  }

  void _loadStory() {
    final story = widget.stories[_currentIndex];
    if (story.isImage) {
      // Attendre que l'image soit chargée
      setState(() => _imageLoaded = false);
    } else {
      // Story texte : démarrer directement
      setState(() => _imageLoaded = true);
      _startProgress();
    }
  }

  void _onImageLoaded() {
    if (!_imageLoaded) {
      setState(() => _imageLoaded = true);
      _startProgress();
    }
  }

  void _startProgress() {
    _progressController.reset();
    _progressController.forward().then((_) {
      if (!_isPaused) _nextStory();
    });
  }

  void _markAsViewed() {
    final userId = ref.read(authStateProvider).value?.uid ?? '';
    if (userId.isNotEmpty) {
      StoryService()
          .markAsViewed(widget.stories[_currentIndex].id, userId);
    }
  }

  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      setState(() {
        _currentIndex++;
        _isPaused = false;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _markAsViewed();
      _loadStory();
    } else {
      Navigator.pop(context);
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _isPaused = false;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _loadStory();
    }
  }

  void _pause() {
    if (!_isPaused) {
      setState(() => _isPaused = true);
      _progressController.stop();
    }
  }

  void _resume() {
    if (_isPaused) {
      setState(() => _isPaused = false);
      _progressController.forward().then((_) {
        if (!_isPaused) _nextStory();
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  BoxDecoration _getTextBgDecoration(String? textBackground) {
    if (textBackground == null || textBackground.isEmpty) {
      return BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.8),
            AppColors.primary.withOpacity(0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    }
    if (textBackground.startsWith('gradient:')) {
      final parts = textBackground.split(':');
      final color1 = Color(int.parse(parts[1]));
      final color2 = Color(int.parse(parts[2]));
      return BoxDecoration(
        gradient: LinearGradient(
          colors: [color1, color2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    } else if (textBackground.startsWith('color:')) {
      final parts = textBackground.split(':');
      return BoxDecoration(color: Color(int.parse(parts[1])));
    }
    return const BoxDecoration(color: Colors.black);
  }

  @override
  Widget build(BuildContext context) {
    final currentStory = widget.stories[_currentIndex];
    final currentUserId = ref.watch(authStateProvider).value?.uid ?? '';
    final isOwner = currentStory.userId == currentUserId;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < screenWidth / 3) {
            _previousStory();
          } else if (details.globalPosition.dx > screenWidth * 2 / 3) {
            _nextStory();
          }
        },
        onLongPressStart: (_) => _pause(),
        onLongPressEnd: (_) => _resume(),
        child: Stack(
          children: [
            // Contenu de la story
            PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.stories.length,
              itemBuilder: (context, index) {
                final story = widget.stories[index];
                if (story.isImage) {
                  return Container(
                    color: Colors.black,
                    child: CachedNetworkImage(
                      imageUrl: story.imageUrl!,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
                      imageBuilder: (context, imageProvider) {
                        // Image chargée ’ démarrer la progression
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (index == _currentIndex) _onImageLoaded();
                        });
                        return Image(
                          image: imageProvider,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                        );
                      },
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(Icons.error,
                            color: Colors.white, size: 48),
                      ),
                    ),
                  );
                } else {
                  return Container(
                    decoration:
                        _getTextBgDecoration(story.textBackground),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          story.text ?? '',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  );
                }
              },
            ),

            // Indicateur pause
            if (_isPaused)
              const Center(
                child: Icon(
                  CupertinoIcons.pause_fill,
                  color: Colors.white54,
                  size: 60,
                ),
              ),

            // Indicateur chargement image
            if (currentStory.isImage && !_imageLoaded)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),

            // Dégradé en haut
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 150,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Dégradé en bas
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 150,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Barre de progression
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              right: 8,
              child: Row(
                children: List.generate(
                  widget.stories.length,
                  (index) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: index < _currentIndex
                          ? Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            )
                          : index == _currentIndex
                              ? AnimatedBuilder(
                                  animation: _progressController,
                                  builder: (context, _) {
                                    return LinearProgressIndicator(
                                      value: _imageLoaded
                                          ? _progressController.value
                                          : 0,
                                      backgroundColor:
                                          Colors.white.withOpacity(0.3),
                                      valueColor:
                                          const AlwaysStoppedAnimation(
                                              Colors.white),
                                      minHeight: 3,
                                      borderRadius:
                                          BorderRadius.circular(2),
                                    );
                                  },
                                )
                              : Container(
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.white.withOpacity(0.3),
                                    borderRadius:
                                        BorderRadius.circular(2),
                                  ),
                                ),
                    ),
                  ),
                ),
              ),
            ),

            // Header user
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary,
                    backgroundImage: currentStory.userPhotoUrl != null
                        ? CachedNetworkImageProvider(
                            currentStory.userPhotoUrl!)
                        : null,
                    child: currentStory.userPhotoUrl == null
                        ? Text(
                            currentStory.username[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentStory.username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${currentStory.duration}h " ${currentStory.viewedBy.length} vue${currentStory.viewedBy.length > 1 ? 's' : ''}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontFamily: 'Poppins',
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(CupertinoIcons.xmark,
                        color: Colors.white),
                  ),
                  if (isOwner)
                    PopupMenuButton<String>(
                      icon: const Icon(CupertinoIcons.ellipsis,
                          color: Colors.white),
                      onSelected: (value) async {
                        if (value == 'delete') {
                          await StoryService()
                              .deleteStory(currentStory.id);
                          if (!mounted) return;
                          Navigator.pop(context);
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
                              Text('Supprimer',
                                  style: TextStyle(
                                      color: Colors.redAccent,
                                      fontFamily: 'Poppins')),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // Bas : répondre + republier
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  if (!isOwner)
                    Expanded(
                      child: _ReplyField(
                        story: currentStory,
                        onPause: _pause,
                        onResume: _resume,
                      ),
                    ),
                  if (!isOwner) const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      _pause();
                      await _showReshareDialog(context, currentStory);
                      _resume();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.arrowshape_turn_up_right_fill,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showReshareDialog(
      BuildContext context, StoryModel story) async {
    final userProfile = await ref.read(currentUserProvider.future);
    final currentUserId = ref.read(authStateProvider).value?.uid ?? '';
    int selectedDuration = 24;

    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Republier la story',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [12, 24, 48].map((d) {
                  return GestureDetector(
                    onTap: () =>
                        setModalState(() => selectedDuration = d),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin:
                          const EdgeInsets.symmetric(horizontal: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selectedDuration == d
                            ? AppColors.primary
                            : AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${d}h',
                        style: TextStyle(
                          color: selectedDuration == d
                              ? Colors.white
                              : AppColors.primary,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await StoryService().reshareStory(
                      story: story,
                      userId: currentUserId,
                      username: userProfile?.username ?? 'User',
                      userPhotoUrl: userProfile?.photoUrl,
                      duration: selectedDuration,
                    );
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Story republiée !',
                            style: TextStyle(fontFamily: 'Poppins')),
                        backgroundColor: AppColors.primary,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Republier',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReplyField extends ConsumerStatefulWidget {
  final StoryModel story;
  final VoidCallback onPause;
  final VoidCallback onResume;

  const _ReplyField({
    required this.story,
    required this.onPause,
    required this.onResume,
  });

  @override
  ConsumerState<_ReplyField> createState() => _ReplyFieldState();
}

class _ReplyFieldState extends ConsumerState<_ReplyField> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    _controller.clear();

    try {
      final user = ref.read(authStateProvider).value!;
      final userProfile = await ref.read(currentUserProvider.future);

      await ChatService().sendMessage(
        senderId: user.uid,
        senderUsername: userProfile?.username ?? 'User',
        senderPhotoUrl: userProfile?.photoUrl,
        receiverId: widget.story.userId,
        text: '=ø Story : $text',
      );

      widget.onResume();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Réponse envoyée !',
              style: TextStyle(fontFamily: 'Poppins')),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      widget.onResume();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onTap: widget.onPause,
      style: const TextStyle(
        fontFamily: 'Poppins',
        color: Colors.white,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: 'Répondre à la story...',
        hintStyle: TextStyle(
          fontFamily: 'Poppins',
          color: Colors.white.withOpacity(0.6),
          fontSize: 14,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        suffixIcon: _sending
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : IconButton(
                onPressed: _sendReply,
                icon: const Icon(CupertinoIcons.arrow_up,
                    color: Colors.white, size: 18),
              ),
      ),
      onSubmitted: (_) => _sendReply(),
    );
  }
}