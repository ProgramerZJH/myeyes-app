import 'dart:async'; // 添加TimeoutException支持
import 'package:flutter/services.dart'; // 添加PlatformException支持
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'services/navigation_service.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        const platform = MethodChannel('com.example.myeyes/amap');
        await platform.invokeMethod('initAMapSDK');

        // 使用高德定位SDK的合规接口
        await platform.invokeMethod(
            'updatePrivacyShow', {'isContains': true, 'isShow': true});
        await platform.invokeMethod('updatePrivacyAgree', {'isAgree': true});

        _getCurrentLocation();
      } on PlatformException catch (e) {
        print("高德SDK初始化失败: ${e.message}");
      }
    });
  }

  /// 获取当前位置
  /// 使用Geolocator插件获取设备GPS位置
  Future<void> _getCurrentLocation() async {
    try {
      // 在定位前检查隐私协议
      if (!await _checkPrivacyAgreement()) {
        await _showPrivacyDialog();
      }
      setState(() => _isLoading = true);

      // 检查服务是否启用
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // 提示用户打开定位服务
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('请先启用定位服务')));
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.deniedForever) {
        // 永久拒绝时的处理
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('需要在设置中授予定位权限')));
        }
        return;
      }

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          return; // 用户拒绝权限
        }
      }

      // 获取位置时添加try-catch
      Position position = await Geolocator.getCurrentPosition().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('定位超时'),
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _currentLatLng = LatLng(position.latitude, position.longitude);
          _updateCurrentMarker();
          _isLoading = false;
        });
      }
    } on PlatformException catch (e) {
      print('定位异常: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('定位失败: ${e.message}')));
      }
    } catch (e) {
      print('获取位置失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('获取位置失败')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _checkPrivacyAgreement() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('privacyAgreed') ?? false;
  }

  Future<void> _showPrivacyDialog() async {
    return showDialog(
        context: context,
        builder: (context) => AlertDialog(
                title: Text('隐私政策'),
                content: SingleChildScrollView(child: Text('...隐私政策内容...')),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text('拒绝')),
                  ElevatedButton(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('privacyAgreed', true);
                        Navigator.pop(context);
                      },
                      child: Text('同意')),
                ]));
  }

  void _updateCurrentMarker() {
    if (_currentLatLng == null) return;

    _markers.clear();
    _markers.add(Marker(
      position: _currentLatLng!,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      infoWindow: const InfoWindow(title: "当前位置"),
    ));
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
      setState(() {
        _selectedRoute = route;
        _isLoading = false;
      });
    } catch (e) {
      print('规划路线失败: $e');
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
                _mapController = controller;
                if (_currentLatLng != null) {
                  _mapController.moveCamera(CameraUpdate.newLatLngZoom(
                    _currentLatLng!,
                    16,
                  ));
                }
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
