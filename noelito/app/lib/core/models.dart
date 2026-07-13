/// Resultado de interpretar lo que dijo el usuario.
/// Puede ser una acción a ejecutar en el teléfono o una respuesta hablada.
class AssistantResult {
  final String? speak; // Lo que Noelito dice en voz alta
  final PhoneAction? action; // Acción a ejecutar (opcional)

  const AssistantResult({this.speak, this.action});

  factory AssistantResult.fromJson(Map<String, dynamic> json) {
    return AssistantResult(
      speak: json['speak'] as String?,
      action: json['action'] != null
          ? PhoneAction.fromJson(json['action'] as Map<String, dynamic>)
          : null,
    );
  }
}

class PhoneAction {
  final String name; // set_alarm, set_timer, open_app, call_contact, ...
  final Map<String, dynamic> args;

  const PhoneAction({required this.name, required this.args});

  factory PhoneAction.fromJson(Map<String, dynamic> json) {
    return PhoneAction(
      name: json['name'] as String,
      args: Map<String, dynamic>.from(json['args'] as Map? ?? {}),
    );
  }
}

class ChatMessage {
  final String role; // 'user' | 'assistant'
  final String text;
  const ChatMessage(this.role, this.text);

  Map<String, dynamic> toJson() => {'role': role, 'content': text};
}
