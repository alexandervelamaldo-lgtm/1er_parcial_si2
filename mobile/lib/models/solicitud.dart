class Solicitud {
  Solicitud({
    required this.id,
    required this.descripcion,
    required this.prioridad,
    required this.fechaSolicitud,
    required this.estado,
    required this.tipoIncidente,
  });

  final int id;
  final String descripcion;
  final String prioridad;
  final String fechaSolicitud;
  final String estado;
  final String tipoIncidente;

  factory Solicitud.fromJson(Map<String, dynamic> json) {
    return Solicitud(
      id: json['id'] as int,
      descripcion: json['descripcion'] as String,
      prioridad: json['prioridad'] as String,
      fechaSolicitud: json['fecha_solicitud'] as String,
      estado: (json['estado'] as Map<String, dynamic>?)?['nombre'] as String? ?? 'Sin estado',
      tipoIncidente: (json['tipo_incidente'] as Map<String, dynamic>?)?['nombre'] as String? ?? 'Sin tipo',
    );
  }
}
