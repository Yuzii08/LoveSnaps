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
  
  bool _isJoinedJam = true;
  String? _soloTitle;
  String? _soloArtist;
  String? _soloImageUrl;
  bool _soloIsPlaying = false;
  
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
    if (!_isJoinedJam) return;
    final myUid = ref.read(authServiceProvider).currentUser?.uid;
    if (myUid == null) return;
    
    // Only the current track sharer manages queue popping to prevent duplicates
    if (widget.couple.currentJamSharedBy == myUid && widget.couple.jamQueue.isNotEmpty) {
      await ref.read(coupleServiceProvider).popFromJamQueue(widget.couple.coupleId, widget.couple.jamQueue);
    }
  }

  Future<void> _syncLocalPlaybackToFirestore() async {
    if (!_isJoinedJam) return;
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
    if (!_isJoinedJam) return;
    
    final downloadUrl = couple.currentJamDownloadUrl;
    if (downloadUrl == null || downloadUrl.isEmpty) {
      if (_player.audioSource != null) {
        await _player.stop();
      }
      return;
    }

    _isSyncingFromServer = true;

    try {
      // 1. Load song source if different (For both sender and receiver)
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

      // 2. Play / Pause Sync (ONLY for receiver)
      if (couple.currentJamSharedBy == myUid) {
        return; // Sender controls playback locally, no need to sync from Firestore
      }
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

  void _playSoloSong(String title, String artist, String? imageUrl, String? downloadUrl) async {
    if (downloadUrl == null) return;
    setState(() {
      _soloTitle = title;
      _soloArtist = artist;
      _soloImageUrl = imageUrl;
      _soloIsPlaying = true;
    });
    
    await _player.setAudioSource(
      AudioSource.uri(
        Uri.parse(downloadUrl),
        tag: MediaItem(
          id: downloadUrl,
          title: title,
          artist: artist,
          artUri: imageUrl != null ? Uri.parse(imageUrl) : null,
        ),
      ),
    );
    await _player.play();
  }

  void _showUpdateJamBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MusicSearchSheet(
        onSelectSong: (title, artist, imageUrl, downloadUrl) async {
          Navigator.pop(context);
          if (!_isJoinedJam) {
            _playSoloSong(title, artist, imageUrl, downloadUrl);
          } else {
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
          }
        },
      ),
    );
  }

  void _addToQueue() {
    if (!_isJoinedJam) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Queue is only available in Jam mode!')));
      return;
    }
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
    if (!_isJoinedJam) return;
    if (widget.couple.jamQueue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Queue is empty!')),
      );
      return;
    }
    await ref.read(coupleServiceProvider).popFromJamQueue(widget.couple.coupleId, widget.couple.jamQueue);
  }

  void _clearQueue() async {
    if (!_isJoinedJam) return;
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

        // Reactively sync playback state for everyone (loads URL if needed, syncs if receiver)
        if (_isJoinedJam) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _syncFirestoreToLocalPlayer(couple, myUid);
          });
        }

        final bool hasJam = _isJoinedJam 
            ? (couple.currentJamTitle != null && couple.currentJamTitle!.isNotEmpty)
            : (_soloTitle != null && _soloTitle!.isNotEmpty);
            
        final String? imageUrl = _isJoinedJam ? couple.currentJamImageUrl : _soloImageUrl;
        final String title = _isJoinedJam ? (couple.currentJamTitle ?? '') : (_soloTitle ?? '');
        final String artist = _isJoinedJam ? (couple.currentJamArtist ?? '') : (_soloArtist ?? '');
        final String sharedByName = _isJoinedJam 
            ? (couple.currentJamSharedBy == myUid ? 'You' : 'Your partner') 
            : 'You (Solo)';

        return Scaffold(
          backgroundColor: Colors.black,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 32),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              _isJoinedJam ? 'PLAYING FROM JAM' : 'SOLO SESSION',
              style: const TextStyle(
                color: Colors.white, 
                fontSize: 10, 
                fontWeight: FontWeight.bold, 
                letterSpacing: 1.5,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                onPressed: _showUpdateJamBottomSheet, // Search music / options
              ),
            ],
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF4A4A4A), // Dark grey
                  Colors.black,
                  Colors.black,
                ],
                stops: [0.0, 0.4, 1.0],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    // Album Art
                    Expanded(
                      flex: 5,
                      child: Center(
                        child: Hero(
                          tag: 'jam_album_art',
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: (imageUrl != null && imageUrl.isNotEmpty)
                                  ? Image.network(
                                      imageUrl, 
                                      fit: BoxFit.cover, 
                                      errorBuilder: (_, __, ___) => _buildFallbackArt(),
                                    )
                                  : _buildFallbackArt(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Shared by text
                    if (hasJam)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.headphones_rounded, color: Colors.white, size: 12),
                              const SizedBox(width: 6),
                              Text(
                                'Shared by $sharedByName',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Song Info Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title.isNotEmpty ? title : 'No Song Playing',
                                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                artist.isNotEmpty ? artist : 'Tap the + to search',
                                style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Mode Toggle Heart
                        GestureDetector(
                          onTap: () async {
                            if (_isJoinedJam) {
                              await _player.stop();
                              setState(() => _isJoinedJam = false);
                            } else {
                              setState(() {
                                _isJoinedJam = true;
                                _loadedUrl = null;
                              });
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 4, left: 16),
                            child: Icon(
                              _isJoinedJam ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: _isJoinedJam ? Colors.greenAccent : Colors.white70,
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Progress Bar
                    StreamBuilder<Duration>(
                      stream: _player.positionStream,
                      builder: (context, snapshot) {
                        final position = snapshot.data ?? Duration.zero;
                        final duration = _player.duration ?? Duration.zero;
                        final progress = duration.inMilliseconds > 0 
                            ? position.inMilliseconds.toDouble() / duration.inMilliseconds.toDouble()
                            : 0.0;
                            
                        return Column(
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
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
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_formatDuration(position), style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w500)),
                                Text(_formatDuration(duration), style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.shuffle_rounded), 
                          color: Colors.white54, 
                          iconSize: 24,
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_previous_rounded), 
                          color: Colors.white, 
                          iconSize: 36, 
                          onPressed: () {
                            if (_player.position.inSeconds > 3) {
                              _player.seek(Duration.zero);
                              _syncLocalPlaybackToFirestore();
                            }
                          },
                        ),
                        // Play button
                        StreamBuilder<PlayerState>(
                          stream: _player.playerStateStream,
                          builder: (context, snapshot) {
                            final playing = snapshot.data?.playing ?? false;
                            final processingState = snapshot.data?.processingState;
                            final isBuffering = processingState == ProcessingState.loading || processingState == ProcessingState.buffering;

                            return Container(
                              width: 64,
                              height: 64,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: IconButton(
                                onPressed: () async {
                                  if (playing) {
                                    await _player.pause();
                                    if (_isJoinedJam) {
                                      await ref.read(coupleServiceProvider).updateJamPlayback(
                                        couple.coupleId,
                                        playing: false,
                                        positionMs: _player.position.inMilliseconds,
                                      );
                                    }
                                  } else {
                                    if (_loadedUrl != couple.currentJamDownloadUrl && _isJoinedJam && couple.currentJamDownloadUrl != null) {
                                      _loadedUrl = couple.currentJamDownloadUrl;
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
                                    if (_isJoinedJam) {
                                      await ref.read(coupleServiceProvider).updateJamPlayback(
                                        couple.coupleId,
                                        playing: true,
                                        positionMs: _player.position.inMilliseconds,
                                      );
                                    }
                                  }
                                },
                                icon: isBuffering 
                                  ? const CircularProgressIndicator(color: Colors.black, strokeWidth: 3)
                                  : Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                                color: Colors.black,
                                iconSize: 32,
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_next_rounded), 
                          color: couple.jamQueue.isNotEmpty ? Colors.white : Colors.white30, 
                          iconSize: 36, 
                          onPressed: couple.jamQueue.isNotEmpty ? _skipNext : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.repeat_rounded), 
                          color: Colors.white54, 
                          iconSize: 24,
                          onPressed: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Bottom Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.devices_rounded), 
                          color: _isJoinedJam ? Colors.greenAccent : Colors.white70, 
                          tooltip: 'Jam Devices',
                          onPressed: () {},
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.share_outlined), 
                          color: Colors.white70, 
                          onPressed: () {},
                        ),
                        Stack(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.queue_music_rounded), 
                              color: Colors.white70, 
                              onPressed: () {
                                _addToQueue();
                              },
                            ),
                            if (couple.jamQueue.isNotEmpty)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.greenAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${couple.jamQueue.length}',
                                    style: const TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
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
          'https://itunes.apple.com/search?term=${Uri.encodeComponent(query)}&media=music&limit=20'));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['results'] != null) {
          setState(() {
            _searchResults = json['results'] as List? ?? [];
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
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.only(
        top: 24,
        left: 20,
        right: 20,
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: LoveSnapsColors.background.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '🎵 Find your Jam',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: LoveSnapsColors.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: 16),
          // Premium Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: _search,
              style: const TextStyle(fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded, color: LoveSnapsColors.primary),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_circle_right, color: LoveSnapsColors.pinkAccent, size: 28),
                  onPressed: () => _search(_searchController.text),
                ),
                hintText: 'Search songs, artists...',
                hintStyle: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.normal),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: LoveSnapsColors.pinkAccent))
                : _errorMessage.isNotEmpty
                    ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.grey)))
                    : _searchResults.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.music_note_rounded, size: 80, color: Colors.grey[300]),
                                const SizedBox(height: 16),
                                Text(
                                  'Search for a track to play\nor add to the queue',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey[500], fontSize: 16, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
                          )
                        : ListView.separated(
                            itemCount: _searchResults.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final song = _searchResults[index];
                              final songName = song['trackName'] ?? 'Unknown Song';
                              final artistName = song['artistName'] ?? 'Unknown Artist';
                              
                              // Upgrade iTunes 100x100 to 600x600 for HD art
                              String? artworkUrl = song['artworkUrl100'] as String?;
                              if (artworkUrl != null) {
                                artworkUrl = artworkUrl.replaceAll('100x100bb', '600x600bb');
                              }
                              final downloadUrl = song['previewUrl'] as String?;

                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    widget.onSelectSong(songName, artistName, artworkUrl, downloadUrl);
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.02),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        )
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        // Album Art
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: artworkUrl != null
                                              ? Image.network(
                                                  artworkUrl,
                                                  width: 64,
                                                  height: 64,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) => _buildFallbackIcon(),
                                                )
                                              : _buildFallbackIcon(),
                                        ),
                                        const SizedBox(width: 16),
                                        // Song Info
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                songName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                artistName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: LoveSnapsColors.primaryContainer,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.play_arrow_rounded, color: LoveSnapsColors.primary, size: 20),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideX(begin: 0.1);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackIcon() {
    return Container(
      width: 64,
      height: 64,
      color: Colors.grey[200],
      child: const Icon(Icons.music_note_rounded, color: Colors.grey),
    );
  }
}

