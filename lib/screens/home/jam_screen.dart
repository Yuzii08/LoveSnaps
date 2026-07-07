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

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
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
        final imageUrl = couple.currentJamImageUrl;

        return Scaffold(
          backgroundColor: Colors.black,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                onPressed: _showUpdateJamBottomSheet,
                icon: const Icon(Icons.search_rounded, color: Colors.white),
                tooltip: 'Search Music',
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Dynamic Blurred Background
              if (imageUrl != null && imageUrl.isNotEmpty)
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: Colors.grey[900]),
                )
              else
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF2C3E50), Color(0xFF000000)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              // Glassmorphism Overlay
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 40.0, sigmaY: 40.0),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.6),
                ),
              ),
              
              // Main Content
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      // Large Album Art
                      Hero(
                        tag: 'jam_album_art',
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.85,
                          height: MediaQuery.of(context).size.width * 0.85,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 40,
                                offset: const Offset(0, 20),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(32),
                            child: (imageUrl != null && imageUrl.isNotEmpty)
                                ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _buildFallbackArt(),
                                  )
                                : _buildFallbackArt(),
                          ),
                        ),
                      ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.95, 0.95)),

                      const SizedBox(height: 48),

                      // Song Info
                      if (hasJam) ...[
                        Text(
                          couple.currentJamTitle!,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
                        
                        const SizedBox(height: 8),
                        
                        Text(
                          couple.currentJamArtist!,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
                        
                        const SizedBox(height: 16),
                        
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.headphones_rounded, color: Colors.white70, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                '$sharedByName shared this jam',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 400.ms),

                        const SizedBox(height: 32),

                        // Progress Slider
                        StreamBuilder<Duration>(
                          stream: _player.positionStream,
                          builder: (context, snapshot) {
                            final position = snapshot.data ?? Duration.zero;
                            final duration = _player.duration ?? Duration.zero;
                            return Column(
                              children: [
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 4,
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                    activeTrackColor: Colors.white,
                                    inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                                    thumbColor: Colors.white,
                                  ),
                                  child: Slider(
                                    value: position.inMilliseconds.toDouble().clamp(0.0, duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0),
                                    min: 0.0,
                                    max: duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0,
                                    onChanged: (val) {
                                      _player.seek(Duration(milliseconds: val.toInt()));
                                    },
                                    onChangeEnd: (val) {
                                      _syncLocalPlaybackToFirestore();
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(_formatDuration(position), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                      Text(_formatDuration(duration), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ).animate().fadeIn(delay: 500.ms),

                        const SizedBox(height: 16),

                        // Media Controls Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: _showUpdateJamBottomSheet,
                              icon: const Icon(Icons.add_rounded),
                              color: Colors.white,
                              iconSize: 32,
                            ),
                            const SizedBox(width: 24),
                            StreamBuilder<PlayerState>(
                              stream: _player.playerStateStream,
                              builder: (context, snapshot) {
                                final playing = snapshot.data?.playing ?? false;
                                final processingState = snapshot.data?.processingState;
                                final isBuffering = processingState == ProcessingState.loading || processingState == ProcessingState.buffering;

                                return Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
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
                                    icon: isBuffering 
                                      ? const CircularProgressIndicator(color: Colors.black)
                                      : Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                                    color: Colors.black,
                                    iconSize: 40,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 24),
                            IconButton(
                              onPressed: couple.jamQueue.isNotEmpty ? _skipNext : null,
                              icon: const Icon(Icons.skip_next_rounded),
                              color: couple.jamQueue.isNotEmpty ? Colors.white : Colors.white30,
                              iconSize: 40,
                            ),
                          ],
                        ).animate().fadeIn(delay: 600.ms),
                      ] else ...[
                        Text(
                          'No Jam Active',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ).animate().fadeIn().slideY(),
                        const SizedBox(height: 8),
                        const Text(
                          'Tap below to search and share music.',
                          style: TextStyle(color: Colors.white70),
                        ).animate().fadeIn(),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: _showUpdateJamBottomSheet,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            minimumSize: const Size(200, 56),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          icon: const Icon(Icons.search_rounded),
                          label: const Text('SEARCH MUSIC', style: TextStyle(fontWeight: FontWeight.bold)),
                        ).animate().fadeIn().scale(),
                      ],

                      const SizedBox(height: 48),

                      // Queue Section (Glassmorphism)
                      if (hasJam || couple.jamQueue.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Up Next',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                            ),
                            Row(
                              children: [
                                if (couple.jamQueue.isNotEmpty)
                                  TextButton(
                                    onPressed: _clearQueue,
                                    child: const Text('Clear', style: TextStyle(color: Colors.white54)),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.queue_music_rounded, color: Colors.white),
                                  onPressed: _addToQueue,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        if (couple.jamQueue.isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.music_note_rounded, color: Colors.white54, size: 32),
                                SizedBox(height: 8),
                                Text(
                                  'Queue is empty. Tap the + icon to add.',
                                  style: TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                              ],
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: couple.jamQueue.length,
                            itemBuilder: (context, index) {
                              final qItem = couple.jamQueue[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: qItem['imageUrl'] != null && qItem['imageUrl'].isNotEmpty
                                        ? Image.network(qItem['imageUrl'], width: 48, height: 48, fit: BoxFit.cover)
                                        : Container(
                                            width: 48, 
                                            height: 48, 
                                            color: Colors.white24,
                                            child: const Icon(Icons.music_note, color: Colors.white),
                                          ),
                                  ),
                                  title: Text(
                                    qItem['title'] ?? 'Song',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    qItem['artist'] ?? 'Artist',
                                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: index == 0
                                      ? const Icon(Icons.play_circle_outline_rounded, color: Colors.white)
                                      : null,
                                ),
                              );
                            },
                          ),
                      ],
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: Colors.white))),
      error: (e, _) => Scaffold(backgroundColor: Colors.black, body: Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white)))),
    );
  }

  Widget _buildFallbackArt() {
    return Container(
      color: Colors.grey[800],
      child: const Center(
        child: Icon(Icons.music_note_rounded, size: 80, color: Colors.white54),
      ),
    );
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
