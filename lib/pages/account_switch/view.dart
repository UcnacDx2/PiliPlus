import 'package:PiliPlus/http/member.dart';
import 'package:PiliPlus/models/common/account_type.dart';
import 'package:PiliPlus/models_new/space/space/data.dart';
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
  final Map<int, SpaceData> _userInfo = {};
  final List<FocusNode> _focusNodes = [];

  @override
  void initState() {
    super.initState();
    _profiles = Accounts.account.values.toList();
    _focusNodes.addAll(List.generate(_profiles.length + 1, (index) => FocusNode()));
    _fetchUserInfo();
  }

  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchUserInfo() async {
    for (var profile in _profiles) {
      final res = await MemberHttp.space(mid: profile.mid);
      if (res.isSuccess) {
        setState(() {
          _userInfo[profile.mid] = res.data;
        });
      }
    }
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
            final userInfo = _userInfo[profile.mid];
            return InkWell(
              focusNode: _focusNodes[index],
              onTap: () async {
                await Accounts.set(AccountType.main, profile);
                await Accounts.set(AccountType.heartbeat, profile);
                await Accounts.set(AccountType.recommend, profile);
                Get.back();
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: userInfo?.card?.face != null
                        ? NetworkImage(userInfo!.card!.face!)
                        : null,
                    child: userInfo?.card?.face == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Text(userInfo?.card?.name ?? 'User: ${profile.mid}'),
                ],
              ),
            );
          } else {
            return InkWell(
              focusNode: _focusNodes[index],
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
