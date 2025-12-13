import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TvDebugPage extends StatefulWidget {
  const TvDebugPage({super.key});

  @override
  State<TvDebugPage> createState() => _TvDebugPageState();
}

class _TvDebugPageState extends State<TvDebugPage> {
  String _log = '';
  bool _switchValue = false;
  bool? _checkboxValue = false;
  double _sliderValue = 50;
  final TextEditingController _textController = TextEditingController();

  void _logEvent(String event) {
    setState(() {
      _log = '${DateTime.now()}: $event\n$_log';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TV Debug Menu'),
      ),
      body: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: (RawKeyEvent event) {
          if (event is RawKeyDownEvent) {
            _logEvent('Key Down: ${event.logicalKey.keyLabel}');
          }
        },
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: ListView(
                children: [
                  _buildFocusableWidget('ElevatedButton',
                      ElevatedButton(onPressed: () {}, child: const Text('Button'))),
                  _buildFocusableWidget(
                    'Switch',
                    Switch(
                      value: _switchValue,
                      onChanged: (value) {
                        setState(() {
                          _switchValue = value;
                        });
                        _logEvent('Switch toggled: $value');
                      },
                    ),
                  ),
                  _buildFocusableWidget(
                    'Checkbox',
                    Checkbox(
                      value: _checkboxValue,
                      onChanged: (value) {
                        setState(() {
                          _checkboxValue = value;
                        });
                        _logEvent('Checkbox toggled: $value');
                      },
                    ),
                  ),
                  _buildFocusableWidget(
                    'Slider',
                    Slider(
                      value: _sliderValue,
                      min: 0,
                      max: 100,
                      onChanged: (value) {
                        setState(() {
                          _sliderValue = value;
                        });
                        _logEvent('Slider changed: $value');
                      },
                    ),
                  ),
                  _buildFocusableWidget(
                    'TextField',
                    TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Input',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                color: Colors.grey[200],
                padding: const EdgeInsets.all(8.0),
                child: SingleChildScrollView(
                  child: Text(_log),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusableWidget(String name, Widget widget) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Focus(
        onFocusChange: (hasFocus) {
          _logEvent('$name focus: $hasFocus');
        },
        child: widget,
      ),
    );
  }
}
