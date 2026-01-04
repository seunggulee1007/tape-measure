import 'dart:io';
import 'package:flutter/material.dart';
import 'ar_ruler_ios.dart';
import 'ar_ruler_android.dart';

class RulerScreen extends StatelessWidget {
  const RulerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 플랫폼에 따라 적절한 AR 화면 표시
    if (Platform.isIOS) {
      return const ARRulerIOS();
    } else if (Platform.isAndroid) {
      return const ARRulerAndroid();
    } else {
      // 지원하지 않는 플랫폼
      return Scaffold(
        appBar: AppBar(
          title: const Text('📏 AR 줄자'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.orange,
                ),
                SizedBox(height: 16),
                Text(
                  'AR 줄자는 iOS와 Android에서만\n사용할 수 있습니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
