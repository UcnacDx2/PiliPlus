import 'package:flutter/material.dart';

class PiliPopupMenuItem {
  final String title;
  final Widget icon;
  final VoidCallback onTap;

  const PiliPopupMenuItem({
    required this.title,
    required this.icon,
    required this.onTap,
  });
}

Future<void> showPiliPopupMenu({
  required BuildContext context,
  required List<PiliPopupMenuItem> items,
}) async {
  final RenderBox? overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
  if (overlay == null) return;

  final RenderBox? widgetRenderBox = context.findRenderObject() as RenderBox?;
  final Offset widgetPosition = widgetRenderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
  final Size widgetSize = widgetRenderBox?.size ?? Size.zero;

  await showMenu<VoidCallback>(
    context: context,
    color: Colors.black.withOpacity(0.8),
    position: RelativeRect.fromLTRB(
      widgetPosition.dx,
      widgetPosition.dy + widgetSize.height,
      widgetPosition.dx + widgetSize.width,
      widgetPosition.dy + widgetSize.height,
    ),
    items: items.map((item) {
      return PopupMenuItem<VoidCallback>(
        value: item.onTap,
        height: 35,
        child: Row(
          children: [
            item.icon,
            const SizedBox(width: 6),
            Text(
              item.title,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ],
        ),
      );
    }).toList(),
  ).then((callback) {
    callback?.call();
  });
}
