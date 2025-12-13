import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controller.dart';

class TvDebugPage extends GetView<TvDebugController> {
  const TvDebugPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TV Debug Page'),
      ),
      body: Obx(
        () => Column(
          children: [
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: 20,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Focus(
                      onKey: controller.onKey,
                      child: ElevatedButton(
                        onPressed: () {
                          Get.dialog(
                            AlertDialog(
                              title: const Text('Test Dialog'),
                              content: const Text('This is a test dialog.'),
                              actions: [
                                TextButton(
                                  onPressed: Get.back,
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: const Text('Show Dialog'),
                      ),
                    );
                  }
                  return Focus(
                    onKey: controller.onKey,
                    child: ElevatedButton(
                      onPressed: () {},
                      child: Text('Button $index'),
                    ),
                  );
                },
              ),
            ),
            Container(
              height: 100,
              color: Colors.black,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Focus(
                    onKey: controller.onKey,
                    child: IconButton(
                      icon: const Icon(Icons.play_arrow, color: Colors.white),
                      onPressed: () {},
                    ),
                  ),
                  Focus(
                    onKey: controller.onKey,
                    child: IconButton(
                      icon: const Icon(Icons.pause, color: Colors.white),
                      onPressed: () {},
                    ),
                  ),
                  Focus(
                    onKey: controller.onKey,
                    child: IconButton(
                      icon: const Icon(Icons.stop, color: Colors.white),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: controller.logs.length,
                itemBuilder: (context, index) {
                  return Text(
                    controller.logs[index],
                    style: const TextStyle(fontSize: 12.0),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
