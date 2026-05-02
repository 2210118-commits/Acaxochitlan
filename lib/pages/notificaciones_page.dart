import 'package:flutter/material.dart';
import '../../supabase/supabase_client.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificacionesPage extends StatefulWidget {
  const NotificacionesPage({super.key});

  @override
  State<NotificacionesPage> createState() => _NotificacionesPageState();
}

class _NotificacionesPageState extends State<NotificacionesPage> {
  List notificaciones = [];
  bool cargando = true;
  late RealtimeChannel _channel;

  late String dispositivoId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    dispositivoId = await _obtenerDispositivoId();
    await cargarNotificaciones();
    escucharNotificacionesRealtime();
  }

  Future<String> _obtenerDispositivoId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString('dispositivo_id');

    if (id == null) {
      id = const Uuid().v4();
      await prefs.setString('dispositivo_id', id);
    }
    return id;
  }

  // 📥 CARGAR NOTIFICACIONES
  Future<void> cargarNotificaciones() async {
    final res = await SupabaseConfig.client
        .from('notificaciones')
        .select('''
          *,
          notificaciones_vistas!left(
            dispositivo_id,
            vista,
            eliminada
          )
        ''')
        .order('fecha', ascending: false);

    if (!mounted) return;

    final filtradas = res.where((n) {
      final vistas = n['notificaciones_vistas'] as List?;

      if (vistas == null || vistas.isEmpty) return true;

      final vistaUsuario = vistas
          .where((v) => v['dispositivo_id'] == dispositivoId)
          .toList();

      if (vistaUsuario.isEmpty) return true;

      return vistaUsuario.first['eliminada'] != true;
    }).toList();

    setState(() {
      notificaciones = filtradas;
      cargando = false;
    });
  }

  // 🔔 REALTIME
  void escucharNotificacionesRealtime() {
    _channel = SupabaseConfig.client.channel('realtime-notificaciones');

    _channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notificaciones',
          callback: (_) => cargarNotificaciones(),
        )
        .subscribe();
  }

  // 👁️ MARCAR COMO VISTA
  Future<void> marcarComoVista(int id) async {
    await SupabaseConfig.client.from('notificaciones_vistas').upsert({
      'notificacion_id': id,
      'dispositivo_id': dispositivoId,
      'vista': true,
    });

    cargarNotificaciones();
  }

  // 🗑️ ELIMINAR SOLO PARA ESTE USUARIO
  Future<void> borrarNotificacion(int id) async {
    await SupabaseConfig.client.from('notificaciones_vistas').upsert({
      'notificacion_id': id,
      'dispositivo_id': dispositivoId,
      'vista': true,
      'eliminada': true,
    });

    cargarNotificaciones();
  }

  @override
  void dispose() {
    SupabaseConfig.client.removeChannel(_channel);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        backgroundColor: Colors.blueAccent,
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : notificaciones.isEmpty
              ? const Center(child: Text('No hay notificaciones'))
              : ListView.builder(
                  itemCount: notificaciones.length,
                  itemBuilder: (context, index) {
                    final noti = notificaciones[index];
                    final vistas = noti['notificaciones_vistas'] as List?;

                    final vistaUsuario = vistas
                            ?.where((v) =>
                                v['dispositivo_id'] == dispositivoId)
                            .toList() ??
                        [];

                    final bool vista = vistaUsuario.isNotEmpty
                        ? vistaUsuario.first['vista'] == true
                        : false;

                    return Card(
                      color: vista ? Colors.grey[200] : Colors.white,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      child: ListTile(
                        leading: Icon(
                          Icons.notifications,
                          color: vista ? Colors.grey : Colors.blue,
                        ),
                        title: Text(
                          noti['titulo'],
                          style: TextStyle(
                            fontWeight:
                                vista ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(noti['mensaje']),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd/MM/yyyy HH:mm')
                                  .format(DateTime.parse(noti['fecha'])),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        onTap: vista
                            ? null
                            : () => marcarComoVista(noti['id']),
                        trailing: IconButton(
                          icon:
                              const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final confirmar = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title:
                                    const Text('Eliminar notificación'),
                                content: const Text(
                                    '¿Deseas eliminar esta notificación?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancelar'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Eliminar'),
                                  ),
                                ],
                              ),
                            );

                            if (confirmar == true) {
                              borrarNotificacion(noti['id']);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
