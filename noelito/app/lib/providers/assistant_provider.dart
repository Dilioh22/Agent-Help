import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/local_parser.dart';
import '../core/models.dart';
import '../services/action_executor.dart';
import '../services/backend_client.dart';
import '../services/voice_services.dart';

enum AssistantStatus { idle, listening, thinking, speaking }

class AssistantState {
  final AssistantStatus status;
  final List<ChatMessage> history;
  final String partial;

  const AssistantState({
    this.status = AssistantStatus.idle,
    this.history = const [],
    this.partial = '',
  });

  AssistantState copyWith({
    AssistantStatus? status,
    List<ChatMessage>? history,
    String? partial,
  }) =>
      AssistantState(
        status: status ?? this.status,
        history: history ?? this.history,
        partial: partial ?? this.partial,
      );
}

class AssistantNotifier extends Notifier<AssistantState> {
  final _stt = SttService();
  final _tts = TtsService();
  final _backend = BackendClient();
  final _executor = ActionExecutor();

  @override
  AssistantState build() => const AssistantState();

  /// Flujo completo: escuchar → interpretar (local o nube) → ejecutar → hablar
  Future<void> listenAndRespond() async {
    if (state.status != AssistantStatus.idle) return;
    await _tts.stop();

    state = state.copyWith(status: AssistantStatus.listening, partial: '');
    final text = await _stt.listenOnce(
      onPartial: (p) => state = state.copyWith(partial: p),
    );

    if (text == null || text.trim().isEmpty) {
      state = state.copyWith(status: AssistantStatus.idle, partial: '');
      return;
    }

    await _respond(text);
  }

  /// Igual que [listenAndRespond] pero con texto escrito en vez de voz.
  Future<void> sendText(String text) async {
    if (state.status != AssistantStatus.idle) return;
    if (text.trim().isEmpty) return;
    await _tts.stop();
    state = state.copyWith(status: AssistantStatus.thinking, partial: '');
    await _respond(text);
  }

  Future<void> _respond(String text) async {
    final history = [...state.history, ChatMessage('user', text)];
    state = state.copyWith(
        status: AssistantStatus.thinking, history: history, partial: '');

    AssistantResult result;
    // 1) Parser local (instantáneo, offline)
    final local = LocalParser.parse(text);
    if (local != null) {
      result = local;
    } else {
      // 2) Fallback: Claude vía backend
      try {
        result = await _backend.chat(_lastTurns(history, 12));
      } catch (_) {
        result = const AssistantResult(
            speak:
                'No pude conectarme a mi cerebro en la nube. Revisa el internet, pero los comandos básicos siguen funcionando.');
      }
    }

    // 3) Ejecutar acción si la hay
    String toSpeak = result.speak ?? '';
    if (result.action != null) {
      final feedback = await _executor.execute(result.action!);
      if (feedback.isNotEmpty) toSpeak = feedback;
    }
    if (toSpeak.isEmpty) toSpeak = 'Listo.';

    state = state.copyWith(
      status: AssistantStatus.speaking,
      history: [...history, ChatMessage('assistant', toSpeak)],
    );
    await _tts.speak(toSpeak);
    state = state.copyWith(status: AssistantStatus.idle);
  }

  List<ChatMessage> _lastTurns(List<ChatMessage> h, int n) =>
      h.length <= n ? h : h.sublist(h.length - n);

  void clear() => state = const AssistantState();
}

final assistantProvider =
    NotifierProvider<AssistantNotifier, AssistantState>(AssistantNotifier.new);
