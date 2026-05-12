import 'package:flutter/material.dart';
import 'package:my_project/services/connectivity_service.dart';

class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({required this.service, super.key});

  final ConnectivityService service;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: service.connectionStatusStream,
      initialData: service.isConnected,
      builder: (_, s) {
        final ok = s.data ?? true;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          color: ok ? Colors.green : Colors.red,
          child: Row(children: [
            Icon(ok ? Icons.cloud_done : Icons.cloud_off, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              ok ? 'Connected' : 'Offline',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ]),
        );
      },
    );
  }
}
