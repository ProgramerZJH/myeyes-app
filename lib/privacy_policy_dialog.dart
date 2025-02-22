import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;
//import 'package:myeyes/amap_initializer.dart';

class PrivacyPolicyDialog extends StatelessWidget {
  final Function(bool) onAgreed;

  const PrivacyPolicyDialog({
    Key? key,
    required this.onAgreed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('隐私政策'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            const Text(
              '本应用使用高德开放平台位置服务SDK，需要收集：\n'
              '1. 位置信息：用于导航和定位服务\n'
              '2. 设备信息：用于地图服务性能优化\n'
              '3. 网络状态：用于在线地图和路径规划\n\n'
              '您可以查看完整的隐私政策和高德地图隐私权政策了解详情。\n\n'
              '继续使用表示您同意我们的隐私政策。',
              style: TextStyle(fontSize: 14),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () async {
                    // 这里需要替换成你自己的隐私政策URL
                    final Uri url = Uri.parse(
                        'https://github.com/ProgramerZJH/MyEyesPrivacy/blob/main/privacy_policy.md');
                    if (await launcher.canLaunchUrl(url)) {
                      await launcher.launchUrl(
                        url,
                        mode: launcher.LaunchMode.externalApplication,
                      );
                    }
                  },
                  child: const Text('My Eyes 隐私政策'),
                ),
                TextButton(
                  onPressed: () async {
                    final Uri url =
                        Uri.parse('https://lbs.amap.com/pages/privacy/');
                    if (await launcher.canLaunchUrl(url)) {
                      await launcher.launchUrl(
                        url,
                        mode: launcher.LaunchMode.externalApplication,
                      );
                    }
                  },
                  child: const Text('高德隐私政策'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('同意'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('不同意'),
        ),
      ],
    );
  }
}
