import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/notification_item.dart';
import '../models/profile_data.dart';
import '../models/solicitud.dart';
import '../models/tecnico_cercano.dart';
import '../models/vehiculo.dart';


class ApiService {
  Future<String> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode >= 400) {
      throw Exception('No fue posible iniciar sesión');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['access_token'] as String;
  }

  Future<ProfileData> obtenerPerfilActual(String token) async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/auth/me'),
      headers: _headers(token),
    );
    _ensureSuccess(response, 'No se pudo cargar el perfil');
    return ProfileData.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<List<Vehiculo>> obtenerVehiculos(String token) async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/vehiculos'),
      headers: _headers(token),
    );
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) => Vehiculo.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<Solicitud>> obtenerSolicitudes(String token) async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/solicitudes'),
      headers: _headers(token),
    );
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) => Solicitud.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<NotificationItem>> obtenerNotificaciones(String token) async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/notificaciones'),
      headers: _headers(token),
    );
    _ensureSuccess(response, 'No se pudieron cargar las notificaciones');
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) => NotificationItem.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<void> marcarNotificacionLeida(String token, int notificacionId) async {
    final response = await http.put(
      Uri.parse('${AppConfig.apiBaseUrl}/notificaciones/$notificacionId/leida'),
      headers: _headers(token),
    );
    _ensureSuccess(response, 'No se pudo actualizar la notificación');
  }

  Future<List<TecnicoCercano>> obtenerTecnicosCercanos(
    String token, {
    required double latitud,
    required double longitud,
  }) async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/mapa/tecnicos-cercanos?lat=$latitud&lon=$longitud'),
      headers: _headers(token),
    );
    _ensureSuccess(response, 'No se pudieron cargar los técnicos cercanos');
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) => TecnicoCercano.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<void> crearSolicitud({
    required String token,
    required int clienteId,
    required int vehiculoId,
    required int tipoIncidenteId,
    required String descripcion,
    required double latitud,
    required double longitud,
    required bool esCarretera,
    required int nivelRiesgo,
    String? fotoUrl,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/solicitudes'),
      headers: _headers(token),
      body: jsonEncode({
        'cliente_id': clienteId,
        'vehiculo_id': vehiculoId,
        'tipo_incidente_id': tipoIncidenteId,
        'latitud_incidente': latitud,
        'longitud_incidente': longitud,
        'descripcion': descripcion,
        'foto_url': fotoUrl,
        'es_carretera': esCarretera,
        'condicion_vehiculo': 'Operativo con limitaciones',
        'nivel_riesgo': nivelRiesgo,
      }),
    );

    if (response.statusCode >= 400) {
      throw Exception('No se pudo crear la solicitud');
    }
  }

  void _ensureSuccess(http.Response response, String message) {
    if (response.statusCode >= 400) {
      throw Exception(message);
    }
  }

  Map<String, String> _headers(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
}
