import 'package:flutter/material.dart';
import 'package:piliplus/services/tv_menu/models/menu_item.dart';

abstract class MenuProvider {
  String get sceneName;
  List<MenuItem> getMenuItems(BuildContext context);
  bool canHandle(BuildContext context);
}
