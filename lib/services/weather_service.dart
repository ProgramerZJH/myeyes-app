import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  // 高德地图 API 密钥
  final String _apiKey = 'd9d5b5221f0dbf8b4e6b09110d91cab0';
  final String _baseUrl = 'https://restapi.amap.com/v3/weather/weatherInfo';

  // 获取天气预报信息
  Future<Map<String, dynamic>> getWeather(String adcode) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?key=$_apiKey&city=$adcode&extensions=all'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == '1') {
          return data;
        } else {
          throw Exception('API返回错误: ${data['info']}');
        }
      } else {
        throw Exception('获取天气数据失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('获取天气数据失败: $e');
    }
  }

  // 获取实时天气信息
  Future<Map<String, dynamic>> getCurrentWeather(String adcode) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?key=$_apiKey&city=$adcode&extensions=base'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == '1') {
          return data;
        } else {
          throw Exception('API返回错误: ${data['info']}');
        }
      } else {
        throw Exception('获取天气数据失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('获取天气数据失败: $e');
    }
  }

  // 获取行政区域信息
  Future<Map<String, dynamic>> getDistrict({String? keywords}) async {
    try {
      final response = await http.get(
        Uri.parse('https://restapi.amap.com/v3/config/district?key=$_apiKey'
            '${keywords != null ? "&keywords=$keywords" : ""}'
            '&subdistrict=2'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == '1') {
          return data;
        } else {
          throw Exception('API返回错误: ${data['info']}');
        }
      } else {
        throw Exception('获取行政区域数据失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('获取行政区域数据失败: $e');
    }
  }
}
