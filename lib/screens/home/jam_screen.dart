import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

import '../../core/theme.dart';
import '../../models/couple_model.dart';
import '../../services/couple_service.dart';
import '../../services/auth_service.dart';

class JamScreen extends ConsumerStatefulWidget {
  final CoupleModel couple;

  const JamScreen({super.key, required this.couple});

  @override
  ConsumerState<JamScreen> createState() => _JamScreenState();
}

class _JamScreenState extends ConsumerState<JamScreen> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  final _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    
    _player.playingStream.listen((playing) {
      if (playing) {
        _rotationController.repeat();
      } else {
        _rotationController.stop();
      }
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _player.dispose();
    super.dispose();
  }

  void _showUpdateJamBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MusicSearchSheet(
        onSelectSong: (title, artist, imageUrl, downloadUrl) async {
          Navigator.pop(context);
          try {
            await ref.read(coupleServiceProvider).shareJam(
                  widget.couple.coupleId,
                  title,
                  artist,
                  imageUrl: imageUrl,
                  downloadUrl: downloadUrl,
                );
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('🎵 Shared "$title" as your current jam!'),
                backgroundColor: LoveSnapsColors.pinkAccent,
              ),
            );
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to share: $e'),
                backgroundColor: LoveSnapsColors.error,
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myUid = ref.watch(authStateProvider).value?.uid ?? '';
    final hasJam = widget.couple.currentJamTitle != null && widget.couple.currentJamTitle!.isNotEmpty;
    
    final isSharedByMe = widget.couple.currentJamSharedBy == myUid;
    final sharedByName = isSharedByMe ? 'You' : 'Your partner';

    return StreamBuilder<bool>(
      stream: _player.playingStream,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data ?? false;
        
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // Marshmallow Vinyl Player Bento Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: LoveSnapsShadows.marshmallowShadowCard,
                  ),
                  child: Column(
                    children: [
                      // Vinyl disc
                      RotationTransition(
                        turns: _rotationController,
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[900],
                            boxShadow: [
                              BoxShadow(
                                color: LoveSnapsColors.primary.withOpacity(0.2),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                            gradient: RadialGradient(
                              colors: [
                                Colors.grey[800]!,
                                Colors.black.withOpacity(0.9),
                                Colors.black,
                              ],
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(40),
                                child: (widget.couple.currentJamImageUrl != null &&
                                        widget.couple.currentJamImageUrl!.isNotEmpty)
                                    ? Image.network(
                                        widget.couple.currentJamImageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Center(
                                          child: Text('🎵', style: TextStyle(fontSize: 28)),
                                        ),
                                      )
                                    : const Center(
                                        child: Text('🎵', style: TextStyle(fontSize: 28)),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      if (hasJam) ...[
                        Text(
                          widget.couple.currentJamTitle!,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: LoveSnapsColors.primary,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ).animate().fadeIn().scale(),
                        const SizedBox(height: 8),
                        Text(
                          widget.couple.currentJamArtist!,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: LoveSnapsColors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          '$sharedByName shared this jam 🎧',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: LoveSnapsColors.secondary,
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ] else ...[
                        Text(
                          'No Jam Active',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: LoveSnapsColors.outline,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Search & share what you are listening to right now!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
                ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0),
                
                const SizedBox(height: 32),
                
                // tactile control button
                if (hasJam) ...[
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            if (isPlaying) {
                              await _player.pause();
                            } else {
                              if (_player.audioSource == null && widget.couple.currentJamDownloadUrl != null) {
                                await _player.setUrl(widget.couple.currentJamDownloadUrl!);
                              }
                              await _player.play();
                            }
                          },
                          child: Container(
                            height: 64,
                            decoration: BoxDecoration(
                              color: isPlaying ? Colors.grey[200] : LoveSnapsColors.primary,
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: LoveSnapsShadows.marshmallowShadowBtn,
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: isPlaying ? LoveSnapsColors.primary : Colors.white),
                                  const SizedBox(width: 12),
                                  Text(
                                    isPlaying ? 'PAUSE' : 'JOIN JAM',
                                    style: TextStyle(
                                      color: isPlaying ? LoveSnapsColors.primary : Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: _showUpdateJamBottomSheet,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: LoveSnapsColors.pinkAccent,
                            shape: BoxShape.circle,
                            boxShadow: LoveSnapsShadows.marshmallowShadowBtn,
                          ),
                          child: const Icon(Icons.search_rounded, color: Colors.white),
                        ),
                      ),
                    ],
                  ).animate(delay: 200.ms).fadeIn().scale(),
                ] else ...[
                  GestureDetector(
                    onTap: _showUpdateJamBottomSheet,
                    child: Container(
                      width: double.infinity,
                      height: 64,
                      decoration: BoxDecoration(
                        color: LoveSnapsColors.pinkAccent,
                        borderRadius: BorderRadius.circular(9999),
                        boxShadow: LoveSnapsShadows.marshmallowShadowBtn,
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_rounded, color: Colors.white),
                            SizedBox(width: 12),
                            Text(
                              'START A JAM',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate(delay: 200.ms).fadeIn().scale(),
                ]
              ],
            ),
          ),
        ),
      ],
    );
  }
);
  }
}

class _MusicSearchSheet extends StatefulWidget {
  final Function(String title, String artist, String? imageUrl, String? downloadUrl) onSelectSong;

  const _MusicSearchSheet({required this.onSelectSong});

  @override
  State<_MusicSearchSheet> createState() => _MusicSearchSheetState();
}

class _MusicSearchSheetState extends State<_MusicSearchSheet> {
  final _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _searchResults = [];
    });

    try {
      final response = await http.get(Uri.parse(
          'https://saavn.sumit.co/api/search/songs?query=${Uri.encodeComponent(query)}'));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          setState(() {
            _searchResults = json['data']['results'] as List? ?? [];
            _isLoading = false;
          });
          return;
        }
      }
      setState(() {
        _errorMessage = 'No songs found';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Search error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: LoveSnapsColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 6,
              decoration: BoxDecoration(
                color: LoveSnapsColors.outlineVariant,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '🎵 Find your Music Jam',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: LoveSnapsColors.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: _search,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search_rounded, color: LoveSnapsColors.primary),
                    hintText: 'Search songs on JioSaavn...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 24,
                backgroundColor: LoveSnapsColors.pinkAccent,
                child: IconButton(
                  icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                  onPressed: () => _search(_searchController.text),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.grey)))
                    : _searchResults.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('🔍', style: TextStyle(fontSize: 40)),
                                SizedBox(height: 12),
                                Text(
                                  'Search for your favorite songs\nand share it with your partner!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final song = _searchResults[index];
                              final songName = song['name'] ?? 'Unknown Song';
                              
                              // Extract artist
                              String artistName = 'Unknown Artist';
                              if (song['artists'] != null && song['artists']['primary'] != null) {
                                final primaryList = song['artists']['primary'] as List;
                                if (primaryList.isNotEmpty) {
                                  artistName = primaryList.map((a) => a['name']).join(', ');
                                }
                              }

                              // Extract album image
                              String? artworkUrl;
                              final images = song['image'] as List?;
                              if (images != null && images.isNotEmpty) {
                                artworkUrl = images.last['url'] as String?;
                              }

                              // Extract download url
                              String? downloadUrl;
                              final dlUrls = song['downloadUrl'] as List?;
                              if (dlUrls != null && dlUrls.isNotEmpty) {
                                final preferred = dlUrls.firstWhere((url) => (url['quality'] as String).contains('160'), orElse: () => dlUrls.last);
                                downloadUrl = preferred['url'] as String?;
                              }

                              return Card(
                                elevation: 0,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                color: Colors.white,
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: artworkUrl != null
                                        ? Image.network(
                                            artworkUrl,
                                            width: 48,
                                            height: 48,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              width: 48,
                                              height: 48,
                                              color: LoveSnapsColors.primaryContainer,
                                              child: const Icon(Icons.music_note_rounded),
                                            ),
                                          )
                                        : Container(
                                            width: 48,
                                            height: 48,
                                            color: LoveSnapsColors.primaryContainer,
                                            child: const Icon(Icons.music_note_rounded),
                                          ),
                                  ),
                                  title: Text(
                                    songName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    artistName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                  trailing: const Icon(Icons.chevron_right_rounded, color: LoveSnapsColors.pinkAccent),
                                  onTap: () {
                                    widget.onSelectSong(songName, artistName, artworkUrl, downloadUrl);
                                  },
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
