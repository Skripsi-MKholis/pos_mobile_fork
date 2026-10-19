import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class PillAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PillAppBar({
    required this.title,
    this.showDrawerButton = false,
    this.compact = false,
    this.leading,
    this.actions,
    super.key,
  });

  final String title;
  final bool showDrawerButton;
  final bool compact;
  final Widget? leading;
  final List<Widget>? actions;

  @override
  Size get preferredSize => Size.fromHeight(compact ? 54 : 80);

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final buttonSize = compact ? 38.0 : 44.0;
    final iconSize = compact ? 18.0 : 20.0;

    Widget? leadingWidget = leading;
    if (leadingWidget == null && showDrawerButton) {
      leadingWidget = Center(
        child: Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
          child: Builder(
            builder: (context) => IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                TablerIcons.menu_2,
                size: iconSize,
                color: Colors.black,
              ),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),
      );
    }

    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.border.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 16 : 20,
              compact ? 4 : 12,
              compact ? 16 : 20,
              compact ? 4 : 12,
            ),
            child: SizedBox(
              height: compact ? 44 : 56,
              child: AppBar(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                centerTitle: true,
                leadingWidth: leadingWidget != null ? (compact ? 46 : 56) : 0,
                leading: leadingWidget,
                title: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 16 : 20,
                    vertical: compact ? 6 : 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.05),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    title,
                    style: theme.textTheme.h4.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: compact ? 14 : 16,
                      color: Colors.black,
                    ),
                  ),
                ),
                actions: actions,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
