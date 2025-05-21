import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

import 'services/tarea_dao.dart';
import 'models/tarea.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelKey: 'apptask_channel',
        channelName: 'AppTask Recordatorios',
        channelDescription: 'Notificaciones para tareas',
        defaultColor: Colors.blue,
        importance: NotificationImportance.High,
        channelShowBadge: true,
      )
    ],
    debug: true,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestor de Tareas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF00357f),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF00357f),
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF00357f),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black87),
          bodyMedium: TextStyle(color: Colors.black87),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Tarea> tareas = [];

  @override
  void initState() {
    super.initState();
    _cargarTareas();
  }

  void _cargarTareas() async {
    final lista = await TareaDAO.obtenerTareas();
    setState(() {
      tareas = lista;
    });
  }

  void _marcarComoCompletada(int index) async {
    final tarea = tareas[index];
    final tareaActualizada = tarea.copiarCon(completada: !tarea.completada);
    await TareaDAO.actualizarTarea(tareaActualizada);
    setState(() {
      tareas[index] = tareaActualizada;
    });
  }

  void _eliminarTarea(int index) async {
    await TareaDAO.eliminarTarea(tareas[index].id);
    _cargarTareas();
  }

  void _mostrarFormularioNuevaTarea() {
    String titulo = '';
    String descripcion = '';
    DateTime? recordatorio;
    int recordatorioSeleccionado = 0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return AlertDialog(
            title: const Text('Nueva Tarea'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(labelText: 'Título'),
                    onChanged: (value) => titulo = value,
                  ),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Descripción'),
                    onChanged: (value) => descripcion = value,
                  ),
                  const SizedBox(height: 10),
                  const Text('Recordarme en:'),
                  ...List.generate(5, (i) {
                    final opciones = [
                      'No recordarme',
                      'En 1 hora',
                      'En 2 horas',
                      'En 3 horas',
                      'Hora personalizada'
                    ];
                    return RadioListTile<int>(
                      title: Text(opciones[i]),
                      value: i,
                      groupValue: recordatorioSeleccionado,
                      onChanged: (value) async {
                        setModalState(() => recordatorioSeleccionado = value!);
                        if (value == 4) {
                          final fecha = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (fecha != null && context.mounted) {
                            final hora = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (hora != null) {
                              setModalState(() {
                                recordatorio = DateTime(
                                  fecha.year,
                                  fecha.month,
                                  fecha.day,
                                  hora.hour,
                                  hora.minute,
                                );
                              });
                            }
                          }
                        }
                      },
                    );
                  }),
                  if (recordatorioSeleccionado == 4 && recordatorio != null)
                    Text('Recordatorio: ${recordatorio!.toLocal().toString().substring(0, 16)}'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (titulo.isNotEmpty && descripcion.isNotEmpty) {
                    final ahora = DateTime.now();
                    DateTime? recordatorioFinal;

                    switch (recordatorioSeleccionado) {
                      case 1:
                        recordatorioFinal = ahora.add(const Duration(hours: 1));
                        break;
                      case 2:
                        recordatorioFinal = ahora.add(const Duration(hours: 2));
                        break;
                      case 3:
                        recordatorioFinal = ahora.add(const Duration(hours: 3));
                        break;
                      case 4:
                        recordatorioFinal = recordatorio;
                        break;
                    }

                    final nuevaTarea = Tarea(
                      id: -1,
                      titulo: titulo,
                      descripcion: descripcion,
                      completada: false,
                      fechaCreacion: ahora,
                      prioridad: 'media',
                      fechaLimite: null,
                      recordatorio: recordatorioFinal,
                    );

                    final tareaConId = await TareaDAO.insertarTarea(nuevaTarea);
                    setState(() {
                      tareas.add(tareaConId);
                    });

                    if (recordatorioFinal != null && recordatorioFinal.isAfter(DateTime.now())) {
                      await AwesomeNotifications().createNotification(
                        content: NotificationContent(
                          id: tareaConId.id,
                          channelKey: 'apptask_channel',
                          title: 'Recordatorio: ${tareaConId.titulo}',
                          body: tareaConId.descripcion,
                          notificationLayout: NotificationLayout.Default,
                        ),
                        schedule: NotificationCalendar(
                          year: recordatorioFinal.year,
                          month: recordatorioFinal.month,
                          day: recordatorioFinal.day,
                          hour: recordatorioFinal.hour,
                          minute: recordatorioFinal.minute,
                          second: 0,
                          timeZone: 'America/Guatemala',
                          preciseAlarm: true,
                        ),
                      );
                    }

                    if (context.mounted) Navigator.of(context).pop();
                  }
                },
                child: const Text('Agregar'),
              ),
            ],
          );
        });
      },
    );
  }

  void _mostrarOpcionesTarea(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Opciones'),
          children: [
            SimpleDialogOption(
              onPressed: () {
                Navigator.of(context).pop();
                _eliminarTarea(index);
              },
              child: const Text('Eliminar'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Tareas')),
      body: Stack(
        children: [
          Center(
            child: Opacity(
              opacity: 0.05,
              child: Image.asset('assets/logo_apptask.png', width: 250),
            ),
          ),
          ListView.builder(
            itemCount: tareas.length,
            itemBuilder: (context, index) {
              final tarea = tareas[index];
              return ListTile(
                leading: Icon(
                  tarea.completada ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: tarea.completada ? Colors.green : Colors.grey,
                ),
                title: Text(
                  tarea.titulo,
                  style: TextStyle(
                    decoration: tarea.completada ? TextDecoration.lineThrough : null,
                  ),
                ),
                subtitle: Text(
                  '${tarea.descripcion}\n'
                  'Creada: ${tarea.fechaCreacion.toLocal().toString().substring(0, 16)}\n'
                  'Prioridad: ${tarea.prioridad.toUpperCase()}\n'
                  '${tarea.recordatorio != null ? 'Recordatorio: ${tarea.recordatorio!.toLocal().toString().substring(0, 16)}' : ''}',
                ),
                isThreeLine: true,
                onTap: () => _marcarComoCompletada(index),
                onLongPress: () => _mostrarOpcionesTarea(index),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarFormularioNuevaTarea,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
