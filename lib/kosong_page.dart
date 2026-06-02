import 'package:flutter/material.dart';
import 'package:pos_mobile/Configuration/components.dart';
import 'package:pos_mobile/Configuration/configuration.dart';

class KosongPage extends StatelessWidget {
  const KosongPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Warna.bg,
      appBar: MyAppBar(title: 'Empty Page'),
      body: Center(child: Column()),
    );
  }
}
