import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../pages/common/common_intro_controller.dart';

class EpisodePanel extends StatelessWidget {
  final CommonIntroController controller;
  final String heroTag;

  const EpisodePanel({
    super.key,
    required this.controller,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '选集',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 2.5,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: controller.videoDetail.value.pages?.length ?? 0,
              itemBuilder: (context, index) {
                final page = controller.videoDetail.value.pages![index];
                final isSelected = page.cid == controller.cid.value;
                return GestureDetector(
                  onTap: () {
                    controller.onChangeEpisode(page);
                    Get.back();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        page.part ?? 'P${index + 1}',
                        style: TextStyle(
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
