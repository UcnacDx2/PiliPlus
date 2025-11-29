import 'package:flutter/material.dart';
import 'package:get/get.dart';

Future<bool> showConfirmDialog({
  required BuildContext context,
  required String title,
  Object? content,
  // @Deprecated('use `bool result = await showConfirmDialog()` instead')
  VoidCallback? onConfirm,
}) async {
  assert(content is String? || content is Widget);
  return await showDialog<bool>(
        context: context,
        builder: (context) {
          return FocusScope(
            child: AlertDialog(
              title: Text(title),
              content: content is String
                  ? Text(content)
                  : content is Widget
                      ? content
                      : null,
              actions: [
                TextButton(
                  onPressed: Get.back,
                  child: Text(
                    '取消',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
                TextButton(
                  autofocus: true,
                  onPressed: () {
                    Get.back(result: true);
                    onConfirm?.call();
                  },
                  child: const Text('确认'),
                ),
              ],
            ),
          );
        },
      ) ??
      false;
}

void showPgcFollowDialog({
  required BuildContext context,
  required String type,
  required int followStatus,
  required ValueChanged<int> onUpdateStatus,
}) {
  Widget statusItem({
    required bool enabled,
    required String text,
    required VoidCallback onTap,
    bool autofocus = false,
  }) {
    return ListTile(
      dense: true,
      enabled: enabled,
      autofocus: autofocus,
      title: Padding(
        padding: const EdgeInsets.only(left: 10),
        child: Text(
          '标记为 $text',
          style: const TextStyle(fontSize: 14),
        ),
      ),
      trailing: !enabled ? const Icon(size: 22, Icons.check) : null,
      onTap: onTap,
    );
  }

  showDialog(
    context: context,
    builder: (context) {
      bool autoFocused = false;
      return FocusScope(
        child: AlertDialog(
          clipBehavior: Clip.hardEdge,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...[
                (followStatus: 3, title: '看过'),
                (followStatus: 2, title: '在看'),
                (followStatus: 1, title: '想看'),
              ].map(
                (item) {
                  final bool enabled = followStatus != item.followStatus;
                  final bool autofocus = enabled && !autoFocused;
                  if (autofocus) {
                    autoFocused = true;
                  }
                  return statusItem(
                    enabled: enabled,
                    text: item.title,
                    autofocus: autofocus,
                    onTap: () {
                      Get.back();
                      onUpdateStatus(item.followStatus);
                    },
                  );
                },
              ).toList(),
              ListTile(
                dense: true,
                title: Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Text(
                    '取消$type',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                onTap: () {
                  Get.back();
                  onUpdateStatus(-1);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
