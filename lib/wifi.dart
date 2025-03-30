// 导入IO操作支持，提供Socket网络通信功能
import 'dart:io';

// 导入Flutter基础库，提供如compute等用于处理异步计算的核心功能
import 'package:flutter/foundation.dart';

// 导入自定义的图像检测模块，用于处理接收到的图像数据
import 'Detection.dart';

// 导入异步编程支持，提供Future、Stream等异步操作功能
import 'dart:async';

// 导入自定义的文字转语音服务，用于语音提示
import 'package:myeyes/TTS.dart';

// 导入OpenCV图像处理库
import 'package:opencv_dart/opencv_dart.dart';

/// WiFi客户端类
/// 负责与眼镜端建立Socket连接并处理图像数据
class WiFiClient {
  // 实例化TTS服务，用于语音播报
  TtsService tts = TtsService();

  // 实例化目标检测服务
  final MyDetection detection = MyDetection();

  // 存储当前接收到的图像数据
  Uint8List currentImageData = Uint8List(0);

  // 存储经过OpenCV处理后的图像数据
  Uint8List processedImageData = Uint8List(0);

  // 预期接收的图像大小（字节数）
  int expectedImageSize = 0;

  // 标记是否正在接收图像数据
  bool isReceivingImage = false;

  // 标记是否正在处理图像
  bool isProcessingImage = false;

  // Socket连接的目标IP地址
  String ip;

  // Socket连接的目标端口
  int port;

  // 连接状态标志
  bool connect_state = false;

  // Socket连接实例
  Socket? socket;

  // UI刷新回调函数
  Function? refreash;

  // 存储日志消息的列表
  // 注释掉日志相关逻辑
  /*
  List<String> logMessages = [];
  */

  // 添加图像显示控制器
  final StreamController<Uint8List> imageStreamController =
      StreamController<Uint8List>.broadcast();
  Stream<Uint8List> get imageStream => imageStreamController.stream;

  // 添加超时控制
  final Duration _imageTimeout = const Duration(seconds: 1);
  DateTime? _lastImageUpdate;

  // 构造函数，初始化IP和端口
  WiFiClient(this.ip, this.port);

  /// 建立Socket连接并开始通信
  Future<void> connectAndCommunicate() async {
    try {
      // 尝试建立Socket连接
      socket = await Socket.connect(ip, port);
      connect_state = true;
      print('Connected to server');

      // 监听Socket数据
      socket!.listen(
        // 数据处理回调
        (Uint8List data) async {
          await handleIncomingData(data);
        },
        // 错误处理回调
        onError: (error) {
          print('Error: $error');
          connect_state = false;
          socket?.close();
        },
        // 连接关闭回调
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

  /// 处理接收到的数据
  /// [data] 接收到的二进制数据
  Future<void> handleIncomingData(Uint8List data) async {
    try {
      if (data.length == 4 && !isReceivingImage) {
        expectedImageSize =
            ByteData.view(data.buffer).getUint32(0, Endian.little);
        //addLog('预期图片大小: $expectedImageSize 字节');
        currentImageData = Uint8List(0);
        isReceivingImage = true;
      }
      // 如果正在接收图像数据
      else if (isReceivingImage) {
        // 将新接收的数据追加到当前图像数据中
        currentImageData = Uint8List.fromList([...currentImageData, ...data]);
        //addLog('当前接收数据长度: ${currentImageData.length} 字节');

        if (currentImageData.length >= expectedImageSize) {
          isReceivingImage = false;
          //addLog('图片接收完成！总大小: ${currentImageData.length} 字节');

          // 如果数据大小正确且未在处理中，则开始处理图像
          if (currentImageData.length == expectedImageSize &&
              !isProcessingImage) {
            isProcessingImage = true;

            try {
              // 进行目标检测
              await MyDetection.Det_StartInference(currentImageData);

              // 使用OpenCV处理图像
              try {
                // 从内存中解码JPEG数据
                final mat = imdecode(currentImageData, IMREAD_COLOR);

                // 将处理后的Mat转换回JPEG格式
                final (success, encodedBytes) = imencode('.jpg', mat);
                if (success) {
                  // 通过 Stream 发送图像数据
                  imageStreamController.add(encodedBytes);
                  processedImageData = encodedBytes;
                  //addLog('图像处理成功');
                } else {
                  processedImageData = currentImageData;
                }

                // 释放OpenCV资源
                mat.dispose();
              } catch (e) {
                //addLog('OpenCV处理错误: $e');
                processedImageData = currentImageData;
              }

              // 如果存在刷新回调，则刷新UI
              if (refreash != null) {
                refreash!();
              }
            } catch (e) {
              //addLog('处理图像时发生错误: $e');
            } finally {
              isProcessingImage = false;
            }
          }

          // 清理数据，准备接收下一张图像
          currentImageData = Uint8List(0);
          expectedImageSize = 0;
        }
      }
    } catch (e) {
      // 发生错误时重置所有状态
      //addLog('数据处理错误: $e');
      isReceivingImage = false;
      isProcessingImage = false;
      currentImageData = Uint8List(0);
      expectedImageSize = 0;
    }
  }

  /// 断开Socket连接
  void disconnect() {
    socket?.close();
    connect_state = false;
  }

  /// 设置新的IP地址
  /// [data] 新的IP地址
  void set_Ip(String data) {
    ip = data;
  }

  /// 获取当前图像数据
  /// 返回处理后的图像，如果没有则返回原始图像
  Uint8List getCurrentImage() {
    return processedImageData.isEmpty ? currentImageData : processedImageData;
  }

  /// 设置当前图像数据
  /// [data] 新的图像数据
  void setCurrentImage(Uint8List data) {
    currentImageData = data;
    processedImageData = data;
    // 通过Stream发送图像数据
    imageStreamController.add(data);
  }

  /// 添加日志记录
  /*
  void addLog(String message) {
    logMessages.add("[${DateTime.now().toString()}] $message");
    // 保持最新的100条记录
    if (logMessages.length > 100) {
      logMessages.removeAt(0);
    }
  }
  */

  // 在不需要时释放资源
  void dispose() {
    imageStreamController.close();
    socket?.close();
  }

  // 修改图像流处理
  void handleImageData(Uint8List data) {
    try {
      _lastImageUpdate = DateTime.now();
      imageStreamController.add(data);
    } catch (e) {
      print('图像处理错误: $e');
    }
  }

  // 添加图像监控机制
  void _startImageMonitor() {
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_lastImageUpdate != null) {
        final difference = DateTime.now().difference(_lastImageUpdate!);
        if (difference > _imageTimeout) {
          print('图像更新超时，尝试重新连接...');
          reconnect();
        }
      }
    });
  }

  // 修改连接方法
  Future<void> connect() async {
    try {
      socket = await Socket.connect(ip, port);
      _startImageMonitor();
      // ... 其他连接代码 ...
    } catch (e) {
      print('连接错误: $e');
    }
  }

  // 添加重连方法
  Future<void> reconnect() async {
    socket?.close();
    socket = null;
    await connect();
  }
}
