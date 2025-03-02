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

//import 'dart:collection'; // 添加这一行

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

  // 添加图像显示控制器
  final StreamController<Uint8List> imageStreamController =
      StreamController<Uint8List>.broadcast();
  Stream<Uint8List> get imageStream => imageStreamController.stream;

  // 添加超时控制
  final Duration _imageTimeout = const Duration(seconds: 1);
  DateTime? _lastImageUpdate;

  // 限制重连频率
  DateTime _lastReconnectAttempt = DateTime.now();
  final Duration _reconnectThrottle = const Duration(seconds: 2);

  // 添加缓冲区大小控制
  static const int BUFFER_SIZE = 131072; // 增加到128KB 缓冲区
  final List<int> _dataBuffer = [];
  bool _isProcessing = false;

  // 添加一个图像处理标志，防止过于频繁处理
  int _lastProcessedTimestamp = 0;
  static const int PROCESS_THROTTLE_MS = 100; // 最短处理间隔(毫秒)

  // 构造函数，初始化IP和端口
  WiFiClient(this.ip, this.port);

  /// 建立Socket连接并开始通信
  Future<void> connectAndCommunicate() async {
    try {
      socket =
          await Socket.connect(ip, port, timeout: const Duration(seconds: 5));
      socket!.setOption(SocketOption.tcpNoDelay, true); // 禁用Nagle算法

      connect_state = true;
      print('Connected to server');
      addLog('已连接到服务器: $ip:$port');

      // 使用compute隔离处理数据流，避免阻塞主线程
      socket!.listen(
        (data) {
          // 直接处理数据，不使用额外的异步
          handleIncomingData(data);
        },
        onError: (error) {
          print('Error: $error');
          addLog('连接错误: $error');
          _handleDisconnect();
        },
        onDone: () {
          print('Server disconnected');
          addLog('服务器断开连接');
          _handleDisconnect();
        },
      );

      _startImageMonitor();
    } catch (e) {
      print('Failed to connect: $e');
      addLog('连接失败: $e');
      connect_state = false;
      if (refreash != null) {
        refreash!();
      }
    }
  }

  void _handleDisconnect() {
    if (connect_state) {
      connect_state = false;
      _resetState();
      if (refreash != null) {
        refreash!();
      }

      // 使用节流控制重连频率
      final now = DateTime.now();
      if (now.difference(_lastReconnectAttempt) > _reconnectThrottle) {
        _lastReconnectAttempt = now;
        Future.delayed(const Duration(seconds: 1), () {
          reconnect();
        });
      }
    }
  }

  /// 处理接收到的数据
  /// [data] 接收到的二进制数据
  void handleIncomingData(Uint8List data) {
    try {
      // 直接将数据添加到缓冲区
      _dataBuffer.addAll(data);

      if (!_isProcessing) {
        _processBufferedData();
      }
    } catch (e) {
      addLog('数据处理错误: $e');
    }
  }

  void _processBufferedData() {
    _isProcessing = true;

    try {
      // 添加溢出控制：如果缓冲区太大，则清空缓冲区并重新开始
      if (_dataBuffer.length > BUFFER_SIZE * 2) {
        addLog('缓冲区溢出，清空缓冲区');
        _dataBuffer.clear();
        _resetState();
        return;
      }

      // 处理初始大小信息（如果有的话）
      if (!isReceivingImage && _dataBuffer.length >= 4) {
        final sizeBytes = Uint8List.fromList(_dataBuffer.sublist(0, 4));
        expectedImageSize =
            ByteData.view(sizeBytes.buffer).getUint32(0, Endian.little);
        _dataBuffer.removeRange(0, 4);
        isReceivingImage = true;
        currentImageData = Uint8List(0);
        addLog('预期图片大小: $expectedImageSize 字节');
      }

      // 处理图像数据
      if (isReceivingImage && _dataBuffer.isNotEmpty) {
        // 将缓冲区数据添加到当前图像
        final bytesToAdd = _dataBuffer.length;
        currentImageData = Uint8List.fromList(
            [...currentImageData, ..._dataBuffer.sublist(0, bytesToAdd)]);
        _dataBuffer.removeRange(0, bytesToAdd);

        // 检查是否接收完成
        if (currentImageData.length >= expectedImageSize) {
          _processCompletedImage();
        }
      }
    } catch (e) {
      addLog('缓冲区处理错误: $e');
      _resetState();
    } finally {
      _isProcessing = false;

      // 如果缓冲区中还有数据，继续处理
      if (_dataBuffer.length >= 4 && !isReceivingImage) {
        _processBufferedData();
      }
    }
  }

  Future<void> _processCompletedImage() async {
    if (!isReceivingImage || currentImageData.length < expectedImageSize)
      return;

    final now = DateTime.now().millisecondsSinceEpoch;
    // 限制处理频率，如果距离上次处理时间太短，则跳过
    if (now - _lastProcessedTimestamp < PROCESS_THROTTLE_MS) {
      _resetState();
      return;
    }
    _lastProcessedTimestamp = now;

    isReceivingImage = false;
    addLog('图片接收完成！总大小: ${currentImageData.length} 字节');

    // 验证图像数据
    if (currentImageData.length != expectedImageSize) {
      addLog('图像数据大小不匹配，跳过处理');
      _resetState();
      return;
    }

    // 处理图像
    if (!isProcessingImage) {
      isProcessingImage = true;

      try {
        // 直接发送原始图像到UI，减少延迟
        imageStreamController.add(currentImageData);
        _lastImageUpdate = DateTime.now();

        // 异步处理目标检测（可选）
        if (currentImageData.isNotEmpty) {
          // 使用compute在隔离区进行图像处理
          compute(MyDetection.Det_StartInference, currentImageData).then((_) {
            // 可选的图像后处理
            try {
              // 解码和重新编码图像（可选）
              final mat = imdecode(currentImageData, IMREAD_COLOR);
              final (success, encodedBytes) = imencode('.jpg', mat);

              if (success) {
                processedImageData = encodedBytes;
              } else {
                processedImageData = currentImageData;
              }

              mat.dispose(); // 释放资源
            } catch (e) {
              addLog('图像处理错误: $e');
              processedImageData = currentImageData;
            }
          });
        }

        // 刷新UI
        if (refreash != null) {
          refreash!();
        }
      } catch (e) {
        addLog('处理图像时发生错误: $e');
      } finally {
        isProcessingImage = false;
        _resetState();
      }
    }
  }

  void _resetState() {
    isReceivingImage = false;
    isProcessingImage = false;
    currentImageData = Uint8List(0);
    expectedImageSize = 0;
  }

  /// 断开Socket连接
  void disconnect() {
    socket?.close();
    connect_state = false;
    if (refreash != null) {
      refreash!();
    }
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
    Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      if (!connect_state) {
        timer.cancel();
        return;
      }

      if (_lastImageUpdate != null) {
        final difference = DateTime.now().difference(_lastImageUpdate!);
        if (difference > _imageTimeout) {
          addLog('图像更新超时，尝试重新连接...');
          _handleDisconnect();
        }
      }
    });
  }

  // 修改重连方法
  Future<void> reconnect() async {
    if (!connect_state) {
      socket?.close();
      socket = null;
      await connectAndCommunicate();
    }
  }
}
