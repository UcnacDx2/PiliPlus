import 'package:PiliPlus/models/user/info.dart';
import 'package:PiliPlus/utils/accounts/account.dart';

class AccountDetails {
  final Account account;
  final UserInfoData? userInfo;

  AccountDetails({required this.account, this.userInfo});
}
