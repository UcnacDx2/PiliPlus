import 'package:PiliPlus/services/tv_menu/models/menu_item.dart';
import 'package:flutter/material.dart';

class MenuBuilder {
  final List<MenuItem> _items = [];

  MenuBuilder addItem(String label, IconData icon, VoidCallback onTap) {
    _items.add(MenuItem(label: label, icon: icon, onTap: onTap));
    return this;
  }

  List<MenuItem> build() => _items;
}
