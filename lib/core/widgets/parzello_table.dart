import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class ParzelloColumn {
  final String title;
  final double? width;
  final bool isFlex;
  final TextAlign textAlign;

  ParzelloColumn({
    required this.title,
    this.width,
    this.isFlex = false,
    this.textAlign = TextAlign.start,
  });
}

class ParzelloTable extends StatelessWidget {
  final List<ParzelloColumn> columns;
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final double totalWidth;
  final Future<void> Function()? onRefresh;
  final Widget? emptyWidget;

  const ParzelloTable({
    super.key,
    required this.columns,
    required this.itemCount,
    required this.itemBuilder,
    required this.totalWidth,
    this.onRefresh,
    this.emptyWidget,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: totalWidth,
        child: Column(
          children: [
            // Table Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: columns.map((col) {
                  final text = Text(
                    col.title,
                    style: theme.textTheme.muted.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: col.textAlign,
                  );

                  if (col.isFlex) {
                    return Expanded(
                      child: col.textAlign == TextAlign.center
                          ? Center(child: text)
                          : text,
                    );
                  }
                  return SizedBox(
                    width: col.width,
                    child: col.textAlign == TextAlign.center
                        ? Center(child: text)
                        : text,
                  );
                }).toList(),
              ),
            ),
            const Divider(indent: 24, endIndent: 24, height: 1),

            // Table Body
            Expanded(
              child: RefreshIndicator(
                onRefresh: onRefresh ?? () async {},
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  itemCount: itemCount,
                  itemBuilder: itemBuilder,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ParzelloTableRow extends StatelessWidget {
  final List<Widget> children;
  final List<ParzelloColumn> columns;
  final VoidCallback? onTap;

  const ParzelloTableRow({
    super.key,
    required this.children,
    required this.columns,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.border.withValues(alpha: 0.5),
            ),
          ),
        ),
        child: Row(
          children: List.generate(children.length, (index) {
            final child = children[index];
            final col = columns[index];

            if (col.isFlex) {
              return Expanded(child: child);
            }
            return SizedBox(width: col.width, child: child);
          }),
        ),
      ),
    );
  }
}
