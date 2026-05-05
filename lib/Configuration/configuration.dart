import 'package:flutter/material.dart';

class Warna {
  static const Color primary = Color(0xFF9AE600);
  static const Color success = Color(0xFF10B981);
  static const Color destructive = Color(0xFFE11D48);
  static const Color neutral = Color(0xFFF8FAFC);

  static const Color black = Color(0xFF121212);
  static const Color textBold = Color(0xFF121212);
  static const Color bg = Color(0xFFFFFFFF);
  static const Color line = Color(0xFFE2E8F0);

  // Dark mode
  static const Color darkBG = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkLine = Color(0xFF334155);
}

class HexColor extends Color {
  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));

  static int _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return int.parse(hexColor, radix: 16);
  }
}

/* Efek Pop */

class PopController {
  void Function()? _triggerPop;

  void _register(void Function() callback) {
    _triggerPop = callback;
  }

  void pop() {
    _triggerPop?.call();
  }
}

class PopEffect extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double scale;
  final PopController? controller;

  const PopEffect({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 150),
    this.scale = 0.9,
    this.controller,
  });

  @override
  State<PopEffect> createState() => _PopEffectState();
}

class _PopEffectState extends State<PopEffect>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    widget.controller?._register(_runPop);
  }

  void _runPop() async {
    setState(() => _scale = widget.scale);
    await Future.delayed(widget.duration);
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _scale,
      duration: widget.duration,
      child: widget.child,
    );
  }
}

/* Efek Pop */
