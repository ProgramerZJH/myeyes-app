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

//import 'package:myeyes/amap_initializer.dart';

import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:x_amap_base/x_amap_base.dart';

import 'package:amap_map/amap_map.dart';

WiFiClient MyWifi = WiFiClient("192.168.185.33", 8080);
TtsService tts = TtsService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 使用 MaterialApp 包装
  runApp(MaterialApp(
    home: const MyApp(),
    debugShowCheckedModeBanner: false,
  ));
  tts.TTS_speakText('My eyes 助您安全出行');
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
                SizedBox(
                  width: 800,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _saveCurrentImage,
                    child: const Text(
                      '拍 摄',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            )),
      )),
    ]));
  }

  Future<void> _saveCurrentImage() async {
    if (MyWifi.getCurrentImage().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有可用的图像')),
      );
      tts.TTS_speakText('没有可用的图像');
      return;
    }

    try {
      // 获取外部存储权限
      if (!await Permission.storage.request().isGranted) {
        throw Exception('需要存储权限才能保存图片');
      }

      // 保存到相册目录
      final directory = await getExternalStorageDirectory();
      if (directory == null) throw Exception('无法访问存储目录');

      // 创建 DCIM/MyEyes 目录
      final myEyesDir = Directory('${directory.path}/DCIM/MyEyes');
      if (!await myEyesDir.exists()) {
        await myEyesDir.create(recursive: true);
      }

      final String fileName =
          'MyEyes_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = '${myEyesDir.path}/$fileName';

      // 保存图片
      final File imageFile = File(filePath);
      await imageFile.writeAsBytes(MyWifi.getCurrentImage());

      // 通知媒体库扫描新文件
      await const MethodChannel('com.example.myeyes/media_scanner')
          .invokeMethod('scanFile', {'path': filePath});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('图片已保存到: ${myEyesDir.path}')),
      );
      tts.TTS_speakText('图片已保存到相册');
    } catch (e) {
      print('保存图片失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存图片失败: $e')),
      );
      tts.TTS_speakText('保存图片失败');
    }
  }
}
