import 'dart:convert'; // 导入JSON编解码支持
import 'package:http/http.dart' as http; // 导入HTTP客户端支持

/// WeatherService类用于处理天气相关的API请求
/// 包括获取天气预报、实时天气和行政区域信息
class WeatherService {
  // 高德地图API密钥，用于认证API请求
  final String _apiKey = 'd9d5b5221f0dbf8b4e6b09110d91cab0';

  // 高德天气API的基础URL
  final String _baseUrl = 'https://restapi.amap.com/v3/weather/weatherInfo';

  /// 获取天气预报信息
  /// [adcode] 城市的行政区划代码
  /// 返回包含未来几天天气预报的Map对象
  Future<Map<String, dynamic>> getWeather(String adcode) async {
    try {
      // 构建API请求URL，extensions=all表示获取预报天气
      final response = await http.get(
        Uri.parse('$_baseUrl?key=$_apiKey&city=$adcode&extensions=all'),
      );

      // 检查响应状态
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // 检查API返回状态，1表示成功
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

  /// 获取实时天气信息
  /// [adcode] 城市的行政区划代码
  /// 返回包含实时天气数据的Map对象
  Future<Map<String, dynamic>> getCurrentWeather(String adcode) async {
    try {
      // 构建API请求URL，extensions=base表示获取实时天气
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

  /// 获取行政区域信息
  /// [keywords] 可选的关键字参数，用于搜索特定地区
  /// 返回包含行政区划数据的Map对象
  Future<Map<String, dynamic>> getDistrict({String? keywords}) async {
    try {
      // 构建行政区划查询API的URL
      // subdistrict=2 表示返回两级行政区划
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
