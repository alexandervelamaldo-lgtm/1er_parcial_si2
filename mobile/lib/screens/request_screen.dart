import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/emergency_provider.dart';
import '../providers/session_provider.dart';
import '../services/api_service.dart';


class RequestScreen extends StatefulWidget {
  const RequestScreen({super.key});

  @override
  State<RequestScreen> createState() => _RequestScreenState();
}


class _RequestScreenState extends State<RequestScreen> {
  static const Map<int, String> _tiposIncidente = {
    1: 'Llanta ponchada',
    2: 'Sin combustible',
    3: 'Falla mecánica',
    4: 'Accidente',
    5: 'Bloqueo de tráfico',
  };

  final _descriptionController = TextEditingController();
  bool _esCarretera = false;
  int _nivelRiesgo = 3;
  int? _vehiculoId;
  int _tipoIncidenteId = 1;
  XFile? _photo;
  bool _sending = false;

  @override
  Widget build(BuildContext context) {
    final emergencyProvider = context.watch<EmergencyProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva asistencia')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<int>(
            value: _vehiculoId,
            decoration: const InputDecoration(
              labelText: 'Vehículo',
              border: OutlineInputBorder(),
            ),
            items: emergencyProvider.vehiculos
                .map(
                  (vehiculo) => DropdownMenuItem<int>(
                    value: vehiculo.id,
                    child: Text('${vehiculo.marca} ${vehiculo.modelo} · ${vehiculo.placa}'),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _vehiculoId = value),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            value: _tipoIncidenteId,
            decoration: const InputDecoration(
              labelText: 'Tipo de incidente',
              border: OutlineInputBorder(),
            ),
            items: _tiposIncidente.entries
                .map(
                  (entry) => DropdownMenuItem<int>(
                    value: entry.key,
                    child: Text(entry.value),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _tipoIncidenteId = value ?? 1),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Descripción del incidente',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            value: _esCarretera,
            title: const Text('¿El incidente ocurrió en carretera?'),
            onChanged: (value) => setState(() => _esCarretera = value),
          ),
          const SizedBox(height: 8),
          Text('Nivel de riesgo: $_nivelRiesgo'),
          Slider(
            value: _nivelRiesgo.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            onChanged: (value) => setState(() => _nivelRiesgo = value.toInt()),
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: _pickImage,
            child: Text(_photo == null ? 'Adjuntar foto' : 'Foto seleccionada: ${_photo!.name}'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _sending ? null : _sendRequest,
            child: Text(_sending ? 'Enviando...' : 'Solicitar asistencia'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.camera);
    setState(() => _photo = result);
  }

  Future<void> _sendRequest() async {
    final messenger = ScaffoldMessenger.of(context);
    final sessionProvider = context.read<SessionProvider>();
    final token = sessionProvider.token;

    if (token == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Sesión no válida')));
      return;
    }
    if (_vehiculoId == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Selecciona un vehículo')));
      return;
    }
    final clienteId = sessionProvider.profile?.clienteId;
    if (clienteId == null) {
      messenger.showSnackBar(const SnackBar(content: Text('No se encontró el perfil del cliente')));
      return;
    }

    setState(() => _sending = true);
    try {
      final position = await Geolocator.getCurrentPosition();
      await context.read<ApiService>().crearSolicitud(
            token: token,
            clienteId: clienteId,
            vehiculoId: _vehiculoId!,
            tipoIncidenteId: _tipoIncidenteId,
            descripcion: _descriptionController.text.trim(),
            latitud: position.latitude,
            longitud: position.longitude,
            esCarretera: _esCarretera,
            nivelRiesgo: _nivelRiesgo,
            fotoUrl: _photo?.path,
          );
      await context.read<EmergencyProvider>().cargarDatos(token);
      messenger.showSnackBar(const SnackBar(content: Text('Solicitud creada correctamente')));
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('No se pudo enviar la solicitud')));
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }
}
