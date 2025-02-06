import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyDialog extends StatelessWidget {
  final Function(bool) onAgreed;

  const PrivacyPolicyDialog({super.key, required this.onAgreed});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('隐私政策协议'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            const Text(
              '请您务必审慎阅读并充分理解《隐私权政策》的全部内容，',
              style: TextStyle(fontSize: 16),
            ),
            TextButton(
              onPressed: () => launchUrl(
                Uri.parse('https://lbs.amap.com/pages/privacy/'),
              ),
              child: const Text('查看完整隐私政策'),
            ),
            const Text(
              '我们使用了高德地图SDK提供服务，需要您同意以下内容：\n'
              '1. 允许应用获取位置信息用于导航服务\n'
              '2. 允许应用收集设备信息用于地图渲染优化\n'
              '3. 同意高德地图开放平台隐私政策（点击查看完整政策）\n'
              '如您不同意，将无法使用导航相关服务',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            onAgreed(false);
            Navigator.of(context).pop();
          },
          child: const Text('暂不同意'),
        ),
        ElevatedButton(
          onPressed: () {
            onAgreed(true);
            Navigator.of(context).pop();
          },
          child: const Text('同意并继续'),
        ),
      ],
    );
  }
}
