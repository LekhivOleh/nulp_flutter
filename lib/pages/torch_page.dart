import 'dart:async';

import 'package:flutter/material.dart';
import 'package:torch_controller/torch_controller.dart';

class TorchPage extends StatefulWidget {
  const TorchPage({super.key});

  static const String routeName = '/torch';

  @override
  State<TorchPage> createState() => _TorchPageState();
}

class _TorchPageState extends State<TorchPage> {
  bool _isOn = false;

  @override
  void dispose() {
    if (_isOn) unawaited(TorchController.offLight());
    super.dispose();
  }

  void _toggle() {
    unawaited(
      TorchController.toggle().then(
        (newState) {
          if (mounted) setState(() => _isOn = newState);
        },
        onError: (Object e, StackTrace s) {
          if (e is TorchPlatformException && mounted) {
            _showUnsupportedDialog();
          }
        },
      ),
    );
  }

  void _showUnsupportedDialog() {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Not Supported'),
          content: const Text(
            'Torch control is not supported on this platform.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secret Torch'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isOn ? Icons.lightbulb : Icons.lightbulb_outline,
              size: 100,
              color: _isOn ? Colors.amber : Colors.grey,
            ),
            const SizedBox(height: 24),
            Text(
              _isOn ? 'Torch is ON' : 'Torch is OFF',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _toggle,
              icon: Icon(_isOn ? Icons.flashlight_off : Icons.flashlight_on),
              label: Text(_isOn ? 'Turn Off' : 'Turn On'),
            ),
          ],
        ),
      ),
    );
  }
}
