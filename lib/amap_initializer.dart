import 'package:flutter/services.dart';

class AMapInitializer {
  static const MethodChannel _channel =
      MethodChannel('com.example.myeyes/amap');

  static Future<bool> init() async {
    try {
      // 先进行隐私合规设置
      await _channel.invokeMethod('updatePrivacyShow', {
        'isContains': true, // 隐私权政策是否包含高德开平隐私权政策
        'isShow': true, // 隐私权政策是否弹窗展示告知用户
      });

      await _channel.invokeMethod('updatePrivacyAgree', {
        'isAgree': true // 隐私权政策是否已经取得用户同意
      });

      // 然后初始化SDK
      final result = await _channel.invokeMethod('initAMapSDK');
      return result ?? false;
    } catch (e) {
      print('高德地图初始化失败: $e');
      return false;
    }
  }
}
