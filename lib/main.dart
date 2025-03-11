// 导入异步编程支持，提供Future、Stream等异步操作功能
import 'dart:async';

// 导入平台服务支持，用于调用原生平台API（如方法通道）
import 'package:flutter/services.dart';

// 导入自定义的WiFi客户端类，处理网络连接和通信
import 'wifi.dart';

// 导入自定义的文字转语音服务
import 'package:myeyes/TTS.dart';

// 导入Flutter基础UI组件
import 'package:flutter/material.dart';

// 导入应用设置插件，用于打开系统设置面板（如WiFi设置）
//import 'package:app_settings/app_settings.dart';

// 导入应用生命周期检测插件，用于监控应用前台/后台状态
//import 'package:flutter_lifecycle_detector/flutter_lifecycle_detector.dart';

// 导入帮助页面组件
import 'help.dart';

// 导入导航页面组件
import 'navigation.dart';

import 'services/openai_service.dart';
import 'dart:convert';
/*
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
*/
import 'package:x_amap_base/x_amap_base.dart';

import 'package:amap_map/amap_map.dart';

// 在文件顶部添加雷达客户端导入
import 'wifi_leida.dart';

// 在全局变量中添加雷达客户端实例
WiFiClient MyWifi = WiFiClient("192.168.37.33", 8080);
RadarClient MyRadar = RadarClient("192.168.37.33", 8082); // 使用相同IP但不同端口
TtsService tts = TtsService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 使用 MaterialApp 包装
  runApp(MaterialApp(
    home: const MyApp(),
    debugShowCheckedModeBanner: false,
  ));
  tts.TTS_speakText('My eyes 伴您安全出行');
}

//------------------------------构建主程序----------------------------------------
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    AMapInitializer.init(context,
        apiKey: AMapApiKey(androidKey: "b1d5458282af400870738a63af553eda"));
    AMapInitializer.updatePrivacyAgree(
        AMapPrivacyStatement(hasAgree: true, hasContains: true, hasShow: true));
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: Colors.black,
          secondary: Colors.black87,
          surface: Colors.black87,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.white,
        ),
      ),
      home: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            backgroundColor: Colors.black,
            title: const Center(
              child: Text(
                '听见视界',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            leading: Padding(
              padding: const EdgeInsets.only(left: 15),
              child: Container(
                height: 35,
                width: 35,
                decoration: const BoxDecoration(
                  color: Colors.yellow,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('通信日志'),
                          content: SizedBox(
                            width: double.maxFinite,
                            child: ListView.builder(
                              itemCount: MyWifi.logMessages.length,
                              itemBuilder: (context, index) {
                                return Text(
                                  MyWifi.logMessages[index],
                                  style: const TextStyle(fontSize: 12),
                                );
                              },
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('关闭'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  icon: const Icon(
                    Icons.list,
                    color: Colors.grey,
                    size: 20,
                  ),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 15),
                child: Container(
                  height: 35,
                  width: 35,
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          final ipController =
                              TextEditingController(text: '192.168.');
                          return AlertDialog(
                            backgroundColor: Colors.yellow,
                            title: const Text(
                              '动态设置IP地址',
                              style: TextStyle(color: Colors.black),
                              textAlign: TextAlign.center,
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  child: TextField(
                                    controller: ipController,
                                    style:
                                        const TextStyle(color: Colors.yellow),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      hintText: '请输入IP地址',
                                      hintStyle:
                                          TextStyle(color: Colors.purple),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '当前IP地址为: ${MyWifi.ip}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  // IP地址格式验证
                                  final RegExp ipRegex = RegExp(
                                      r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$');

                                  if (ipRegex.hasMatch(ipController.text)) {
                                    // 同时更新两个设备的IP地址
                                    MyWifi.set_Ip(ipController.text);
                                    MyRadar.setIp(ipController.text);
                                    Navigator.of(context).pop();
                                  } else {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text('错误'),
                                          content: const Text('IP地址格式不合法'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                              child: const Text('确定'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  }
                                },
                                child: const Text('确定',
                                    style: TextStyle(color: Colors.black)),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    icon: const Icon(
                      Icons.add,
                      color: Colors.yellow,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: const Center(
            child: MyHomePage(),
          ),
        ),
      ),
      routes: {
        '/navigation': (context) => const Navigation(),
      },
    );
  }
}

//----------------------------构建主页面------------------------------------------
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => MyHomePageState();
}

//-----------------------------主页面示内容--------------------------------------
class MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  TtsService mytts = TtsService();

  bool _previousConnectState = false; // 添加变量跟踪之前的连接状态
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();

    //传递刷新ui的函数
    MyWifi.refreash = () {
      // 检查连接状态是否发生变化
      if (_previousConnectState != MyWifi.connect_state) {
        if (MyWifi.connect_state) {
          tts.TTS_speakText('眼镜已连接');
        } else {
          tts.TTS_speakText('眼镜已断开连接');
        }
        _previousConnectState = MyWifi.connect_state;
      }
      setState(() {});
    };

    // 监听雷达障碍物流
    MyRadar.obstacleStream.listen((data) {
      // 可以在这里处理UI更新等
      setState(() {});
    });
  }

  Widget buildImageWidget() {
    return StreamBuilder<Uint8List>(
      stream: MyWifi.imageStream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Image.memory(
            snapshot.data!,
            gaplessPlayback: true, // 防止图像闪烁
          );
        }
        return Container(); // 或其他占位组件
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        // 添加滚动视图
        child: Column(
          children: <Widget>[
            Center(
              child: Container(
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200], // 容器的背景颜色
                            borderRadius:
                                BorderRadius.circular(15.0), // 设置圆角半径为 15.0
                          ),
                          alignment: Alignment.center,
                          width: 1000,
                          height: 50,
                          child: Text(
                            '眼镜连接状态：${MyWifi.connect_state ? '已连接' : '未连接'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18, // 设置文字大小为18
                              color: Colors.black,
                            ),
                          )),
                      const SizedBox(height: 40),
                      SizedBox(child: buildImageWidget()),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: 800,
                        height: 60,
                        child: ElevatedButton(
                            onPressed: () async {
                              const platform =
                                  MethodChannel('com.example.myeyes/hotspot');
                              try {
                                await platform
                                    .invokeMethod('openHotspotSettings');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('请开启个人热点')),
                                );
                                tts.TTS_speakText('请开启个人热点');
                              } catch (e) {
                                print('开启热点失败: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('开启热失败，请手动开启')),
                                );
                                tts.TTS_speakText('开启热点失败，请手动开启');
                              }
                            },
                            child: const Text("连接热点",
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                ))),
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: 800,
                        height: 60,
                        child: ElevatedButton(
                            onPressed: (MyWifi.connect_state || _isConnecting)
                                ? null
                                : () async {
                                    setState(() {
                                      _isConnecting = true;
                                    });
                                    tts.TTS_speakText('正在连接设备');

                                    // 分别处理连接，避免互相影响
                                    try {
                                      await MyWifi.connectAndCommunicate()
                                          .timeout(const Duration(seconds: 5),
                                              onTimeout: () {
                                        print('摄像头连接超时');
                                        return;
                                      });
                                    } catch (e) {
                                      print('摄像头连接错误: $e');
                                    }

                                    try {
                                      await MyRadar.connectAndCommunicate()
                                          .timeout(const Duration(seconds: 5),
                                              onTimeout: () {
                                        print('雷达连接超时');
                                        return;
                                      });
                                    } catch (e) {
                                      print('雷达连接错误: $e');
                                    }

                                    // 检查连接状态并播报
                                    if (MyWifi.connect_state &&
                                        MyRadar.connectState) {
                                      tts.TTS_speakText('摄像头和雷达均已连接');
                                    } else if (MyWifi.connect_state) {
                                      tts.TTS_speakText('仅摄像头已连接');
                                    } else if (MyRadar.connectState) {
                                      tts.TTS_speakText('仅雷达已连接');
                                    } else {
                                      tts.TTS_speakText('设备连接失败');
                                    }

                                    // 重置连接状态
                                    if (mounted) {
                                      setState(() {
                                        _isConnecting = false;
                                      });
                                    }
                                  },
                            child:
                                Text(_isConnecting ? "正在连接..." : "open my eyes",
                                    style: const TextStyle(
                                      fontSize: 20,
                                      color: Colors.white,
                                    ))),
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: 800,
                        height: 60,
                        child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (context) => const Help()),
                              );
                            },
                            child: const Text(
                              '帮 助',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                              ),
                            )),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width *
                                0.4, // 屏幕宽度的40%
                            height: 60,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              onPressed: () {
                                SystemNavigator.pop();
                              },
                              child: const Text(
                                '退 出',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width *
                                0.4, // 屏幕宽度的40%
                            height: 60,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              onPressed: _saveCurrentImage,
                              child: const Text(
                                '解 读',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                          alignment: Alignment.center,
                          width: 1000,
                          height: 50,
                          child: Text(
                            '雷达连接状态：${MyRadar.connectState ? '已连接' : '未连接'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.black,
                            ),
                          )),
                      StreamBuilder<Map<String, dynamic>>(
                        stream: MyRadar.obstacleStream,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData ||
                              MyRadar.displayMatrix.isEmpty) {
                            return Container(
                              height: 150,
                              color: Colors.grey[300],
                              child: const Center(child: Text('等待雷达数据...')),
                            );
                          }

                          return Container(
                            height: 150,
                            color: Colors.grey[300],
                            child: Column(
                              children: [
                                const Text('雷达避障数据',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                Expanded(
                                  child: Column(
                                    children: List.generate(
                                      MyRadar.displayMatrix.length,
                                      (row) => Expanded(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: List.generate(
                                            MyRadar.displayMatrix[row].length,
                                            (col) {
                                              int distance = MyRadar
                                                  .displayMatrix[row][col];
                                              // 获取当前格子的阈值
                                              int threshold = 0;
                                              if (row == 0)
                                                threshold = 50; // 上行
                                              else if (row == 1)
                                                threshold = 100; // 中行
                                              else
                                                threshold = 150; // 下行

                                              // 根据阈值设置颜色（只有红/绿两色）
                                              Color color = distance < threshold
                                                  ? Colors.red
                                                  : Colors.green;

                                              return Container(
                                                width: 50,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  color: color,
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    '$distance',
                                                    style: const TextStyle(
                                                      color: Colors.black,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveCurrentImage() async {
    if (MyWifi.getCurrentImage().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有可用的图像')),
      );
      tts.TTS_speakText('没有可用的图像');
      return;
    }

    Uint8List image = MyWifi.getCurrentImage();

    try {
      final openAIService = OpenAIService();
      final base64Image = base64Encode(image);

      // 添加加载状态提示
      tts.TTS_speakText('图片分析中，请稍候');

      final result = await openAIService
          .analyzeImage(base64Image)
          .timeout(const Duration(seconds: 30), onTimeout: () {
        return "分析超时，请检查网络连接";
      });

      // 确保在播报前停止其他播报
      await tts.flutterTts.stop();

      // 设置最高优先级标志
      TtsService.HighestPriority = true;

      // 按照AI返回的内容结构拆分回答（通常会按1. 2. 3.这样的格式返回）
      List<String> contentParts = [];

      // 尝试用序号分割
      RegExp numbered = RegExp(r'\d+[\.\、]');
      List<Match> matches = numbered.allMatches(result).toList();

      if (matches.length >= 2) {
        for (int i = 0; i < matches.length; i++) {
          int start = matches[i].start;
          int end =
              (i < matches.length - 1) ? matches[i + 1].start : result.length;
          contentParts.add(result.substring(start, end).trim());
        }
      } else {
        // 如果没有清晰的序号，则按句号分割
        contentParts =
            result.split('。').where((s) => s.trim().isNotEmpty).toList();
      }

      // 播报每个部分
      for (String part in contentParts) {
        if (part.isNotEmpty) {
          await tts.flutterTts.speak(part);
          // 等待播报完成（根据文本长度估算时间）
          await Future.delayed(
              Duration(milliseconds: 200 + (part.length * 80)));
        }
      }

      // 播报完成后释放最高优先级
      TtsService.HighestPriority = false;
    } catch (e) {
      TtsService.HighestPriority = false;
      print('图像处理失败: $e');
      tts.TTS_speakText('图片解读失败，请重试');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('处理失败: ${e.toString()}')),
      );
    }
  }
}
