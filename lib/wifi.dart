// 导入IO操作支持，提供Socket网络通信功能
import 'dart:io';

// 导入Flutter基础库，提供如compute等用于处理异步计算的核心功能
import 'package:flutter/foundation.dart';

// 导入平台服务支持，用于与原生平台交互
import 'package:flutter/services.dart';

// 导入自定义的图像检测模块，用于处理接收到的图像数据
import 'Detection.dart';

// 导入异步编程支持，提供Future、Stream等异步操作功能
import 'dart:async';

// 导入类型化数据支持，提供如Uint8List等用于处理二进制数据的类型
import 'dart:typed_data';

// 导入自定义的文字转语音服务，用于语音提示
import 'package:myeyes/TTS.dart';

class WiFiClient {
  TtsService tts = TtsService();
  List<int> Data = []; //存储接收的数据流，按字节数组形式存储，直到完整接收一张图片
  Uint8List list =
      Uint8List(0); //存储完整的图片数据，类型为 Uint8List，这是 Flutter 处理二进制数据的常用类型
  String ip;
  int port;
  int data_length = 0; //用于记录接收到的数据包长度
  bool clean_flag = false; //用于判断是否需要清空数据
  bool connect_state = false; //用于判断是否已经连接
  Socket? socket;
  Function? refreash;

  WiFiClient(this.ip, this.port);

  Future<void> connectAndCommunicate() async {
    try {
      // 连接到服务器
      socket = await Socket.connect(ip, port);
      connect_state = true;
      print('Connected to server');

      // 处理接收到的数据
      socket!.listen(
        (Uint8List data) async {
          // 首先接收4字节的图片大小数据
          if (data.length == 4) {
            int imageSize =
                ByteData.view(data.buffer).getUint32(0, Endian.little);
            print('Expected image size: $imageSize bytes');
            list = Uint8List(0); // 清空之前的数据
          } else {
            // 接收图片数据
            list = Uint8List.fromList([...list, ...data]);
            if (refreash != null) {
              refreash!(); // 刷新UI显示新图片
            }
          }
        },
        onError: (error) {
          print('Error: $error');
          connect_state = false;
          socket?.close();
        },
        onDone: () {
          print('Server disconnected');
          connect_state = false;
          socket?.close();
        },
      );
    } catch (e) {
      print('Failed to connect: $e');
      connect_state = false;
    }
  }

  void disconnect() {
    socket?.close();
    connect_state = false;
  }

  void set_Ip(String data) {
    ip = data;
  }
}
