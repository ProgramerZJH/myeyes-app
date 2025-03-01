import 'dart:async'; // 添加TimeoutException支持
//import 'package:flutter/services.dart'; // 添加PlatformException支持
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'services/navigation_service.dart';
import 'package:amap_map/amap_map.dart';
import 'package:x_amap_base/x_amap_base.dart';
//import 'package:shared_preferences/shared_preferences.dart';
import 'package:myeyes/privacy_policy_dialog.dart'; // 添加这行
import 'dart:math' show min, max;

/// 导航页面
/// 提供基于高德地图的步行导航功能
/// 包含地点搜索、路线规划等功能

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class Navigation extends StatefulWidget {
  const Navigation({super.key});

  @override
  State<Navigation> createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  final NavigationService _navigationService = NavigationService();
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = []; // 搜索结果列表
  Position? _currentPosition; // 当前位置
  Map<String, dynamic>? _selectedRoute; // 选中的路线
  bool _isLoading = false; // 加载状态标志
  late AMapController _mapController;
  final List<Marker> _markers = [];
  final List<Polyline> _polylines = [];
  LatLng? _currentLatLng;

  @override
  void initState() {
    super.initState();
    // 立即初始化隐私合规
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initPrivacy();
    });
  }

  Future<void> _initPrivacy() async {
    try {
      // 每次都显示隐私弹窗
      final agreed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => PrivacyPolicyDialog(
          onAgreed: (agreed) {
            Navigator.pop(context, agreed);
          },
        ),
      );

      if (agreed == true) {
        // 3. 初始化地图
        await _initMap();
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      print('隐私合规初始化失败: $e');
    }
  }

  Future<void> _initMap() async {
    try {
      // 2. 获取位置权限和位置信息
      await _getCurrentLocation();
    } catch (e) {
      print('地图初始化失败: $e');
    }
  }

  /// 获取当前位置
  /// 使用Geolocator插件获取设备GPS位置
  Future<void> _getCurrentLocation() async {
    try {
      setState(() => _isLoading = true);

      // 检查服务是否启用
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('请先启用定位服务')));
        }
        return;
      }

      // 请求权限
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      // 获取位置
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _currentLatLng = LatLng(position.latitude, position.longitude);
        _updateCurrentMarker();
        _isLoading = false;
      });
    } catch (e) {
      print('获取位置失败: $e');
      setState(() => _isLoading = false);
    }
  }

  /*Future<bool> _checkPrivacyAgreement() async {
    // 移除缓存检查，每次都显示隐私弹窗
    return false;
  }*/

  void _updateCurrentMarker() {
    // 使用 _mapController 移动相机
    _mapController.moveCamera(
      CameraUpdate.newLatLngZoom(_currentLatLng!, 15),
    );
  }

  /// 搜索地点
  /// [keyword] 搜索关键词
  /// 使用高德地图POI搜索API
  Future<void> _searchPlace(String keyword) async {
    if (keyword.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _navigationService.searchPlace(keyword);
      setState(() {
        _searchResults = result['pois'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      print('搜索失败: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 规划步行路线
  /// [destination] 目的地信息
  /// 使用高德地图步行路线规划API
  Future<void> _planRoute(Map<String, dynamic> destination) async {
    if (_currentPosition == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final origin =
          '${_currentPosition!.longitude},${_currentPosition!.latitude}';
      final dest = '${destination['location']}';

      final route = await _navigationService.getWalkingRoute(origin, dest);

      // 添加路线到地图
      if (route['route']['paths'].isNotEmpty) {
        final path = route['route']['paths'][0];
        final steps = path['steps'] as List;

        List<LatLng> points = [];
        for (var step in steps) {
          final polyline = step['polyline'].split(';');
          for (var point in polyline) {
            final coords = point.split(',');
            points.add(LatLng(
              double.parse(coords[1]),
              double.parse(coords[0]),
            ));
          }
        }

        setState(() {
          _polylines.clear();
          _polylines.add(Polyline(
            points: points,
            width: 5,
            color: Colors.blue,
          ));
          _selectedRoute = route;
        });

        // 调整相机以显示整个路线
        _mapController.moveCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(
                points.map((p) => p.latitude).reduce(min),
                points.map((p) => p.longitude).reduce(min),
              ),
              northeast: LatLng(
                points.map((p) => p.latitude).reduce(max),
                points.map((p) => p.longitude).reduce(max),
              ),
            ),
            50.0, // padding
          ),
        );
      }
    } catch (e) {
      print('规划路线失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('导航'),
      ),
      body: Column(
        children: [
          // 地图容器
          Expanded(
            flex: 2,
            child: AMapWidget(
              onMapCreated: (controller) {
                setState(() {
                  _mapController = controller;
                  if (_currentLatLng != null) {
                    _updateCurrentMarker();
                  }
                });
              },
              markers: Set<Marker>.of(_markers),
              polylines: Set<Polyline>.of(_polylines),
              initialCameraPosition: CameraPosition(
                target: _currentLatLng ?? const LatLng(39.90960, 116.397228),
                zoom: 15,
              ),
            ),
          ),
          // 搜索框
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索地点',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _searchPlace(_searchController.text),
                ),
              ),
            ),
          ),

          // 加载指示器
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final place = _searchResults[index];
                  return ListTile(
                    title: Text(place['name'] ?? ''),
                    subtitle: Text(place['address'] ?? ''),
                    onTap: () => _planRoute(place),
                  );
                },
              ),
            ),

          // 显示路线信息
          if (_selectedRoute != null)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '步行路线：',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '总距离: ${_selectedRoute!['route']['paths'][0]['distance']}米\n'
                      '预计时间: ${_selectedRoute!['route']['paths'][0]['duration']}秒',
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _selectedRoute!['route']['paths'][0]['steps']
                            .length,
                        itemBuilder: (context, index) {
                          final step = _selectedRoute!['route']['paths'][0]
                              ['steps'][index];
                          return ListTile(
                            leading: const Icon(Icons.directions_walk),
                            title: Text(step['instruction']),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
