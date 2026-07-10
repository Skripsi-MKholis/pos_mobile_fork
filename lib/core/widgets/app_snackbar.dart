import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:pos_mobile/core/theme/app_theme.dart';

enum ToastStatus { success, send, error, info, warning }

void mySnackBar({
  required BuildContext context,
  required String text,
  ToastStatus status = ToastStatus.info,
  IconData? icon,
  Duration duration = const Duration(seconds: 2),
}) {
  // Tentukan warna dan ikon berdasarkan status
  Color bgColor;
  Color textColor;
  IconData defaultIcon;

  switch (status) {
    case ToastStatus.success:
      bgColor = const Color(0xFFE8FAF0); // green-100
      textColor = const Color(0xff1AC966);
      defaultIcon = TablerIcons.circle_check;
      break;
    case ToastStatus.send:
      bgColor = const Color(0xFFE8FAF0); // green-100
      textColor = const Color(0xff1AC966);
      defaultIcon = TablerIcons.send;
      break;
    case ToastStatus.error:
      bgColor = const Color(0xFFFEE2E2); // red-100
      textColor = Colors.red[400]!;
      defaultIcon = TablerIcons.circle_x;
      break;
    case ToastStatus.warning:
      bgColor = const Color(0xFFFFF7CD); // yellow-100
      textColor = const Color(0xffC4841D);
      defaultIcon = TablerIcons.alert_circle;
      break;
    case ToastStatus.info:
      bgColor = const Color(0xFFE6F1FE); // yellow-100
      textColor = const Color(0xff005BC4);
      defaultIcon = TablerIcons.info_circle;
      break;
  }

  DelightToastBar(
    autoDismiss: true,
    snackbarDuration: duration,
    builder: (context) => ToastCard(
      color: bgColor,
      leading: Icon(icon ?? defaultIcon, size: 28, color: textColor),
      title: Text(
        text,
        style: AppFonts.body(fontWeight: FontWeight.w700, fontSize: 14, color: textColor),
      ),
    ),
  ).show(context);
}
