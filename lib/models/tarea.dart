class Tarea {
  final int id;
  final String titulo;
  final String descripcion;
  final bool completada;
  final DateTime fechaCreacion;
  final DateTime? fechaLimite;
  final String prioridad;
  final DateTime? recordatorio;

  Tarea({
    required this.id,
    required this.titulo,
    required this.descripcion,
    this.completada = false,
    required this.fechaCreacion,
    this.fechaLimite,
    required this.prioridad,
    this.recordatorio,
  });

Map<String, dynamic> toMap({bool includeId = false}) {
  final map = {
    'titulo': titulo,
    'descripcion': descripcion,
    'completada': completada ? 1 : 0,
    'fecha_creacion': fechaCreacion.toIso8601String(),
    'fecha_limite': fechaLimite?.toIso8601String(),
    'prioridad': prioridad,
    'recordatorio': recordatorio?.toIso8601String(),
  };

  if (includeId) {
    map['id'] = id;
  }

  return map;
}

  static Tarea fromMap(Map<String, dynamic> map) {
    return Tarea(
      id: map['id'],
      titulo: map['titulo'],
      descripcion: map['descripcion'],
      completada: map['completada'] == 1,
      fechaCreacion: map['fecha_creacion'] != null
          ? DateTime.parse(map['fecha_creacion'])
          : DateTime.now(),
      fechaLimite: map['fecha_limite'] != null
          ? DateTime.tryParse(map['fecha_limite'])
          : null,
      prioridad: map['prioridad'] ?? 'media',
      recordatorio: map['recordatorio'] != null
          ? DateTime.tryParse(map['recordatorio'])
          : null,
    );
  }

  Tarea copiarCon({
    int? id,
    String? titulo,
    String? descripcion,
    bool? completada,
    DateTime? fechaCreacion,
    DateTime? fechaLimite,
    String? prioridad,
    DateTime? recordatorio,
  }) {
    return Tarea(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      completada: completada ?? this.completada,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaLimite: fechaLimite ?? this.fechaLimite,
      prioridad: prioridad ?? this.prioridad,
      recordatorio: recordatorio ?? this.recordatorio,
    );
  }
}
