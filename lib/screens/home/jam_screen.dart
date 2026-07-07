import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

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
  
  String? _loadedUrl;
  bool _isSyncingFromServer = false;
  
  StreamSubscription? _playerStateSub;
  StreamSubscription? _playerPositionSub;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );

    // Listen to local player play/pause state
    _playerStateSub = _player.playerStateStream.listen((state) {
      if (state.playing) {
        _rotationController.repeat();
      } else {
        _rotationController.stop();
      }
      
      // When track completes naturally, pop from queue if we are the host/sharer
      if (state.processingState == ProcessingState.completed) {
        _handleTrackCompleted();
      }
    });

    // Periodically update playback position to Firestore if we are playing and sharing
    _playerPositionSub = Stream.periodic(const Duration(seconds: 4)).listen((_) {
      _syncLocalPlaybackToFirestore();
    });
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _playerPositionSub?.cancel();
    _rotationController.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _handleTrackCompleted() async {
    final myUid = ref.read(authServiceProvider).currentUser?.uid;
    if (myUid == null) return;
    
    // Only the current track sharer manages queue popping to prevent duplicates
    if (widget.couple.currentJamSharedBy == myUid && widget.couple.jamQueue.isNotEmpty) {
      await ref.read(coupleServiceProvider).popFromJamQueue(widget.couple.coupleId, widget.couple.jamQueue);
    }
  }

  Future<void> _syncLocalPlaybackToFirestore() async {
    final myUid = ref.read(authServiceProvider).currentUser?.uid;
    if (myUid == null) return;

    // Only sync if we are the active sharer and player is playing
    if (widget.couple.currentJamSharedBy == myUid && _player.playing && !_isSyncingFromServer) {
      final pos = _player.position.inMilliseconds;
      await ref.read(coupleServiceProvider).updateJamPlayback(
        widget.couple.coupleId,
        playing: true,
        positionMs: pos,
      );
    }
  }

  /// Syncs database changes into local AudioPlayer
  void _syncFirestoreToLocalPlayer(CoupleModel couple, String myUid) async {
    final downloadUrl = couple.currentJamDownloadUrl;
    if (downloadUrl == null || downloadUrl.isEmpty) {
      if (_player.audioSource != null) {
        await _player.stop();
      }
      return;
    }

    _isSyncingFromServer = true;

    try {
      // 1. Load song source if different
      if (_loadedUrl != downloadUrl) {
        _loadedUrl = downloadUrl;
        await _player.setAudioSource(
          AudioSource.uri(
            Uri.parse(downloadUrl),
            tag: MediaItem(
              id: downloadUrl,
              title: couple.currentJamTitle ?? 'LoveSnaps Jam',
              artist: couple.currentJamArtist ?? 'Partner',
              artUri: (couple.currentJamImageUrl != null && couple.currentJamImageUrl!.isNotEmpty)
                  ? Uri.tryParse(couple.currentJamImageUrl!)
                  : null,
            ),
          ),
        );
      }

      // 2. Play / Pause Sync
      final shouldBePlaying = couple.currentJamPlaying;
      if (shouldBePlaying && !_player.playing) {
        // Calculate elapsed offset since last database update
        int targetPos = couple.currentJamPositionMs;
        if (couple.currentJamLastUpdatedMs > 0) {
          final elapsed = DateTime.now().millisecondsSinceEpoch - couple.currentJamLastUpdatedMs;
          if (elapsed > 0 && elapsed < 300000) {
            targetPos += elapsed;
          }
        }
        await _player.seek(Duration(milliseconds: targetPos));
        await _player.play();
      } else if (!shouldBePlaying && _player.playing) {
        await _player.pause();
        await _player.seek(Duration(milliseconds: couple.currentJamPositionMs));
      } else if (shouldBePlaying && _player.playing) {
        // Position drift check (sync if drifted by > 3 seconds)
        final localPos = _player.position.inMilliseconds;
        int remotePos = couple.currentJamPositionMs;
        if (couple.currentJamLastUpdatedMs > 0) {
          final elapsed = DateTime.now().millisecondsSinceEpoch - couple.currentJamLastUpdatedMs;
          if (elapsed > 0 && elapsed < 300000) {
            remotePos += elapsed;
          }
        }
        
        if ((localPos - remotePos).abs() > 3000) {
          await _player.seek(Duration(milliseconds: remotePos));
        }
      }
    } catch (e) {
      debugPrint('Sync player error: $e');
    } finally {
      _isSyncingFromServer = false;
    }
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
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to share: $e')));
          }
        },
      ),
    );
  }

  void _addToQueue() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MusicSearchSheet(
        onSelectSong: (title, artist, imageUrl, downloadUrl) async {
          Navigator.pop(context);
          try {
            await ref.read(coupleServiceProvider).addToJamQueue(
              widget.couple.coupleId,
              {
                'title': title,
                'artist': artist,
                'imageUrl': imageUrl ?? '',
                'downloadUrl': downloadUrl ?? '',
              },
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('➕ Added "$title" to Jam queue!'), backgroundColor: LoveSnapsColors.secondary),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to queue: $e')));
            }
          }
        },
      ),
    );
  }

  void _skipNext() async {
    if (widget.couple.jamQueue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Queue is empty!')),
      );
      return;
    }
    await ref.read(coupleServiceProvider).popFromJamQueue(widget.couple.coupleId, widget.couple.jamQueue);
  }

  void _clearQueue() async {
    await ref.read(coupleServiceProvider).clearJamQueue(widget.couple.coupleId);
  }

  @override
  Widget build(BuildContext context) {
    final myUid = ref.watch(authStateProvider).value?.uid ?? '';
    final coupleAsync = ref.watch(coupleStreamProvider);
    
    return coupleAsync.when(
      data: (couple) {
        if (couple == null) return const Center(child: Text('Pair first to jam!'));

        // Reactively sync playback state if we are NOT the active sender
        if (couple.currentJamSharedBy != myUid) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _syncFirestoreToLocalPlayer(couple, myUid);
          });
        }

        final hasJam = couple.currentJamTitle != null && couple.currentJamTitle!.isNotEmpty;
        final isSharedByMe = couple.currentJamSharedBy == myUid;
        final sharedByName = isSharedByMe ? 'You' : 'Your partner';

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),

                      // Vinyl Player Bento Box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
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
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey[900],
                                  boxShadow: [
                                    BoxShadow(
                                      color: LoveSnapsColors.primary.withValues(alpha: 0.15),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                  gradient: RadialGradient(
                                    colors: [
                                      Colors.grey[800]!,
                                      Colors.black.withValues(alpha: 0.9),
                                      Colors.black,
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Container(
                                    width: 70,
                                    height: 70,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(35),
                                      child: (couple.currentJamImageUrl != null &&
                                              couple.currentJamImageUrl!.isNotEmpty)
                                          ? Image.network(
                                              couple.currentJamImageUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => const Center(
                                                child: Text('🎵', style: TextStyle(fontSize: 24)),
                                              ),
                                            )
                                          : const Center(
                                              child: Text('🎵', style: TextStyle(fontSize: 24)),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 32),
                            
                            if (hasJam) ...[
                              Text(
                                couple.currentJamTitle!,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: LoveSnapsColors.primary,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                couple.currentJamArtist!,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: LoveSnapsColors.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '$sharedByName shared this jam 🎧',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: LoveSnapsColors.secondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ] else ...[
                              Text(
                                'No Jam Active',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: LoveSnapsColors.outline,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Search & share what you are listening to!',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Player Playback controls
                      if (hasJam) ...[
                        Row(
                          children: [
                            Expanded(
                              child: StreamBuilder<PlayerState>(
                                stream: _player.playerStateStream,
                                builder: (context, snapshot) {
                                  final playing = snapshot.data?.playing ?? false;
                                  return ElevatedButton.icon(
                                    onPressed: () async {
                                      if (playing) {
                                        await _player.pause();
                                        await ref.read(coupleServiceProvider).updateJamPlayback(
                                          couple.coupleId,
                                          playing: false,
                                          positionMs: _player.position.inMilliseconds,
                                        );
                                      } else {
                                        if (_player.audioSource == null && couple.currentJamDownloadUrl != null) {
                                          await _player.setAudioSource(
                                            AudioSource.uri(
                                              Uri.parse(couple.currentJamDownloadUrl!),
                                              tag: MediaItem(
                                                id: couple.currentJamDownloadUrl!,
                                                title: couple.currentJamTitle ?? 'LoveSnaps Jam',
                                                artist: couple.currentJamArtist ?? 'Partner',
                                                artUri: (couple.currentJamImageUrl != null && couple.currentJamImageUrl!.isNotEmpty)
                                                    ? Uri.tryParse(couple.currentJamImageUrl!)
                                                    : null,
                                              ),
                                            ),
                                          );
                                        }
                                        await _player.play();
                                        await ref.read(coupleServiceProvider).updateJamPlayback(
                                          couple.coupleId,
                                          playing: true,
                                          positionMs: _player.position.inMilliseconds,
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: playing ? Colors.grey[200] : LoveSnapsColors.primary,
                                      foregroundColor: playing ? LoveSnapsColors.primary : Colors.white,
                                      minimumSize: const Size(double.infinity, 54),
                                    ),
                                    icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                                    label: Text(playing ? 'PAUSE JAM' : 'JOIN JAM', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              onPressed: _showUpdateJamBottomSheet,
                              icon: const Icon(Icons.search_rounded),
                              style: IconButton.styleFrom(
                                backgroundColor: LoveSnapsColors.pinkAccent,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(54, 54),
                              ),
                            ),
                            if (couple.jamQueue.isNotEmpty) ...[
                              const SizedBox(width: 12),
                              IconButton(
                                onPressed: _skipNext,
                                icon: const Icon(Icons.skip_next_rounded),
                                style: IconButton.styleFrom(
                                  backgroundColor: LoveSnapsColors.secondary,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(54, 54),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ] else ...[
                        ElevatedButton.icon(
                          onPressed: _showUpdateJamBottomSheet,
                          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 54)),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('START A JAM', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Music Queue / Up Next Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '🎧 Up Next Queue',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: LoveSnapsColors.primary),
                          ),
                          Row(
                            children: [
                              if (couple.jamQueue.isNotEmpty)
                                TextButton(
                                  onPressed: _clearQueue,
                                  child: const Text('Clear', style: TextStyle(color: Colors.redAccent)),
                                ),
                              IconButton(
                                icon: const Icon(Icons.add_box_rounded, color: LoveSnapsColors.secondary),
                                onPressed: _addToQueue,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (couple.jamQueue.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: const Center(
                            child: Text(
                              'Queue is empty. Add songs to queue!',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: couple.jamQueue.length,
                          itemBuilder: (context, index) {
                            final qItem = couple.jamQueue[index];
                            return Card(
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              borderOnForeground: true,
                              child: ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: qItem['imageUrl'] != null && qItem['imageUrl'].isNotEmpty
                                      ? Image.network(qItem['imageUrl'], width: 36, height: 36, fit: BoxFit.cover)
                                      : const Icon(Icons.music_note),
                                ),
                                title: Text(
                                  qItem['title'] ?? 'Song',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  qItem['artist'] ?? 'Artist',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: index == 0
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: LoveSnapsColors.secondaryContainer,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text('Up Next', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: LoveSnapsColors.onSecondaryContainer)),
                                    )
                                    : null,
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
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
                              
                              String artistName = 'Unknown Artist';
                              if (song['artists'] != null && song['artists']['primary'] != null) {
                                final primaryList = song['artists']['primary'] as List;
                                if (primaryList.isNotEmpty) {
                                  artistName = primaryList.map((a) => a['name']).join(', ');
                                }
                              }

                              String? artworkUrl;
                              final images = song['image'] as List?;
                              if (images != null && images.isNotEmpty) {
                                artworkUrl = images.last['url'] as String?;
                              }

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
