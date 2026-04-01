import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/emergency_provider.dart';


class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmergencyProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Historial de solicitudes')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: provider.solicitudes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final solicitud = provider.solicitudes[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(child: Text('${solicitud.id}')),
              title: Text(solicitud.tipoIncidente),
              subtitle: Text(solicitud.descripcion),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(solicitud.estado),
                  Text(solicitud.prioridad),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
