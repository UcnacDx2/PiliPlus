import 'package:PiliPlus/models/user/info.dart';
import 'package:PiliPlus/utils/accounts/account.dart';

class Profile {
  final Account account;
  final UserInfoData userInfo;

  Profile({required this.account, required this.userInfo});
}
