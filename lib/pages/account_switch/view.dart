import 'package:PiliPlus/models/common/account_type.dart';
import 'package:PiliPlus/utils/accounts.dart';
import 'package:PiliPlus/utils/accounts/account.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AccountSwitchPage extends StatefulWidget {
  const AccountSwitchPage({super.key});

  @override
  State<AccountSwitchPage> createState() => _AccountSwitchPageState();
}

class _AccountSwitchPageState extends State<AccountSwitchPage> {
  late final List<LoginAccount> _profiles;

  @override
  void initState() {
    super.initState();
    _profiles = Accounts.account.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Who's watching?"),
      ),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.0,
        ),
        itemCount: _profiles.length + 1,
        itemBuilder: (context, index) {
          if (index < _profiles.length) {
            final profile = _profiles[index];
            return GestureDetector(
              onTap: () async {
                await Accounts.set(AccountType.main, profile);
                Get.back();
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 40,
                    child: Icon(Icons.person),
                  ),
                  const SizedBox(height: 8),
                  Text('User: ${profile.mid}'),
                ],
              ),
            );
          } else {
            return GestureDetector(
              onTap: () {
                Get.toNamed('/loginPage');
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.add_circle_outline, size: 50),
                  SizedBox(height: 8),
                  Text('Add Profile'),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
