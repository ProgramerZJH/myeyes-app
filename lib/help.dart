// 导入Flutter基础UI组件库，提供了构建界面所需的核心组件
import 'package:flutter/material.dart';

// 导入平台服务支持，用于实现与原生平台的通信（如拨打电话功能）
import 'package:flutter/services.dart';

// 导入权限处理插件，用于请求和管理应用权限（如电话权限）
import 'package:permission_handler/permission_handler.dart';

// 导入地理位置定位插件，用于获取用户位置信息
import 'package:geolocator/geolocator.dart';

// 导入天气服务类
import 'services/weather_service.dart';

class Help extends StatefulWidget {
  const Help({super.key});

  @override
  State<Help> createState() => _HelpState();
}

class _HelpState extends State<Help> {
  // 添加状态变量来存储当前选择的城市
  String selectedCity = "重庆";
  final WeatherService _weatherService = WeatherService();
  List<Map<String, dynamic>> weatherData = [];
  Map<String, List<String>> cityData = {};
  String selectedProvince = '';

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _loadCityData();
  }

  Future<void> _initializeLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition();
        // TODO: 需要添加一个方法来根据经纬度获取adcode
        // 这里暂时使用默认值
        String adcode = "500000"; // 重庆市的adcode
        await _updateWeather(adcode);
      }
    } catch (e) {
      print('定位错误: $e');
      // 使用默认城市
      await _updateWeather("500000");
    }
  }

  Future<void> _loadCityData() async {
    try {
      final districtData = await _weatherService.getDistrict();
      if (districtData['districts'] != null &&
          districtData['districts'].isNotEmpty) {
        Map<String, List<String>> tempCityData = {};

        // 遍历省份
        for (var province in districtData['districts'][0]['districts']) {
          String provinceName = province['name'];
          tempCityData[provinceName] = [];

          // 遍历城市
          for (var city in province['districts']) {
            tempCityData[provinceName]!.add(city['name']);
          }
        }

        setState(() {
          cityData = tempCityData;
        });
      }
    } catch (e) {
      print('加载城市数据错误: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载城市数据失败: $e')),
        );
      }
    }
  }

  Future<void> _updateWeather(String adcode) async {
    try {
      final weather = await _weatherService.getWeather(adcode);
      if (weather['forecasts'] != null && weather['forecasts'].isNotEmpty) {
        setState(() {
          weatherData =
              List<Map<String, dynamic>>.from(weather['forecasts'][0]['casts']);
          selectedCity = weather['forecasts'][0]['city'];
        });
      }
    } catch (e) {
      print('更新天气错误: $e');
    }
  }

  Future<void> _checkAndRequestPermission() async {
    // 检查电话权限
    var status = await Permission.phone.status;
    if (!status.isGranted) {
      // 请求权限
      status = await Permission.phone.request();
      if (!status.isGranted) {
        // 用户拒绝了权限
        return;
      }
    }
  }

  void _showEmergencyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('紧急援助电话'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('110 - 报警'),
                onTap: () async {
                  Navigator.pop(context);
                  // 先检查权限
                  await _checkAndRequestPermission();
                  const platform = MethodChannel('com.example.myeyes/sos');
                  try {
                    await platform.invokeMethod('openDialer');
                  } catch (e) {
                    if (!mounted) return;
                    // 显示错误对话框
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('错误'),
                          content: Text('打开拨号界面失败: $e'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('确定'),
                            ),
                          ],
                        );
                      },
                    );
                  }
                },
              ),
              ListTile(
                title: const Text('120 - 急救'),
                onTap: () async {
                  Navigator.pop(context);
                  await _checkAndRequestPermission();
                  const platform = MethodChannel('com.example.myeyes/sos');
                  try {
                    await platform.invokeMethod('openDialer120');
                  } catch (e) {
                    if (!mounted) return;
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('错误'),
                          content: Text('打开拨号界面失败: $e'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('确定'),
                            ),
                          ],
                        );
                      },
                    );
                  }
                },
              ),
              ListTile(
                title: const Text('119 - 消防'),
                onTap: () async {
                  Navigator.pop(context);
                  await _checkAndRequestPermission();
                  const platform = MethodChannel('com.example.myeyes/sos');
                  try {
                    await platform.invokeMethod('openDialer119');
                  } catch (e) {
                    if (!mounted) return;
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('错误'),
                          content: Text('打开拨号界面败: $e'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('确定'),
                            ),
                          ],
                        );
                      },
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showProvinceDialog() {
    if (cityData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('城市数据加载中，请稍后重试')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('选择省份'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: cityData.keys.map((province) {
                return ListTile(
                  title: Text(province),
                  onTap: () {
                    Navigator.pop(context);
                    selectedProvince = province;
                    _showCityDialog(province);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  void _showCityDialog(String province) async {
    try {
      final cityData = await _weatherService.getDistrict(keywords: province);
      if (cityData['districts'] != null &&
          cityData['districts'].isNotEmpty &&
          cityData['districts'][0]['districts'] != null) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('选择城市 - $province'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children:
                      cityData['districts'][0]['districts'].map<Widget>((city) {
                    return ListTile(
                      title: Text(city['name']),
                      onTap: () async {
                        setState(() {
                          selectedCity = city['name'];
                        });
                        await _updateWeather(city['adcode']);
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
              ),
            );
          },
        );
      }
    } catch (e) {
      print('获取城市数据错误: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('获取城市数据失败: $e')),
        );
      }
    }
  }

  // 添加显示天气详情对话框的方法
  void _showWeatherDetailsDialog() {
    if (weatherData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('天气数据加载中...')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$selectedCity 四日天气'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: weatherData.map((weather) {
              return ListTile(
                title: Text('${weather['date']} ${weather['week']}'),
                subtitle: Text(
                  '日间: ${weather['daytemp']}° ${weather['dayweather']}\n'
                  '夜间: ${weather['nighttemp']}° ${weather['nightweather']}',
                  style: const TextStyle(fontSize: 14),
                ),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("帮助界面"),
      ),
      body: Center(
          child: Container(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200], // 容器的背景颜色
                      borderRadius: BorderRadius.circular(15.0), // 设置圆角半径为 15.0
                    ),
                    alignment: Alignment.center,
                    width: 400,
                    height: 250,
                    child: const Text(
                      '使用说明:xxx',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15, // 设置字大小为18
                        color: Colors.black,
                      ),
                    )),
                SizedBox(
                  width: 400,
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red, // 使用红色背景
                      foregroundColor: Colors.white, // 使用白色文字
                    ),
                    onPressed: _showEmergencyDialog, // 添加点击事件
                    child: const Text(
                      '紧急援助(SOS)',
                      style: TextStyle(
                        fontSize: 30,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // 添加新的Row组件
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // 左侧天气信息容器（改为可点击的容器）
                    GestureDetector(
                      onTap: _showWeatherDetailsDialog,
                      child: Container(
                        width: 180,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: weatherData.isEmpty
                              ? const Text(
                                  '加载中...',
                                  style: TextStyle(color: Colors.white),
                                )
                              : const Text(
                                  '点击查看天气详情',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    // 右侧城市选择按钮
                    SizedBox(
                      width: 80,
                      height: 60,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _showProvinceDialog,
                        child: Text(
                          selectedCity,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200], // 容器的背景颜色
                      borderRadius: BorderRadius.circular(15.0), // 设置圆角半径为 15.0
                    ),
                    alignment: Alignment.center,
                    width: 400,
                    height: 100,
                    child: const Text(
                      '开发团队:C204\n电子邮箱:jz659947@gmail.com\n联系电话:+8619133785078',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18, // 设文字大小为18
                        color: Colors.black,
                      ),
                    )),
              ]),
        ),
      )),
    );
  }
}
