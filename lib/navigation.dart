import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'services/navigation_service.dart';

class Navigation extends StatefulWidget {
  const Navigation({super.key});

  @override
  State<Navigation> createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  final NavigationService _navigationService = NavigationService();
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  Position? _currentPosition;
  Map<String, dynamic>? _selectedRoute;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  /// 获取当前位置
  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition();
        setState(() {
          _currentPosition = position;
        });
      }
    } catch (e) {
      print('获取位置失败: $e');
    }
  }

  /// 搜索地点
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

  /// 规划路线
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
