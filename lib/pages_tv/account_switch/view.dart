import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/member.dart';
import 'package:PiliPlus/models/common/account_type.dart';
import 'package:PiliPlus/models_new/space/space/data.dart';
import 'package:PiliPlus/pages_tv/common/tv_focus_wrapper.dart';
import 'package:PiliPlus/pages_tv/common/tv_page.dart';
import 'package:PiliPlus/utils/accounts.dart';
import 'package:PiliPlus/utils/accounts/account.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class TVAccountSwitchPage extends StatefulWidget {
  const TVAccountSwitchPage({super.key});

  @override
  State<TVAccountSwitchPage> createState() => _TVAccountSwitchPageState();
}

class _TVAccountSwitchPageState extends State<TVAccountSwitchPage> {
  late final List<LoginAccount> _profiles;
  final Map<int, SpaceData> _userInfo = {};

  @override
  void initState() {
    super.initState();
    _profiles = Accounts.account.values.toList(growable: false);
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    for (final profile in _profiles) {
      final res = await MemberHttp.space(mid: profile.mid);
      if (!mounted) return;
      if (res case Success(:final response)) {
        setState(() => _userInfo[profile.mid] = response);
      }
    }
  }

  Future<void> _selectAccount(LoginAccount account) async {
    SmartDialog.showLoading(msg: '正在切换账号');
    try {
      await Accounts.set(AccountType.main, account);
      await Accounts.set(AccountType.heartbeat, account);
      await Accounts.set(AccountType.recommend, account);
      await Accounts.set(AccountType.video, account);
      if (mounted) {
        SmartDialog.showToast('账号切换成功');
        Get.offAllNamed('/');
      }
    } finally {
      SmartDialog.dismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TVPage(
      child: Scaffold(
        appBar: AppBar(title: const Text('选择账号')),
        body: GridView.builder(
          padding: const EdgeInsets.all(32),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 24,
            crossAxisSpacing: 24,
            childAspectRatio: 1.15,
          ),
          itemCount: _profiles.length + 1,
          itemBuilder: (context, index) {
            if (index == _profiles.length) {
              return TVFocusWrapper(
                onSelect: () => Get.toNamed('/tvLogin'),
                scaleFactor: 1.05,
                borderRadius: 16,
                child: Card(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        size: 64,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      const Text('添加账号'),
                    ],
                  ),
                ),
              );
            }

            final profile = _profiles[index];
            final card = _userInfo[profile.mid]?.card;
            final isCurrent = Accounts.main.mid == profile.mid;
            return TVFocusWrapper(
              autoFocus: isCurrent || (index == 0 && !Accounts.main.isLogin),
              onSelect: () => _selectAccount(profile),
              scaleFactor: 1.05,
              borderRadius: 16,
              child: Card(
                color: isCurrent
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 42,
                        backgroundImage: card?.face?.isNotEmpty == true
                            ? NetworkImage(card!.face!)
                            : null,
                        child: card?.face?.isNotEmpty == true
                            ? null
                            : const Icon(Icons.person, size: 44),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        card?.name ?? 'UID ${profile.mid}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                      if (isCurrent)
                        Text(
                          '当前账号',
                          style: TextStyle(color: theme.colorScheme.primary),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
