import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../core/models.dart';

/// Ejecuta acciones del teléfono vía MethodChannel hacia Kotlin.
/// Devuelve el texto que Noelito debe decir tras ejecutar (o el error).
class ActionExecutor {
  static const _channel = MethodChannel('noelito/actions');

  Future<String> execute(PhoneAction action) async {
    try {
      switch (action.name) {
        case 'set_alarm':
        case 'set_timer':
        case 'open_settings_panel':
        case 'create_calendar_event':
          await _channel.invokeMethod(action.name, action.args);
          return '';

        case 'open_app':
          final ok = await _channel.invokeMethod<bool>(
              'open_app', {'name': action.args['name']});
          return ok == true
              ? ''
              : 'No encontré la aplicación ${action.args['name']} en tu teléfono.';

        case 'call_contact':
          final phone = await _resolveContact(action.args['name'] as String);
          if (phone == null) {
            return 'No encontré a ${action.args['name']} en tus contactos.';
          }
          await _channel.invokeMethod('dial', {'number': phone.$2});
          return 'Marcando a ${phone.$1}. Confirma la llamada en pantalla.';

        case 'send_whatsapp':
          String? number = action.args['phone'] as String?;
          String display = action.args['name'] as String? ?? '';
          if (number == null && action.args['name'] != null) {
            final c = await _resolveContact(action.args['name'] as String);
            if (c == null) return 'No encontré a $display en tus contactos.';
            display = c.$1;
            number = c.$2;
          }
          await _channel.invokeMethod('send_whatsapp', {
            'number': number,
            'text': action.args['text'] ?? '',
          });
          return 'Te abrí el chat de WhatsApp con $display, solo dale enviar.';

        default:
          return 'Todavía no sé hacer la acción ${action.name}.';
      }
    } on PlatformException catch (e) {
      return 'No pude ejecutar la acción: ${e.message}';
    }
  }

  /// Matching difuso simple contra contactos: exacto > empieza con > contiene.
  Future<(String, String)?> _resolveContact(String query) async {
    if (!await FlutterContacts.requestPermission(readonly: true)) return null;
    final contacts =
        await FlutterContacts.getContacts(withProperties: true);
    final q = _norm(query);

    Contact? best;
    int bestScore = 0;
    for (final c in contacts) {
      if (c.phones.isEmpty) continue;
      final name = _norm(c.displayName);
      int score = 0;
      if (name == q) {
        score = 3;
      } else if (name.startsWith(q) || q.startsWith(name)) {
        score = 2;
      } else if (name.contains(q)) {
        score = 1;
      }
      if (score > bestScore) {
        bestScore = score;
        best = c;
      }
    }
    if (best == null) return null;
    return (best.displayName, best.phones.first.number);
  }

  String _norm(String s) => s
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .trim();
}
