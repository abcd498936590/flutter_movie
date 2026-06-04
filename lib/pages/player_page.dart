import 'dart:async';

import 'package:flutter/material.dart';
import 'package:movie/entity/video.dart';
import 'package:video_player/video_player.dart';
import 'package:window_manager/window_manager.dart';

class PlayerPage extends StatefulWidget {
  final VideoSourceListItem video;

  const PlayerPage({super.key, required this.video});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  VideoPlayerController? _controller;
  bool _showControls = true;
  bool _isFullScreen = false;
  Timer? _hideTimer;
  double _volume = 1.0;

  List<Episode> _episodes = [];
  int _currentEpisodeIndex = 0;

  @override
  void initState() {
    super.initState();
    _parseEpisodes();
    if (_episodes.isNotEmpty) {
      _initPlayer(_episodes[0].url);
    }
  }

  void _parseEpisodes() {
    final String playFrom = widget.video.vodPlayFrom ?? "";
    final String playUrl = widget.video.vodPlayUrl ?? "";
    final froms = playFrom.split(r'$$$');
    final urls = playUrl.split(r'$$$');
    int m3u8Index = -1;
    for (var i = 0; i < froms.length; i++) {
      if (froms[i].toLowerCase().contains('m3u8')) {
        m3u8Index = i;
        break;
      }
    }
    if (m3u8Index == -1 && urls.isNotEmpty) m3u8Index = 0;
    if (m3u8Index != -1 && m3u8Index < urls.length) {
      final episodesString = urls[m3u8Index];
      _episodes = episodesString.split('#').map((e) {
        final parts = e.split(r'$');
        if (parts.length >= 2) {
          return Episode(name: parts[0], url: parts[1]);
        } else {
          return Episode(name: '正片', url: parts[0]);
        }
      }).toList();
    }
  }

  Future<void> _initPlayer(String url) async {
    await _controller?.dispose();
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await _controller!.initialize();
      _controller!.setVolume(_volume);
      _controller!.play();
      _controller!.addListener(() => setState(() {}));
      setState(() {});
    } catch (e) {
      debugPrint('Player error: $e');
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _toggleFullScreen() async {
    try {
      final isFull = await windowManager.isFullScreen();
      await windowManager.setFullScreen(!isFull);
      setState(() {
        _isFullScreen = !isFull;
      });
    } catch (e) {
      debugPrint("FullScreen Error: $e");
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      if (_showControls) _startHideTimer();
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "${duration.inHours > 0 ? '${duration.inHours}:' : ''}$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: _toggleControls,
              behavior: HitTestBehavior.opaque,
              child: MouseRegion(
                onHover: (_) {
                  if (!_showControls) setState(() => _showControls = true);
                  _startHideTimer();
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_controller != null && _controller!.value.isInitialized)
                      Center(
                        child: AspectRatio(
                          aspectRatio: _controller!.value.aspectRatio,
                          child: VideoPlayer(_controller!),
                        ),
                      )
                    else
                      const CircularProgressIndicator(
                        color: Colors.green,
                        strokeWidth: 4,
                      ),

                    AnimatedOpacity(
                      opacity: _showControls ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: _buildControls(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _buildRightPanel(),
        ],
      ),
    );
  }

  Widget _buildControls() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const SizedBox();
    }

    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black87, Colors.transparent],
              ),
            ),
            child: Row(
              children: [
                Text(
                  '${widget.video.vodName ?? ""} - ${_episodes.isNotEmpty ? _episodes[_currentEpisodeIndex].name : ""}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        Center(
          child: IconButton(
            iconSize: 64,
            icon: Icon(
              _controller!.value.isPlaying
                  ? Icons.pause_circle_filled
                  : Icons.play_circle_filled,
              color: Colors.white70,
            ),
            onPressed: () {
              setState(() {
                _controller!.value.isPlaying
                    ? _controller!.pause()
                    : _controller!.play();
              });
            },
          ),
        ),

        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.only(
              bottom: 10,
              left: 20,
              right: 20,
              top: 20,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black87, Colors.transparent],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      _formatDuration(_controller!.value.position),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                          activeTrackColor: Colors.green,
                          inactiveTrackColor: Colors.white24,
                          thumbColor: Colors.green,
                        ),
                        child: Slider(
                          value: _controller!.value.position.inMilliseconds
                              .toDouble()
                              .clamp(
                                0,
                                _controller!.value.duration.inMilliseconds
                                    .toDouble(),
                              ),
                          min: 0.0,
                          max: _controller!.value.duration.inMilliseconds
                              .toDouble(),
                          onChanged: (value) {
                            _controller!.seekTo(
                              Duration(milliseconds: value.toInt()),
                            );
                          },
                        ),
                      ),
                    ),
                    Text(
                      _formatDuration(_controller!.value.duration),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),

                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _controller!.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _controller!.value.isPlaying
                              ? _controller!.pause()
                              : _controller!.play();
                        });
                      },
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.volume_up, color: Colors.white, size: 20),
                    SizedBox(
                      width: 100,
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2,
                          thumbColor: Colors.green,
                          activeTrackColor: Colors.green,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 10.0,
                          ),
                        ),
                        child: Slider(
                          value: _volume,
                          onChanged: (value) {
                            setState(() {
                              _volume = value;
                              _controller!.setVolume(_volume);
                            });
                          },
                        ),
                      ),
                    ),

                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        _isFullScreen
                            ? Icons.fullscreen_exit
                            : Icons.fullscreen,
                        color: Colors.white,
                      ),
                      onPressed: _toggleFullScreen,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRightPanel() {
    return Container(
      width: 300,
      color: const Color(0xFF1A1A1F),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.video.vodName ?? '',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${widget.video.vodYear} · ${widget.video.vodArea} · ${widget.video.typeName}',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 20),
          const Text(
            '选集',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3.2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _episodes.length,
              itemBuilder: (context, index) {
                final isSelected = _currentEpisodeIndex == index;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _currentEpisodeIndex = index;
                      _initPlayer(_episodes[index].url);
                    });
                  },
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.green : Colors.white10,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _episodes[index].name,
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white70,
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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

class Episode {
  final String name;
  final String url;

  Episode({required this.name, required this.url});
}
