import 'package:flutter/material.dart';
import 'package:bounce_tapper/bounce_tapper.dart';

ButtonStyle myButtonStyle({
  Color backgroundColor = Colors.white,
  Color foregroundColor = Colors.black,
  double radius = 16.0,
  final bool isOutlined = false,
}) {
  return ElevatedButton.styleFrom(
    backgroundColor: isOutlined ? Colors.white : backgroundColor,
    foregroundColor: isOutlined ? backgroundColor : foregroundColor,

    elevation: 0,
    shadowColor: Colors.black.withValues(alpha: 0.5),
    padding: const EdgeInsets.symmetric(vertical: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: backgroundColor, width: isOutlined ? 1.5 : 0),
    ),
  );
}

class MyButtonPrimary extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final Widget? child;
  final double? width;
  final double radius;
  final bool isOutlined;

  const MyButtonPrimary({
    super.key,
    this.onPressed,
    this.backgroundColor = const Color(0xffD4D4D8),
    this.foregroundColor = Colors.black,
    this.child,
    this.width = double.infinity,
    this.radius = 16.0,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: BounceTapper(
        highlightColor: Colors.transparent,
        child: SizedBox(
          width: width,
          child: ElevatedButton(
            style: myButtonStyle(
              backgroundColor: backgroundColor,
              foregroundColor: foregroundColor,
              radius: radius,
              isOutlined: isOutlined,
            ),
            onPressed: onPressed,
            child: child,
          ),
        ),
      ),
    );
  }
}
