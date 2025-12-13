
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DpadTestPage extends StatefulWidget {
  const DpadTestPage({super.key});

  @override
  State<DpadTestPage> createState() => _DpadTestPageState();
}

class _DpadTestPageState extends State<DpadTestPage> {
  String _log = '';
  bool _checkboxValue = false;
  int? _radioValue = 1;

  @override
  void initState() {
    super.initState();
    ServicesBinding.instance.keyboard.addHandler(_onKeyEvent);
  }

  @override
  void dispose() {
    ServicesBinding.instance.keyboard.removeHandler(_onKeyEvent);
    super.dispose();
  }

  bool _onKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      setState(() {
        _log += 'KeyDown: ${event.logicalKey.keyLabel}\n';
      });
    } else if (event is KeyUpEvent) {
      setState(() {
        _log += 'KeyUp: ${event.logicalKey.keyLabel}\n';
      });
    } else if (event is KeyRepeatEvent) {
      setState(() {
        _log += 'KeyRepeat: ${event.logicalKey.keyLabel}\n';
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('D-pad Test Page'),
      ),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: ListView(
              children: [
                const Text('Test Widgets'),
                const Divider(),
                ListTile(
                  title: const Text('Button'),
                  trailing: ElevatedButton(
                    onPressed: () => setState(() => _log += 'Button Clicked\n'),
                    child: const Text('Click Me'),
                  ),
                ),
                ListTile(
                  title: const Text('Text Field'),
                  trailing: SizedBox(
                    width: 200,
                    child: TextField(
                      onChanged: (value) =>
                          setState(() => _log += 'TextField Changed: $value\n'),
                    ),
                  ),
                ),
                ListTile(
                  title: const Text('Checkbox'),
                  trailing: Checkbox(
                    value: _checkboxValue,
                    onChanged: (value) {
                      setState(() {
                        _checkboxValue = value!;
                        _log += 'Checkbox Changed: $value\n';
                      });
                    },
                  ),
                ),
                ListTile(
                  title: const Text('Radio Buttons'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Radio<int>(
                        value: 1,
                        groupValue: _radioValue,
                        onChanged: (value) {
                          setState(() {
                            _radioValue = value;
                            _log += 'Radio Button 1 Changed: $value\n';
                          });
                        },
                      ),
                      Radio<int>(
                        value: 2,
                        groupValue: _radioValue,
                        onChanged: (value) {
                          setState(() {
                            _radioValue = value;
                            _log += 'Radio Button 2 Changed: $value\n';
                          });
                        },
                      ),
                    ],
                  ),
                ),
                ListTile(
                  title: const Text('Dialog'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      setState(() => _log += 'Show Dialog\n');
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Test Dialog'),
                          content: SizedBox(
                            width: 200,
                            child: TextField(
                              onChanged: (value) => setState(
                                  () => _log += 'Dialog TextField Changed: $value\n'),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                setState(() => _log += 'Dialog OK Clicked\n');
                                Navigator.of(context).pop();
                              },
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text('Show Dialog'),
                  ),
                ),
                ListTile(
                  title: const Text('Player Controls'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.play_arrow),
                        onPressed: () =>
                            setState(() => _log += 'Play Button Clicked\n'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.pause),
                        onPressed: () =>
                            setState(() => _log += 'Pause Button Clicked\n'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.stop),
                        onPressed: () =>
                            setState(() => _log += 'Stop Button Clicked\n'),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  title: const Text('Popup Menu'),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 1,
                        child: const Text('Option 1'),
                        onTap: () =>
                            setState(() => _log += 'Popup Option 1 Selected\n'),
                      ),
                      PopupMenuItem(
                        value: 2,
                        child: const Text('Option 2'),
                        onTap: () =>
                            setState(() => _log += 'Popup Option 2 Selected\n'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.grey[200],
              child: SingleChildScrollView(
                child: Text(_log),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
