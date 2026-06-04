import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:movie/entity/video.dart';
import 'package:movie/request/api_service.dart';
import 'package:movie/widget/proxy_movie_image.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<VideoSourceListItem> _results = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  String _currentKeyword = "";

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _performSearch(isLoadMore: true);
    }
  }

  Future<void> _performSearch({bool isLoadMore = false}) async {
    if (_isLoading) return;
    final keyword = _controller.text.trim();
    if (keyword.isEmpty) return;
    if (!isLoadMore) {
      setState(() {
        _results = [];
        _currentPage = 1;
        _hasMore = true;
        _currentKeyword = keyword;
      });
    }
    if (!_hasMore) return;
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.fetchVideosByKeyword(
        _currentKeyword,
        page: _currentPage,
      );
      setState(() {
        _results.addAll(response.list ?? []);
        _currentPage++;
        if (response.pagecount != null && _currentPage > response.pagecount!) {
          _hasMore = false;
        }
        if ((response.list ?? []).isEmpty) _hasMore = false;
      });
    } catch (e) {
      debugPrint("Search error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Container(
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: TextField(
              controller: _controller,
              textAlignVertical: const TextAlignVertical(y: -0.2),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.0,
              ),
              decoration: const InputDecoration(
                hintText: '搜索电影、电视剧...',
                hintStyle: TextStyle(color: Colors.white30),
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 15),
              ),
              onSubmitted: (_) => _performSearch(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _performSearch,
            child: const Text('搜索', style: TextStyle(color: Colors.green)),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_results.isEmpty && _isLoading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 4, color: Colors.green),
      );
    }
    if (_results.isEmpty && _currentKeyword.isNotEmpty && !_isLoading) {
      return const Center(
        child: Text("未找到相关结果", style: TextStyle(color: Colors.white54)),
      );
    }
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              childAspectRatio: 0.7,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildVideoItem(_results[index]),
              childCount: _results.length,
            ),
          ),
        ),
        if (_hasMore && _results.isNotEmpty)
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
}
