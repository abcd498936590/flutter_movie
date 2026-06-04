import 'package:flutter/material.dart';
import 'package:movie/entity/video.dart';
import 'package:movie/request/api_service.dart';
import 'package:movie/utils/shared_preferences.dart';

class MovieProvider with ChangeNotifier {
  List<VideoCategory> _allCategories = [];
  List<VideoCategory> _parentCategories = [];
  Map<int, List<VideoCategory>> _subCategoriesMap = {};

  List<VideoSourceListItem> _videos = [];
  int _currentPage = 1;
  int? _selectedTypeId;
  bool _isLoading = false;
  bool _hasMore = true;

  List<Map<String, String>> _resourceList = [];
  String _activeUrl = ApiService.baseUrl;

  List<VideoCategory> get parentCategories => _parentCategories;

  Map<int, List<VideoCategory>> get subCategoriesMap => _subCategoriesMap;

  List<VideoSourceListItem> get videos => _videos;

  bool get isLoading => _isLoading;

  bool get hasMore => _hasMore;

  List<Map<String, String>> get resourceList => _resourceList;

  String get activeUrl => _activeUrl;

  Future<void> init() async {
    await loadSettings();
    await fetchCategories();
    await fetchVideos(refresh: true);
  }

  Future<void> loadSettings() async {
    final listData = SpUtil().getJSON('resource_list');
    if (listData != null && listData is List) {
      _resourceList = List<Map<String, String>>.from(
        listData.map((e) => Map<String, String>.from(e)),
      );
    } else {
      _resourceList = [
        {
          'name': '非凡资源',
          'url': 'http://cj.ffzyapi.com/api.php/provide/vod/at/json/',
        },
      ];
      await SpUtil().setJSON('resource_list', _resourceList);
    }
    _activeUrl =
        SpUtil().getString('active_url') ?? _resourceList.first['url']!;
    ApiService.baseUrl = _activeUrl;
    notifyListeners();
  }

  Future<void> addResource(String name, String url) async {
    _resourceList.add({'name': name, 'url': url});
    await SpUtil().setJSON('resource_list', _resourceList);
    notifyListeners();
  }

  Future<void> deleteResource(int index) async {
    final deletedUrl = _resourceList[index]['url'];
    _resourceList.removeAt(index);
    await SpUtil().setJSON('resource_list', _resourceList);
    if (_activeUrl == deletedUrl && _resourceList.isNotEmpty) {
      await switchResource(_resourceList.first['url']!);
    }
    notifyListeners();
  }

  Future<void> switchResource(String url) async {
    _activeUrl = url;
    ApiService.baseUrl = url;
    await SpUtil().setString('active_url', url);
    await refreshAll();
  }

  Future<void> fetchCategories() async {
    try {
      _allCategories = await ApiService.fetchCategories();
      final allIds = _allCategories.map((e) => e.typeId).toSet();

      // 1. Definite Parents (Categories that ARE parents of others)
      final pointedParentIds = _allCategories
          .where((e) => e.typePid > 0 && allIds.contains(e.typePid))
          .map((e) => e.typePid)
          .toSet();

      // 2. Standard Parent Names
      final standardParentNames = [
        "电影",
        "连续剧",
        "剧集",
        "电视剧",
        "综艺",
        "动漫",
        "纪录片",
        "电影片",
      ];

      // 3. Resolve Hierarchy
      _parentCategories = [];
      List<VideoCategory> orphanChildren = [];

      for (var cat in _allCategories) {
        bool isStandard = standardParentNames.any(
          (name) => cat.typeName.contains(name),
        );
        bool isPointed = pointedParentIds.contains(cat.typeId);

        // If it's a PID 0/missing AND (it's standard OR it's pointed to), it's a parent
        if ((cat.typePid <= 0) && (isStandard || isPointed)) {
          _parentCategories.add(cat);
        } else if (cat.typePid > 0 && allIds.contains(cat.typePid)) {
          // Explicit child - will be mapped later
        } else {
          // It's a potential orphan (pid 0 but not a standard parent)
          orphanChildren.add(cat);
        }
      }

      // 4. Mapping
      _subCategoriesMap = {};
      for (var p in _parentCategories) {
        _subCategoriesMap[p.typeId] = [];
      }

      for (var cat in _allCategories) {
        if (_parentCategories.any((p) => p.typeId == cat.typeId)) continue;

        // Try mapping by PID
        if (cat.typePid > 0 && _subCategoriesMap.containsKey(cat.typePid)) {
          _subCategoriesMap[cat.typePid]!.add(cat);
        } else {
          // Fuzzy match by name if PID is useless
          VideoCategory? bestParent;
          if (cat.typeName.contains("剧")) {
            bestParent = _parentCategories
                .where((p) => p.typeName.contains("剧"))
                .firstOrNull;
          } else if (cat.typeName.contains("片") || cat.typeName.contains("影")) {
            bestParent = _parentCategories
                .where(
                  (p) => p.typeName.contains("电影") || p.typeName.contains("片"),
                )
                .firstOrNull;
          }

          if (bestParent != null) {
            _subCategoriesMap[bestParent.typeId]!.add(cat);
          } else {
            // If still no match, and it's a root-like orphan, make it a parent
            if (cat.typePid <= 0) _parentCategories.add(cat);
          }
        }
      }

      // Cleanup empty parents (optional, but keep for now)
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    }
  }

  Future<void> fetchVideos({bool refresh = false, int? typeId}) async {
    if (_isLoading) return;
    if (refresh) {
      _currentPage = 1;
      _videos = [];
      _hasMore = true;
      _selectedTypeId = typeId;
    }
    if (!_hasMore) return;
    _isLoading = true;
    notifyListeners();
    try {
      final source = await ApiService.fetchVideos(
        typeId: _selectedTypeId,
        page: _currentPage,
      );
      final newVideos = source.list ?? [];
      if (newVideos.isEmpty) {
        _hasMore = false;
      } else {
        _videos.addAll(newVideos);
        _currentPage++;
        if (source.pagecount != null && _currentPage > source.pagecount!) {
          _hasMore = false;
        }
      }
    } catch (e) {
      _hasMore = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectCategory(int? typeId) {
    fetchVideos(refresh: true, typeId: typeId);
  }

  Future<void> refreshAll() async {
    await loadSettings();
    await fetchCategories();
    await fetchVideos(refresh: true);
    notifyListeners();
  }
}
