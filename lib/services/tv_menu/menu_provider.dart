import 'package:PiliPlus/services/tv_menu/models/menu_item.dart';
import 'package:flutter/material.dart';

/// Abstract interface for menu content providers
/// Each scene (video playback, browsing, etc.) can implement this interface
/// to provide scene-specific menu items
abstract class MenuProvider {
  /// Display name for this menu provider (for debugging)
  String get sceneName;

  /// Priority - higher priority providers are checked first
  int get priority => 0;

  /// Check if this provider can handle the current context
  bool canHandle(BuildContext context);

  /// Get the list of menu items for the current context
  List<TvMenuItem> getMenuItems(BuildContext context);
}
