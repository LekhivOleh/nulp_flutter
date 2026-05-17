import 'package:flutter/material.dart';
import 'package:my_project/services/connectivity_service.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({required this.service, super.key});

  final ConnectivityService service;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: service.connectionStatusStream,
      initialData: service.isConnected,
      builder: (_, snapshot) {
        if (snapshot.data ?? true) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: Colors.orange,
          child: const Row(
            children: [
              Icon(Icons.cloud_off, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'No internet connection.\nSaved sessions may still work.',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
