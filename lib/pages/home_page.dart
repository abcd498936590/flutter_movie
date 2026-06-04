import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:movie/entity/video.dart';
import 'package:movie/provider/movie_provider.dart';
import 'package:movie/widget/proxy_movie_image.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _syncChannel = WindowMethodChannel(
    'movie_sync_channel',
    mode: ChannelMode.unidirectional,
  );
  final ScrollController _scrollController = ScrollController();
  int? _hoveredParentId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MovieProvider>().init();
    });
    _scrollController.addListener(_onScroll);
    _syncChannel.setMethodCallHandler((call) async {
      if (call.method == 'onResourceChanged' && mounted) {
        _resetScroll();
        await context.read<MovieProvider>().refreshAll();
      }
      return null;
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<MovieProvider>().fetchVideos();
    }
  }

  void _resetScroll() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Stack(
              children: [_buildVideoGrid(), _buildSubCategoryMenuOverlay()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final provider = context.watch<MovieProvider>();
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: Colors.black,
      child: Row(
        children: [
          const Text(
            '影视迷',
            style: TextStyle(
              color: Colors.green,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 40),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildHeaderItem(
                    typeName: '首页',
                    onTap: () {
                      _resetScroll();
                      provider.selectCategory(null);
                    },
                    onEnter: () => setState(() => _hoveredParentId = -1),
                  ),
                  ...provider.parentCategories.map((cat) {
                    return _buildHeaderItem(
                      typeName: cat.typeName,
                      onTap: null,
                      onEnter: () =>
                          setState(() => _hoveredParentId = cat.typeId),
                    );
                  }),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () {
              _resetScroll();
              context.read<MovieProvider>().fetchVideos(refresh: true);
            },
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white70),
            onPressed: _openSearchWindow,
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70),
            onPressed: _openSettingsWindow,
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderItem({
    required String typeName,
    VoidCallback? onTap,
    required VoidCallback onEnter,
  }) {
    return MouseRegion(
      onEnter: (_) => onEnter(),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Center(
            child: Text(
              typeName,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubCategoryMenuOverlay() {
    final provider = context.watch<MovieProvider>();
    final isVisible = _hoveredParentId != null && _hoveredParentId != -1;
    final subs = isVisible
        ? (provider.subCategoriesMap[_hoveredParentId] ?? [])
        : [];
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: !isVisible || subs.isEmpty,
        child: AnimatedOpacity(
          opacity: (isVisible && subs.isNotEmpty) ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 150),
          child: MouseRegion(
            onExit: (_) => setState(() => _hoveredParentId = null),
            child: Container(
              color: Colors.black.withAlpha(230),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Wrap(
                spacing: 20,
                runSpacing: 10,
                children: subs.map((sub) {
                  return InkWell(
                    onTap: () {
                      _resetScroll();
                      provider.selectCategory(sub.typeId);
                      setState(() => _hoveredParentId = null);
                    },
                    child: Text(
                      sub.typeName,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoGrid() {
    final provider = context.watch<MovieProvider>();
    final videos = provider.videos;
    return MouseRegion(
      onEnter: (_) {
        if (_hoveredParentId != null) setState(() => _hoveredParentId = null);
      },
      child: videos.isEmpty && provider.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                strokeWidth: 4,
                color: Colors.green,
              ),
            )
          : CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                        ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildVideoItem(videos[index]),
                      childCount: videos.length,
                    ),
                  ),
                ),
                if (provider.hasMore)
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      alignment: Alignment.center,
                      child: const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 4,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildVideoItem(VideoSourceListItem video) {
    return InkWell(
      onTap: () => _openPlayerWindow(video),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ProxyMovieImage(url: video.vodPic ?? ''),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            video.vodName ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            video.vodRemarks ?? '',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _openPlayerWindow(VideoSourceListItem video) async {
    try {
      final String videoJson = jsonEncode(video.toJson());
      final window = await WindowController.create(
        WindowConfiguration(arguments: videoJson, hiddenAtLaunch: false),
      );
      window.show();
    } catch (e) {
      debugPrint("Failed to open window: $e");
    }
  }

  void _openSettingsWindow() async {
    try {
      final window = await WindowController.create(
        const WindowConfiguration(
          arguments: 'settings_window',
          hiddenAtLaunch: false,
        ),
      );
      window.show();
    } catch (e) {
      debugPrint("Failed to open settings window: $e");
    }
  }

  void _openSearchWindow() async {
    try {
      final window = await WindowController.create(
        const WindowConfiguration(
          arguments: 'search_window',
          hiddenAtLaunch: false,
        ),
      );
      window.show();
    } catch (e) {
      debugPrint("Failed to open search window: $e");
    }
  }
}
