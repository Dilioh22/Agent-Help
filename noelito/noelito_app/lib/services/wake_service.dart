import 'package:flutter/services.dart';

/// Cliente del servicio nativo de Android que escucha "Oye Noelito"
/// en segundo plano (foreground service + Porcupine).
class WakeService {
  static const _channel = MethodChannel('noelito/wake');

  /// true si esta apertura de la app fue disparada por la palabra clave.
  /// Consume la bandera del lado nativo (solo se puede leer una vez).
  Future<bool> consumeWakeFlag() async {
    final r = await _channel.invokeMethod<bool>('consumeWakeFlag');
    return r ?? false;
  }

  Future<void> start() => _channel.invokeMethod('start');

  Future<void> stop() => _channel.invokeMethod('stop');

  Future<bool> isRunning() async {
    final r = await _channel.invokeMethod<bool>('isRunning');
    return r ?? false;
  }
}
