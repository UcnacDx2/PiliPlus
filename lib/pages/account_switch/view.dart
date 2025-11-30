import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controller.dart';

class AccountSwitchPage extends GetView<AccountSwitchController> {
  const AccountSwitchPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Who\'s Watching?'),
        centerTitle: true,
      ),
      body: Obx(
        () {
          if (controller.isLoading.value && controller.accountDetails.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    alignment: WrapAlignment.center,
                    children: [
                      ...controller.accountDetails.map((details) {
                        final userInfo = details.userInfo;
                        return GestureDetector(
                          onTap: () =>
                              controller.switchAccount(details.account),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (userInfo != null)
                                CircleAvatar(
                                  radius: 50,
                                  backgroundImage:
                                      NetworkImage(userInfo.face ?? ''),
                                )
                              else
                                const CircleAvatar(
                                  radius: 50,
                                  child: Icon(Icons.error_outline, size: 50),
                                ),
                              const SizedBox(height: 10),
                              Text(
                                userInfo?.uname ?? 'Error',
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      GestureDetector(
                        onTap: () => controller.addAccount(),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add_circle_outline, size: 100),
                            SizedBox(height: 10),
                            Text(
                              'Add Account',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
