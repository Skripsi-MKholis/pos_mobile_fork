import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:pos_mobile/l10n/app_localizations.dart';

class PillAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PillAppBar({
    required this.title,
    this.showDrawerButton = false,
    this.leading,
    this.actions,
    super.key,
  });

  final String title;
  final bool showDrawerButton;
  final Widget? leading;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    Widget? leadingWidget = leading;
    if (leadingWidget == null && showDrawerButton) {
      leadingWidget = Center(
        child: Container(
          width: 44,
          height: 44,
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
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return IconButton(
                tooltip: l10n.menu,
                icon: const Icon(
                  TablerIcons.menu_2,
                  size: 20,
                  color: Colors.black,
                ),
                onPressed: () => Scaffold.of(context).openDrawer(),
              );
            },
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
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: SizedBox(
              height: 56,
              child: AppBar(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                centerTitle: true,
                leadingWidth: leadingWidget != null ? 56 : 0,
                leading: leadingWidget,
                title: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
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
                      fontSize: 16,
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
