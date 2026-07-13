import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/models.dart';

/// Cliente hacia el backend proxy de Noelito.
/// La API key de Anthropic vive SOLO en el backend, nunca aquí.
class BackendClient {
  // ⚙️ URL de Railway (producción). Para pruebas locales con el teléfono en
  // la misma red podés usar http://<IP-de-tu-PC>:3000 en su lugar.
  static const String baseUrl = 'https://agent-help-production.up.railway.app';

  Future<AssistantResult> chat(List<ChatMessage> history) async {
    final resp = await http
        .post(
          Uri.parse('$baseUrl/chat'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'messages': history.map((m) => m.toJson()).toList(),
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (resp.statusCode != 200) {
      throw Exception('Backend respondió ${resp.statusCode}: ${resp.body}');
    }
    return AssistantResult.fromJson(
        jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>);
  }
}
