import 'package:movie/entity/video.dart';
import 'package:movie/request/dio_client.dart';

class ApiService {
  static String baseUrl = 'http://cj.ffzyapi.com/api.php/provide/vod/at/json/';

  static Future<VideoSource> fetchVideos({int? typeId, int page = 1}) async {
    final query = <String, dynamic>{'ac': 'videolist', 'pg': page};
    if (typeId != null) {
      query['t'] = typeId;
    }

    final response = await HttpUtil().get(baseUrl, query: query);
    if (response.ok && response.data != null) {
      return VideoSource.fromJson(response.data);
    } else {
      throw Exception('Failed to load videos: ${response.exc?.message}');
    }
  }

  static Future<VideoSource> fetchVideosByKeyword(
    String keyword, {
    int page = 1,
  }) async {
    final query = <String, dynamic>{
      'ac': 'videolist',
      'wd': keyword,
      'pg': page,
    };

    final response = await HttpUtil().get(baseUrl, query: query);
    if (response.ok && response.data != null) {
      return VideoSource.fromJson(response.data);
    } else {
      throw Exception(
        'Failed to load search results: ${response.exc?.message}',
      );
    }
  }

  static Future<List<VideoCategory>> fetchCategories() async {
    final response = await HttpUtil().get(baseUrl);
    if (response.ok && response.data != null) {
      final List<dynamic> classList = response.data['class'] ?? [];
      return classList.map((e) => VideoCategory.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load categories: ${response.exc?.message}');
    }
  }

  static Future<VideoSourceListItem?> fetchVideoDetail(int vodId) async {
    final response = await HttpUtil().get(
      baseUrl,
      query: {'ac': 'videolist', 'ids': vodId},
    );
    if (response.ok && response.data != null) {
      final source = VideoSource.fromJson(response.data);
      if (source.list != null && source.list!.isNotEmpty) {
        return source.list!.first;
      }
    }
    return null;
  }
}

class VideoCategory {
  final int typeId;
  final int typePid;
  final String typeName;

  VideoCategory({
    required this.typeId,
    required this.typePid,
    required this.typeName,
  });

  factory VideoCategory.fromJson(Map<String, dynamic> json) {
    int parse(dynamic v, int fallback) {
      if (v == null) return fallback;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? fallback;
    }

    return VideoCategory(
      typeId: parse(json['type_id'], 0),
      // Use -1 for missing PID to distinguish from explicit 0
      typePid: parse(json['type_pid'], -1),
      typeName: json['type_name']?.toString() ?? '',
    );
  }
}
