import 'dart:convert';
import 'package:http/http.dart' as http;

class NavigationService {
  // 使用与天气服务相同的API密钥
  final String _apiKey = 'd9d5b5221f0dbf8b4e6b09110d91cab0';

  // 高德地图API的基础URL
  final String _searchUrl = 'https://restapi.amap.com/v3/place/text';
  final String _routeUrl = 'https://restapi.amap.com/v3/direction/walking';

  // 缓存相关
  final Map<String, dynamic> _searchCache = {};
  final Map<String, DateTime> _cacheTimestamp = {};
  final Duration _cacheDuration = const Duration(minutes: 5);

  /// 检查缓存是否有效
  bool _isCacheValid(String key) {
    if (!_cacheTimestamp.containsKey(key)) return false;
    final difference = DateTime.now().difference(_cacheTimestamp[key]!);
    return difference < _cacheDuration;
  }

  /// 搜索地点
  /// [keywords] 搜索关键词
  /// [city] 城市名称（可选）
  Future<Map<String, dynamic>> searchPlace(String keywords,
      {String? city}) async {
    final cacheKey = 'search_${keywords}_${city ?? ""}';

    // 检查缓存
    if (_isCacheValid(cacheKey) && _searchCache.containsKey(cacheKey)) {
      return _searchCache[cacheKey];
    }

    try {
      final response = await http.get(
        Uri.parse('$_searchUrl?key=$_apiKey&keywords=$keywords'
            '${city != null ? "&city=$city" : ""}&offset=20&page=1'
            '&extensions=all'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == '1') {
          // 更新缓存
          _searchCache[cacheKey] = data;
          _cacheTimestamp[cacheKey] = DateTime.now();
          return data;
        } else {
          throw Exception('API返回错误: ${data['info']}');
        }
      } else {
        throw Exception('搜索地点失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('搜索地点失败: $e');
    }
  }

  /// 规划步行路线
  /// [origin] 起点坐标，格式：'longitude,latitude'
  /// [destination] 终点坐标，格式：'longitude,latitude'
  Future<Map<String, dynamic>> getWalkingRoute(
      String origin, String destination) async {
    try {
      final response = await http.get(
        Uri.parse('$_routeUrl?key=$_apiKey&origin=$origin'
            '&destination=$destination'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == '1') {
          return data;
        } else {
          throw Exception('API返回错误: ${data['info']}');
        }
      } else {
        throw Exception('获取路线失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('获取路线失败: $e');
    }
  }

  /// 获取地点详细信息
  /// [id] POI的ID
  Future<Map<String, dynamic>> getPlaceDetail(String id) async {
    try {
      final response = await http.get(
        Uri.parse('https://restapi.amap.com/v3/place/detail'
            '?key=$_apiKey&id=$id'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == '1') {
          return data;
        } else {
          throw Exception('API返回错误: ${data['info']}');
        }
      } else {
        throw Exception('获取地点详情失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('获取地点详情失败: $e');
    }
  }
}
