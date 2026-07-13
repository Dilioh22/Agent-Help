import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  final Map<Permission, PermissionStatus> _status = {};

  static const _permissions = [
    (
      Permission.microphone,
      'Micrófono',
      'Para escucharte cuando le hablas a Noelito',
      Icons.mic,
    ),
    (
      Permission.contacts,
      'Contactos',
      'Para llamar o mandar WhatsApp por nombre, ej. "llama a mamá"',
      Icons.contacts,
    ),
    (
      Permission.notification,
      'Notificaciones',
      'Para mostrar el aviso de "Noelito" escuchando en segundo plano',
      Icons.notifications,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // El usuario puede volver de la pantalla de Ajustes del sistema.
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final entries = await Future.wait(
      _permissions.map((p) async => MapEntry(p.$1, await p.$1.status)),
    );
    if (mounted) setState(() => _status.addEntries(entries));
  }

  Future<void> _handle(Permission permission) async {
    final status = _status[permission];
    if (status != null && status.isPermanentlyDenied) {
      await openAppSettings();
    } else {
      await permission.request();
    }
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Permisos')),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _permissions.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final (permission, title, subtitle, icon) = _permissions[i];
          final status = _status[permission];
          final granted = status?.isGranted ?? false;
          return ListTile(
            leading: Icon(icon),
            title: Text(title),
            subtitle: Text(subtitle),
            trailing: granted
                ? const Icon(Icons.check_circle, color: Colors.green)
                : TextButton(
                    onPressed: () => _handle(permission),
                    child: Text(
                      status?.isPermanentlyDenied == true
                          ? 'Ajustes'
                          : 'Conceder',
                    ),
                  ),
          );
        },
      ),
    );
  }
}
