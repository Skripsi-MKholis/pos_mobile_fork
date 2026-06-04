import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bounce_tapper/bounce_tapper.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:pos_mobile/kosong_page.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:pos_mobile/configuration/configuration.dart';
export 'package:bounce_tapper/bounce_tapper.dart';
import 'package:dotted_dashed_line/dotted_dashed_line.dart';
import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String imageUrl;
  final Color color;
  final List<Widget>? actions;
  final Widget? leading;
  final bool isCenter;

  const MyAppBar({
    super.key,
    required this.title,
    this.color = Colors.black,
    this.imageUrl = '',
    this.actions,
    this.leading,
    this.isCenter = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    bool showImage = false;
    if (imageUrl.isEmpty || imageUrl == '') {
      showImage = false;
    } else {
      showImage = true;
    }
    return AppBar(
      centerTitle: isCenter,
      leading: leading,
      title: Row(
        mainAxisAlignment: isCenter
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(width: 10),
          showImage
              ? Image.asset(imageUrl, width: 30, height: 30)
              : Container(),
        ],
      ),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      actions: actions,
    );
  }
}

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,

      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.white),
            child: Column(
              children: [
                Image.asset(
                  'assets/images/brand/poltek.png',
                  width: 80,
                  height: 80,
                ),
                SizedBox(height: 10),
                Text(
                  'E-Konsul PNL',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: Warna.primary,
                  ),
                ),
              ],
            ),
          ),

          /* ITEM */
          myDrawerItem(
            context,
            () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('userRole', 'admin');
              await prefs.setBool('isLoggedIn', true);
              if (!context.mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const KosongPage()),
              );
            },
            'Login Sebagai Admin',
            TablerIcons.key,
          ),
          myDrawerItem(
            context,
            () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('userRole', 'dosen');
              await prefs.setBool('isLoggedIn', true);
              if (!context.mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const KosongPage()),
              );
            },
            'Login Sebagai Dosen',
            TablerIcons.user_circle,
          ),
          myDrawerItem(
            context,
            () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('userRole', 'mahasiswa');
              await prefs.setBool('isLoggedIn', true);
              if (!context.mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const KosongPage()),
              );
            },
            'Login Sebagai Mahasiswa',
            TablerIcons.users,
          ),
          myDrawerItem(
            context,
            () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('userRole');
              await prefs.setBool('isLoggedIn', false);
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => KosongPage()),
                (route) => false,
              );
            },
            'Log out',
            TablerIcons.logout,
          ),
          /* ITEM */
        ],
      ),
    );
  }
}

Widget myDrawerItem(
  BuildContext context,
  VoidCallback onTap,
  String title,
  IconData icon,
) {
  return BounceTapper(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Warna.bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.black),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const Icon(TablerIcons.chevron_right, color: Colors.black),
        ],
      ),
    ),
  );
}

Widget myTextField({
  required TextEditingController controller,
  FocusNode? focusNode,
  String labelText = '',
  required String placeholder,
  TextInputType? keyboardType,
  TextCapitalization textCapitalization = TextCapitalization.none,
  bool obscureText = false,
  String? Function(String?)? validator,
  int maxLines = 1,
  Widget? prefix,
  Widget? suffix,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      labelText.isEmpty
          ? Container()
          : Container(
              padding: const EdgeInsets.all(8),
              child: Text(
                labelText,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
      TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 14), // Ukuran teks input
        decoration: InputDecoration(
          hintText: placeholder, // Ganti labelText dengan hintText
          hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
          prefixIcon: prefix,
          suffixIcon: suffix,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.transparent),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.transparent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Warna.primary.withValues(alpha: 0.2)),
          ),
          filled: true,
          fillColor: const Color(0xFFF6F8FA),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 12,
          ), // padding dalam input
        ),
      ),
    ],
  );
}

Widget mySelectField({
  required String labelText,
  required String? selectedValue,
  required List<String> items,
  required void Function(String?) onChanged,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        child: Text(
          labelText,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
      Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF6F8FA),
          borderRadius: BorderRadius.circular(12.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButtonFormField<String>(
          initialValue: selectedValue,
          onChanged: onChanged,
          icon: const Icon(Icons.arrow_drop_down),
          dropdownColor: Colors.white,
          elevation: 0,
          style: const TextStyle(fontSize: 14, color: Colors.black),
          decoration: InputDecoration(
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    ],
  );
}

Widget myInputFile({
  required String labelText,
  required String? fileName,
  required VoidCallback onTap,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        child: Text(
          labelText,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F8FA),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: Colors.grey), // border luar
          ),
          child: Row(
            children: [
              const Icon(Icons.upload_file, size: 20, color: Colors.grey),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  fileName ?? 'Pilih file...',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: fileName == null ? Colors.grey : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

Widget mySelectDate({
  required String labelText,
  required String? selectedDate,
  required VoidCallback onTap,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        child: Text(
          labelText,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F8FA),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
              const SizedBox(width: 10),
              Text(
                selectedDate ?? 'Pilih tanggal',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: selectedDate == null ? Colors.grey : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

Widget mySelectTime({
  required String labelText,
  required String? selectedTime,
  required VoidCallback onTap,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        child: Text(
          labelText,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F8FA),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              const Icon(Icons.access_time, size: 18, color: Colors.grey),
              const SizedBox(width: 10),
              Text(
                selectedTime ?? 'Pilih waktu',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: selectedTime == null ? Colors.grey : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

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

class MyButtonSecondary extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final Widget? child;
  final double? width;
  final double radius;

  const MyButtonSecondary({
    super.key,
    this.onPressed,
    this.backgroundColor = Warna.primary,
    this.foregroundColor = Warna.primary,
    this.child,
    this.width = double.infinity,
    this.radius = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: MyButtonPrimary(
        onPressed: onPressed,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        isOutlined: true,
        radius: radius,
        child: child,
      ),
    );
  }
}

/* LOADING */
class MyLoading extends StatelessWidget {
  final Color color;
  final double size;

  const MyLoading({super.key, this.color = Colors.black, this.size = 35.0});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(9),
        ),
        child: LoadingAnimationWidget.progressiveDots(color: color, size: size),
      ),
    );
  }
}

/* LOADING */

/* SNACKBAR */
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
        style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: textColor,
        ),
      ),
    ),
  ).show(context);
}

/* SNACKBAR */

class MyDivider extends StatelessWidget {
  const MyDivider({
    super.key,
    this.height = 0,
    this.padding = 0,
    this.dashColor = Colors.grey,
    this.width = double.infinity,
    this.axis = Axis.horizontal,
  });

  final double height;
  final double padding;
  final Color dashColor;
  final double width;
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: padding),
      margin: EdgeInsets.symmetric(vertical: 10),
      child: DottedDashedLine(
        height: height,
        dashColor: dashColor,
        width: width,
        axis: axis,
      ),
    );
  }
}

class MyNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;

  const MyNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: width ?? double.infinity,
            height: height ?? double.infinity,
            color: Colors.white,
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: width ?? double.infinity,
          height: height ?? double.infinity,
          color: const Color(0xFFF6F8FA),
          child: const Center(
            child: Icon(TablerIcons.photo_off, color: Colors.grey, size: 24),
          ),
        ),
      ),
    );
  }
}
