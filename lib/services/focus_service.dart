import 'package:get/get.dart';

class FocusContext {
  final String contextType;
  final dynamic focusData;

  FocusContext({required this.contextType, this.focusData});
}

class FocusService extends GetxService {
  final Rx<FocusContext?> _currentFocus = Rx<FocusContext?>(null);

  FocusContext? get currentFocus => _currentFocus.value;

  void setFocus(String contextType, {dynamic focusData}) {
    _currentFocus.value = FocusContext(contextType: contextType, focusData: focusData);
  }

  void clearFocus() {
    _currentFocus.value = null;
  }
}
