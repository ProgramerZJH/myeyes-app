// 导入IO操作支持，提供Socket网络通信功能
import 'dart:io';

// 导入Flutter基础库，提供如compute等用于处理异步计算的核心功能
import 'package:flutter/foundation.dart';

// 导入自定义的图像检测模块，用于处理接收到的图像数据
import 'Detection.dart';

// 导入异步编程支持，提供Future、Stream等异步操作功能
import 'dart:async';

// 导入类型化数据支持，提供如Uint8List等用于处理二进制数据的类型
import 'dart:typed_data';

// 导入自定义的文字转语音服务，用于语音提示
import 'package:myeyes/TTS.dart';

import 'package:opencv_dart/opencv_dart.dart';

class WiFiClient {
  TtsService tts = TtsService();
  final MyDetection detection = MyDetection(); // 修改为 MyDetection

  Uint8List currentImageData = Uint8List(0);
  Uint8List processedImageData = Uint8List(0); // 新增：存储处理后的图片
  int expectedImageSize = 0;
  bool isReceivingImage = false;
  bool isProcessingImage = false; // 新增：防止重复处理

  String ip;
  int port;
  bool connect_state = false;
  Socket? socket;
  Function? refreash;

  // 添加日志列表
  List<String> logMessages = [];

  WiFiClient(this.ip, this.port) {}

  Future<void> connectAndCommunicate() async {
    try {
      socket = await Socket.connect(ip, port);
      connect_state = true;
      print('Connected to server');

      socket!.listen(
        (Uint8List data) async {
          await handleIncomingData(data);
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

  Future<void> handleIncomingData(Uint8List data) async {
    try {
      if (data.length == 4 && !isReceivingImage) {
        expectedImageSize =
            ByteData.view(data.buffer).getUint32(0, Endian.little);
        addLog('预期图片大小: $expectedImageSize 字节');
        currentImageData = Uint8List(0);
        isReceivingImage = true;
      } else if (isReceivingImage) {
        currentImageData = Uint8List.fromList([...currentImageData, ...data]);
        addLog('当前接收数据长度: ${currentImageData.length} 字节');

        if (currentImageData.length >= expectedImageSize) {
          isReceivingImage = false;
          addLog('图片接收完成！总大小: ${currentImageData.length} 字节');

          if (currentImageData.length == expectedImageSize &&
              !isProcessingImage) {
            isProcessingImage = true;

            try {
              // 先进行目标检测
              await MyDetection.Det_StartInference(currentImageData);

              // 使用OpenCV处理图像
              try {
                // 从内存中解码JPEG数据
                final mat = imdecode(currentImageData, IMREAD_COLOR);

                // 转换颜色空间
                final convertedMat = cvtColor(mat, COLOR_BGR2RGB);

                // 将Mat转换回Uint8List
                final (success, encodedBytes) = imencode('.jpg', convertedMat);
                if (success) {
                  processedImageData = encodedBytes;
                } else {
                  processedImageData = currentImageData;
                }
                addLog('图像处理成功');
                convertedMat.dispose();
                mat.dispose();
              } catch (e) {
                addLog('OpenCV处理错误: $e');
                processedImageData = currentImageData;
              }

              if (refreash != null) {
                refreash!();
              }
            } catch (e) {
              addLog('处理图像时发生错误: $e');
            } finally {
              isProcessingImage = false;
            }
          }

          currentImageData = Uint8List(0);
          expectedImageSize = 0;
        }
      }
    } catch (e) {
      addLog('数据处理错误: $e');
      isReceivingImage = false;
      isProcessingImage = false;
      currentImageData = Uint8List(0);
      expectedImageSize = 0;
    }
  }

  void disconnect() {
    socket?.close();
    connect_state = false;
  }

  void set_Ip(String data) {
    ip = data;
  }

  // 获取当前图片数据的方法
  Uint8List getCurrentImage() {
    return processedImageData.isEmpty ? currentImageData : processedImageData;
  }

  // 添加日志记录方法
  void addLog(String message) {
    logMessages.add("[${DateTime.now().toString()}] $message");
    // 保持最新的100条记录
    if (logMessages.length > 100) {
      logMessages.removeAt(0);
    }
  }
}
