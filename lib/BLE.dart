import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/services.dart';
import 'package:myeyes/TTS.dart';
import 'dart:async';

class BLEManager {
  static final BLEManager _instance = BLEManager._internal();
  factory BLEManager() => _instance;
  BLEManager._internal();

  BluetoothDevice? _connectedDevice;
  // ignore: unused_field
  BluetoothCharacteristic? _characteristic;
  bool _isScanning = false;
  List<BluetoothDevice> _discoveredDevices = [];
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _deviceStateSubscription;
  final TtsService tts = TtsService();

  // 获取当前连接状态
  bool get isConnected => _connectedDevice != null;
  bool get isScanning => _isScanning;
  set isScanning(bool value) => _isScanning = value;
  List<BluetoothDevice> get discoveredDevices => _discoveredDevices;
  BluetoothDevice? get connectedDevice => _connectedDevice;

  // 初始化蓝牙
  Future<void> initBluetooth() async {
    try {
      final isSupported = await FlutterBluePlus.isSupported;
      if (!isSupported) {
        print('设备不支持蓝牙');
        return;
      }

      // 监听蓝牙状态变化
      FlutterBluePlus.adapterState.listen((state) {
        if (state == BluetoothAdapterState.on) {
          print('蓝牙已启用');
        } else {
          print('蓝牙未启用');
          _connectedDevice = null;
        }
      });
    } catch (e) {
      print('蓝牙初始化失败: $e');
    }
  }

  // 开始扫描设备
  Future<void> startScan(StateSetter setState) async {
    if (_isScanning) return;

    _discoveredDevices.clear();
    _isScanning = true;

    try {
      // 确保蓝牙已开启
      if (await FlutterBluePlus.adapterState.first ==
          BluetoothAdapterState.on) {
        _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
          for (ScanResult result in results) {
            if (!_discoveredDevices.contains(result.device) &&
                result.device.platformName.isNotEmpty) {
              setState(() {
                _discoveredDevices.add(result.device);
              });
            }
          }
        });

        await FlutterBluePlus.startScan(
          timeout: const Duration(seconds: 10),
          androidUsesFineLocation: false,
        );
      } else {
        print('蓝牙未开启');
        tts.TTS_speakText('请先开启蓝牙');
      }
    } catch (e) {
      print('扫描失败: $e');
      tts.TTS_speakText('蓝牙扫描失败');
    }

    _isScanning = false;
  }

  // 停止扫描
  void stopScan() {
    _scanSubscription?.cancel();
    FlutterBluePlus.stopScan();
    _isScanning = false;
  }

  // 连接到设备
  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(autoConnect: false).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          tts.TTS_speakText('导盲杖快捷键连接超时');
          device.disconnect();
          throw Exception('连接超时');
        },
      );

      _connectedDevice = device;
      tts.TTS_speakText('导盲杖快捷键连接成功');

      _deviceStateSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _connectedDevice = null;
          _characteristic = null;
          tts.TTS_speakText('导盲杖快捷键连接已断开');
        }
      });

      await _discoverServicesAndListen(device);
    } catch (e) {
      print('连接失败: $e');
      tts.TTS_speakText('导盲杖快捷键连接失败');
      device.disconnect();
    }
  }

  // 断开连接
  void disconnectFromDevice() {
    if (_connectedDevice != null) {
      _connectedDevice!.disconnect();
      _deviceStateSubscription?.cancel();
      _connectedDevice = null;
      _characteristic = null;
      tts.TTS_speakText('导盲杖快捷键连接已断开');
    }
  }

  // 发现服务和特征
  Future<void> _discoverServicesAndListen(BluetoothDevice device) async {
    try {
      List<BluetoothService> services = await device.discoverServices();

      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.properties.notify) {
            _characteristic = characteristic;

            await characteristic.setNotifyValue(true);

            characteristic.lastValueStream.listen((value) {
              if (value.isNotEmpty) {
                String message = String.fromCharCodes(value);
                print('收到消息: $message');

                if (message.contains('Black Button pressed')) {
                  // 触发回调
                  if (_onButtonPressed != null) {
                    _onButtonPressed!();
                  }
                }
              }
            });

            print('已设置特征值通知: ${characteristic.uuid}');
            break;
          }
        }
      }
    } catch (e) {
      print('发现服务失败: $e');
    }
  }

  // 按钮按下的回调函数
  Function? _onButtonPressed;
  void setOnButtonPressedCallback(Function callback) {
    _onButtonPressed = callback;
  }

  // 请求蓝牙权限
  Future<void> requestBluetoothPermissions(BuildContext context) async {
    const platform = MethodChannel('com.example.myeyes/bluetooth');
    bool hasPermissions = false;

    try {
      hasPermissions = await platform.invokeMethod('checkBluetoothPermissions');
    } catch (e) {
      print('检查蓝牙权限失败: $e');
    }

    if (!hasPermissions) {
      try {
        await platform.invokeMethod('requestBluetoothPermissions');
        await Future.delayed(const Duration(seconds: 1));
        hasPermissions =
            await platform.invokeMethod('checkBluetoothPermissions');
      } catch (e) {
        print('请求蓝牙权限失败: $e');
      }
    }

    if (hasPermissions) {
      showBluetoothDevicesList(context);
    } else {
      _showPermissionDialog(context);
    }
  }

  // 显示权限对话框
  void _showPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('需要蓝牙权限'),
          content: const Text('请授予应用蓝牙权限以连接导盲杖快捷键'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                const platform = MethodChannel('com.example.myeyes/bluetooth');
                try {
                  await platform.invokeMethod('openBluetoothSettings');
                } catch (e) {
                  print('打开蓝牙设置失败: $e');
                }
              },
              child: const Text('去设置'),
            ),
          ],
        );
      },
    );
  }

  // 显示蓝牙设备列表
  void showBluetoothDevicesList(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('蓝牙连接'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_isScanning ? '正在扫描...' : '可用设备'),
                        ElevatedButton(
                          onPressed: () {
                            if (_isScanning) {
                              stopScan();
                            } else {
                              startScan(setState);
                            }
                            setState(() {});
                          },
                          child: Text(_isScanning ? '停止' : '扫描'),
                        ),
                      ],
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _discoveredDevices.length,
                        itemBuilder: (context, index) {
                          final device = _discoveredDevices[index];
                          final isConnected =
                              _connectedDevice?.remoteId == device.remoteId;
                          return ListTile(
                            title: Text(device.platformName.isEmpty
                                ? '未知设备'
                                : device.platformName),
                            subtitle: Text(device.remoteId.str),
                            trailing: isConnected
                                ? const Icon(Icons.bluetooth_connected,
                                    color: Colors.green)
                                : const Icon(Icons.bluetooth),
                            onTap: () {
                              if (isConnected) {
                                disconnectFromDevice();
                              } else {
                                connectToDevice(device);
                              }
                              Navigator.of(context).pop();
                            },
                          );
                        },
                      ),
                    ),
                  ],
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
  }

  // 释放资源
  void dispose() {
    stopScan();
    disconnectFromDevice();
    _scanSubscription?.cancel();
    _deviceStateSubscription?.cancel();
  }
}
