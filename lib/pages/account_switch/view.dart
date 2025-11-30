import 'package:PiliPlus/utils/accounts/account.dart';
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
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Obx(
                () => Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  alignment: WrapAlignment.center,
                  children: [
                    ...controller.accounts.map((account) {
                      final bool isLoginAccount = account is LoginAccount;
                      return GestureDetector(
                        onTap: () => controller.switchAccount(account),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.account_circle, size: 100),
                            const SizedBox(height: 10),
                            Text(
                              isLoginAccount
                                  ? (account as LoginAccount).userId
                                  : 'Anonymous',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
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
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
