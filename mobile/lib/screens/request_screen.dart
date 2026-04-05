import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
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
  final _evidenceNoteController = TextEditingController();
  bool _esCarretera = false;
  int _nivelRiesgo = 3;
  int? _vehiculoId;
  int _tipoIncidenteId = 1;
  XFile? _photo;
  String? _audioPath;
  String? _audioName;
  bool _sending = false;
  String _gpsStatus = 'GPS pendiente';

  @override
  Widget build(BuildContext context) {
    final emergencyProvider = context.watch<EmergencyProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva asistencia')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<int>(
            initialValue: _vehiculoId,
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
            initialValue: _tipoIncidenteId,
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
          TextField(
            controller: _evidenceNoteController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Nota adicional para evidencias',
              helperText: 'Opcional: contexto extra para revisión IA u operador',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.my_location),
            title: const Text('Estado de geolocalización'),
            subtitle: Text(_gpsStatus),
            trailing: FilledButton.tonal(
              onPressed: _sending ? null : _refreshLocationStatus,
              child: const Text('Verificar'),
            ),
          ),
          const SizedBox(height: 8),
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
          FilledButton.tonal(
            onPressed: _pickAudio,
            child: Text(_audioName == null ? 'Adjuntar audio' : 'Audio seleccionado: $_audioName'),
          ),
          const SizedBox(height: 12),
          Text(
            'Puedes enviar texto, foto y audio en una sola solicitud. El backend transcribe y analiza la evidencia automáticamente.',
            style: Theme.of(context).textTheme.bodySmall,
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

  @override
  void initState() {
    super.initState();
    _refreshLocationStatus();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.camera);
    if (result == null) {
      return;
    }
    setState(() => _photo = result);
  }

  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a'],
      withData: false,
    );
    final file = result?.files.single;
    if (file?.path == null) {
      return;
    }
    setState(() {
      _audioPath = file!.path;
      _audioName = file.name;
    });
  }

  Future<void> _refreshLocationStatus() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() => _gpsStatus = 'Activa el servicio de ubicación para enviar la asistencia');
      }
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() => _gpsStatus = 'Permiso GPS no concedido');
      }
      return;
    }
    final position = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _gpsStatus = 'Última ubicación lista: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      });
    }
  }

  Future<void> _sendRequest() async {
    final messenger = ScaffoldMessenger.of(context);
    final sessionProvider = context.read<SessionProvider>();
    final token = sessionProvider.token;
    final apiService = context.read<ApiService>();
    final emergencyProvider = context.read<EmergencyProvider>();

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
    if (_descriptionController.text.trim().length < 10) {
      messenger.showSnackBar(const SnackBar(content: Text('Describe el incidente con más detalle')));
      return;
    }

    setState(() => _sending = true);
    try {
      final position = await _resolvePosition();
      final solicitudId = await apiService.crearSolicitud(
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
      if (_photo != null) {
        await apiService.subirEvidenciaArchivo(
              token: token,
              solicitudId: solicitudId,
              filePath: _photo!.path,
            );
      }
      if (_audioPath != null) {
        await apiService.subirEvidenciaArchivo(
              token: token,
              solicitudId: solicitudId,
              filePath: _audioPath!,
            );
      }
      if (_evidenceNoteController.text.trim().isNotEmpty) {
        await apiService.subirEvidenciaTexto(
              token: token,
              solicitudId: solicitudId,
              contenido: _evidenceNoteController.text.trim(),
            );
      }
      await emergencyProvider.cargarDatos(token);
      messenger.showSnackBar(const SnackBar(content: Text('Solicitud creada correctamente')));
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<Position> _resolvePosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('El GPS está desactivado');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      throw Exception('No hay permiso de geolocalización para reportar la emergencia');
    }
    return Geolocator.getCurrentPosition();
  }
}
