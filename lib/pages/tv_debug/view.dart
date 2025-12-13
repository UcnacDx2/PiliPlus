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
