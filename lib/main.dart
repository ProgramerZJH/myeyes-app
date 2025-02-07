// 导入异步编程支持，提供Future、Stream等异步操作功能
//import 'dart:async';

// 导入平台服务支持，用于调用原生平台API（如方法通道）
import 'package:flutter/services.dart';

// 导入自定义的WiFi客户端类，处理网络连接和通信
import 'wifi.dart';

// 导入自定义的文字转语音服务
import 'package:myeyes/TTS.dart';

// 导入Flutter基础UI组件
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

// 导入应用设置插件，用于打开系统设置面板（如WiFi设置）
//import 'package:app_settings/app_settings.dart';

// 导入应用生命周期检测插件，用于监控应用前台/后台状态
//import 'package:flutter_lifecycle_detector/flutter_lifecycle_detector.dart';

// 导入帮助页面组件
import 'help.dart';

// 导入导航页面组件
import 'navigation.dart';

WiFiClient MyWifi = WiFiClient("192.168.185.33", 8080);
TtsService tts = TtsService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

//------------------------------构建主程序----------------------------------------
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, //去掉debug图标
      title: '',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: Colors.black, // 设置主要颜色
          secondary: Colors.black87, // 设置背景色
          surface: Colors.black87, // 设置表面颜色
          onPrimary: Colors.white, // 设置主色上的文本颜色
          onSecondary: Colors.white, // 设置背景上的文本颜色
          onSurface: Colors.white, // 设置表面上的文本颜色
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
                '视途无忧',
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
                                    MyWifi.set_Ip(ipController.text);
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
  //final TextEditingController _ipController = TextEditingController();

  bool _previousConnectState = false; // 添加变量跟踪之前的连接状态

  /*
  //暴露出的在其他文件中刷新ui的方法
  void _refreshUI() {
    setState(() {});
  }
  */

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
    /*
    FlutterLifecycleDetector().onBackgroundChange.listen((isBackground) async {
      if (!isBackground) {
        await MyWifi.connectAndCommunicate();
        tts.TTS_speakImpText('设备连接成功');
      }
    });
    */
  }

  Widget buildImageWidget() {
    final imageData = MyWifi.getCurrentImage();
    if (imageData.isEmpty) {
      return Container(); // 显示占位符
    }

    return FutureBuilder<ui.Image>(
      future: decodeImageFromList(imageData),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Image decode error: ${snapshot.error}');
          return Container(); // 解码失败时显示空容器
        }

        if (!snapshot.hasData) {
          return const CircularProgressIndicator(); // 加载中显示进度指示器
        }

        return Image.memory(
          imageData,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) {
            print('Image error: $error');
            return Container(); // 显示错误时的占位符
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(children: <Widget>[
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
                      borderRadius: BorderRadius.circular(15.0), // 设置圆角半径为 15.0
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
                /*
                  SizedBox(
                    width: 800,
                    height: 60,
                    child: ElevatedButton(
                        onPressed: MyWifi.connect_state
                            ? null
                            : () {
                                AppSettings.openAppSettingsPanel(
                                    AppSettingsPanelType.wifi);
                                tts.TTS_speakImpText(
                                    '请在当前界面内找到名为H O M E的设备并连接');
                              },
                        child: const Text("打开wifi设置",
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                            ))),
                  ),
                  const SizedBox(height: 15),
                  */
                SizedBox(
                  width: 800,
                  height: 60,
                  child: ElevatedButton(
                      onPressed: () async {
                        const platform =
                            MethodChannel('com.example.myeyes/hotspot');
                        try {
                          await platform.invokeMethod('openHotspotSettings');
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
                      onPressed: MyWifi.connect_state
                          ? null
                          : () async {
                              await MyWifi.connectAndCommunicate();
                            },
                      child: const Text("open my eyes",
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
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const Help()),
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
                SizedBox(
                  width: 800,
                  height: 60,
                  child: ElevatedButton(
                      onPressed: () {
                        SystemNavigator.pop();
                      },
                      child: const Text(
                        '退 出',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      )),
                ),
              ],
            )),
      )),
    ]));
  }
}
