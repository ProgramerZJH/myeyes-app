// 导入IO操作支持，提供Socket网络通信功能
import 'dart:io';

// 导入Flutter基础库，提供如compute等用于处理异步计算的核心功能
import 'package:flutter/foundation.dart';

// 导入自定义的图像检测模块，用于处理接收到的图像数据
import 'Detection.dart';

// 导入异步编程支持，提供Future、Stream等异步操作功能
import 'dart:async';

// 导入类型化数据支持，提供如Uint8List等用于处理二进制数据的类型
//import 'dart:typed_data';

// 导入自定义的文字转语音服务，用于语音提示
import 'package:myeyes/TTS.dart';

// 导入OpenCV图像处理库
import 'package:opencv_dart/opencv_dart.dart';

// 添加必要的导入
import 'dart:collection'; // 添加Queue支持
import 'package:opencv_dart/opencv_dart.dart' as cv; // 明确命名空间

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
  List<String> logMessages = [];

  // 添加帧缓冲区
  final Queue<Uint8List> _frameQueue = Queue(); // 图像帧队列
  bool _isProcessingQueue = false; // 队列处理状态

  // 添加缺失的成员变量
  int frame_counter = 0;
  final ValueNotifier<Uint8List> imageNotifier = ValueNotifier(Uint8List(0));

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
      // 添加帧头解析逻辑
      if (data.length == 8 && !isReceivingImage) {
        final headerData = ByteData.sublistView(data);
        frame_counter = headerData.getUint32(0, Endian.little);
        expectedImageSize = headerData.getUint32(4, Endian.little);

        currentImageData = Uint8List(0);
        isReceivingImage = true;
        return;
      }

      // 如果正在接收图像数据
      else if (isReceivingImage) {
        // 将新接收的数据追加到当前图像数据中
        currentImageData = Uint8List.fromList([...currentImageData, ...data]);
        addLog('当前接收数据长度: ${currentImageData.length} 字节');

        // 检查是否接收完整个图像
        if (currentImageData.length >= expectedImageSize) {
          // 将完整帧加入队列
          _frameQueue.add(Uint8List.fromList(currentImageData));
          currentImageData = Uint8List(0);
          expectedImageSize = 0;
          isReceivingImage = false;

          // 启动队列处理（如果未在处理）
          if (!_isProcessingQueue) {
            _processFrameQueue();
          }
        }
      }
    } catch (e) {
      // 发生错误时重置所有状态
      addLog('数据处理错误: $e');
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

  /// 添加日志记录
  /// [message] 日志消息内容
  void addLog(String message) {
    logMessages.add("[${DateTime.now().toString()}] $message");
    // 保持最新的100条记录
    if (logMessages.length > 100) {
      logMessages.removeAt(0);
    }
  }

  // 新增队列处理方法
  void _processFrameQueue() async {
    _isProcessingQueue = true;
    while (_frameQueue.isNotEmpty) {
      final frame = _frameQueue.removeFirst();
      try {
        // 并行处理检测和图像处理
        await Future.wait([
          MyDetection.Det_StartInference(frame),
          _processImage(frame),
        ]);

        if (refreash != null) refreash!();
      } catch (e) {
        addLog('帧处理错误: $e');
      }
    }
    _isProcessingQueue = false;
  }

  // 新增图像处理方法
  Future<void> _processImage(Uint8List frame) async {
    try {
      final mat = imdecode(frame, IMREAD_COLOR);
      final convertedMat = cvtColor(mat, COLOR_BGR2RGB);

      // 获取检测结果并绘制边界框
      final detectionResults = MyDetection.getLastResults();
      _drawBoundingBoxes(convertedMat, detectionResults);

      final (success, encodedBytes) = imencode('.jpg', convertedMat);
      processedImageData = success ? encodedBytes : frame;

      convertedMat.dispose();
      mat.dispose();

      // 更新通知器
      imageNotifier.value = processedImageData;
    } catch (e) {
      processedImageData = frame;
    }
  }

  // 修改边界框绘制方法
  void _drawBoundingBoxes(cv.Mat image, List<dynamic> results) {
    for (var result in results) {
      final box = result['box'];
      final left = box[0].toInt();
      final top = box[1].toInt();
      final right = box[2].toInt();
      final bottom = box[3].toInt();

      // 确保坐标有效性
      final width = (right - left).clamp(1, image.cols);
      final height = (bottom - top).clamp(1, image.rows);

      cv.rectangle(
          image,
          cv.Rect(left.clamp(0, image.cols - 1), top.clamp(0, image.rows - 1),
              width, height),
          cv.Scalar(0, 255, 0),
          thickness: 2);

      cv.putText(
          image,
          result['tag'].toString(),
          cv.Point(
              left.clamp(0, image.cols - 20), // 留出文本显示空间
              (top - 5).clamp(20, image.rows) // 防止顶部越界
              ),
          cv.FONT_HERSHEY_SIMPLEX,
          0.5,
          cv.Scalar(0, 255, 0),
          thickness: 1);
    }
  }
}
