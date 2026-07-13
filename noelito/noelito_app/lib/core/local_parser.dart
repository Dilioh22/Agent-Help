import 'models.dart';

/// Parser local: intenta resolver los comandos más frecuentes SIN ir a la nube.
/// Si devuelve null, el texto se manda al backend (Claude) como fallback.
class LocalParser {
  static AssistantResult? parse(String raw) {
    final text = _normalize(raw);

    // --- Alarma: "pon una alarma a las 6", "alarma a las 6 y media de la tarde" ---
    final alarm = RegExp(
            r'alarma.*?a las (\d{1,2})(?::(\d{2}))?( y media| y cuarto)?( de la (manana|tarde|noche))?')
        .firstMatch(text);
    if (alarm != null) {
      var hour = int.parse(alarm.group(1)!);
      var minute = int.tryParse(alarm.group(2) ?? '') ?? 0;
      if (alarm.group(3) == ' y media') minute = 30;
      if (alarm.group(3) == ' y cuarto') minute = 15;
      final period = alarm.group(5);
      if ((period == 'tarde' || period == 'noche') && hour < 12) hour += 12;
      return AssistantResult(
        speak: 'Listo, alarma puesta a las ${_hora(hour, minute)}.',
        action: PhoneAction(
            name: 'set_alarm',
            args: {'hour': hour, 'minute': minute, 'label': 'Alarma de Noelito'}),
      );
    }

    // --- Temporizador: "temporizador de 10 minutos", "timer de 30 segundos" ---
    final timer = RegExp(r'(temporizador|timer|cuenta regresiva).*?(\d+)\s*(minutos?|segundos?|horas?)')
        .firstMatch(text);
    if (timer != null) {
      final n = int.parse(timer.group(2)!);
      final unit = timer.group(3)!;
      final seconds = unit.startsWith('hora')
          ? n * 3600
          : unit.startsWith('minuto')
              ? n * 60
              : n;
      return AssistantResult(
        speak: 'Temporizador de $n $unit iniciado.',
        action: PhoneAction(
            name: 'set_timer', args: {'seconds': seconds, 'label': 'Noelito'}),
      );
    }

    // --- Abrir app: "abre spotify", "abrir whatsapp" ---
    final open = RegExp(r'\babr(?:e|ir|eme)\s+(.+)$').firstMatch(text);
    if (open != null) {
      final appName = open.group(1)!.trim();
      return AssistantResult(
        speak: 'Abriendo $appName.',
        action: PhoneAction(name: 'open_app', args: {'name': appName}),
      );
    }

    // --- Llamar: "llama a mama", "llamar a juan" ---
    final call = RegExp(r'\bllama(?:r|me)?\s+a\s+(.+)$').firstMatch(text);
    if (call != null) {
      final who = call.group(1)!.trim();
      return AssistantResult(
        speak: null, // el ejecutor confirma cuando encuentre el contacto
        action: PhoneAction(name: 'call_contact', args: {'name': who}),
      );
    }

    // --- WhatsApp: "manda un whatsapp a juan que dice voy en camino" ---
    final wa = RegExp(
            r'(?:manda|envia)\s+(?:un\s+)?whatsapp\s+a\s+(.+?)\s+(?:que diga|que dice|diciendo)\s+(.+)$')
        .firstMatch(text);
    if (wa != null) {
      return AssistantResult(
        action: PhoneAction(name: 'send_whatsapp', args: {
          'name': wa.group(1)!.trim(),
          'text': wa.group(2)!.trim(),
        }),
      );
    }

    // --- Paneles de ajustes: "abre el wifi", "configuracion de bluetooth" ---
    if (RegExp(r'\b(wifi|wi fi)\b').hasMatch(text) &&
        RegExp(r'(abre|activa|configuracion|ajustes)').hasMatch(text)) {
      return const AssistantResult(
        speak: 'Abriendo el panel de WiFi.',
        action: PhoneAction(name: 'open_settings_panel', args: {'panel': 'wifi'}),
      );
    }
    if (text.contains('bluetooth') &&
        RegExp(r'(abre|activa|configuracion|ajustes)').hasMatch(text)) {
      return const AssistantResult(
        speak: 'Abriendo ajustes de Bluetooth.',
        action:
            PhoneAction(name: 'open_settings_panel', args: {'panel': 'bluetooth'}),
      );
    }

    // --- Hora: "que hora es" ---
    if (RegExp(r'que horas? (es|son)').hasMatch(text)) {
      final now = DateTime.now();
      return AssistantResult(
          speak: 'Son las ${_hora(now.hour, now.minute)}.');
    }

    return null; // no matcheó: que lo resuelva Claude
  }

  static String _normalize(String s) => s
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll(RegExp(r'[¿?¡!.,]'), '')
      .trim();

  static String _hora(int h, int m) {
    final h12 = h % 12 == 0 ? 12 : h % 12;
    final suf = h < 12 ? 'de la mañana' : (h < 19 ? 'de la tarde' : 'de la noche');
    return m == 0 ? '$h12 $suf' : '$h12 y ${m.toString().padLeft(2, '0')} $suf';
  }
}
