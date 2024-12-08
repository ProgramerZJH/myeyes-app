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

WiFiClient MyWifi = WiFiClient("192.168.185.33", 8080);
TtsService tts = TtsService();

Future<void> main() async {
  //初始化flutter框架(permission_handler必须)
  WidgetsFlutterBinding.ensureInitialized();

  //检查设备连接情况  后  构建主ui
  runApp(const MyApp());

  tts.TTS_speakText('My eyes 助您安全出行');
  //await AppSettings.openAppSettingsPanel(AppSettingsPanelType.wifi);弃用的WiFi面板
}

//------------------------------构建主程序----------------------------------------
class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
      home: Scaffold(
        appBar: AppBar(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15), // 设置圆角半径为 15
            ),
            backgroundColor: Colors.black,
            title: const Center(
                child: Text(
              '视途无忧',
              style: TextStyle(
                color: Colors.white, // 设置标题文字颜色为白色
                fontWeight: FontWeight.bold,
              ),
            ))),
        body: const Center(
          child: MyHomePage(),
        ),
      ),
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
class MyHomePageState extends State<MyHomePage> {
  TtsService mytts = TtsService();
  //final TextEditingController _ipController = TextEditingController();

  bool _previousConnectState = false; // 添加变量跟踪之前的连接状态

  //暴露出的在其他文件中刷新ui的方法
  void _refreshUI() {
    setState(() {});
  }

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
                      // 添加文本框和按钮
                      /*
                      TextField(
                        controller: _ipController,
                        decoration: const InputDecoration(
                          labelText: '输入新的IP地址',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 15),
                      ElevatedButton(
                        onPressed: () {
                          String newIp = _ipController.text;
                          MyWifi.set_Ip(newIp);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('IP地址已更新为: $newIp')),
                          );
                          tts.TTS_speakText('IP地址已更新');
                        },
                        child: const Text(
                          '确定',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      */
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
                      SizedBox(
                          child: MyWifi.list.isEmpty
                              ? const Image(
                                  image: AssetImage('assets/ic_launcher.png'))
                              : FadeInImage(
                                  placeholder: MemoryImage(
                                      MyWifi.list), // 使用相同的图像作为占位图像和加载图像
                                  image: MemoryImage(MyWifi.list),
                                )
                          //Image.memory(Uint8List.fromList(MyWifi.Data),),
                          ),
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
                                await platform
                                    .invokeMethod('openHotspotSettings');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('请开启个人热点')),
                                );
                                tts.TTS_speakText('请开启个人热点');
                              } catch (e) {
                                print('开启热点失败: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('开启热点失败，请手动开启')),
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
                  )))),
    ]));
  }
}
