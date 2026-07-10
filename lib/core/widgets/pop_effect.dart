import 'package:flutter/material.dart';

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
