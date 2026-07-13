import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/assistant_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Permission.microphone.request();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submitText() {
    final text = _textController.text;
    if (text.trim().isEmpty) return;
    ref.read(assistantProvider.notifier).sendText(text);
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(assistantProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Noelito'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => ref.read(assistantProvider.notifier).clear(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: s.history.isEmpty
                ? Center(
                    child: Text(
                      'Hola, soy Noelito 👋\nToca el micrófono y pídeme algo:\n\n“Pon una alarma a las 6”\n“Abre Spotify”\n“Llama a mamá”\n“¿Qué es un agujero negro?”',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    reverse: true,
                    itemCount: s.history.length,
                    itemBuilder: (_, i) {
                      final m = s.history[s.history.length - 1 - i];
                      final isUser = m.role == 'user';
                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(12),
                          constraints: const BoxConstraints(maxWidth: 300),
                          decoration: BoxDecoration(
                            color: isUser
                                ? scheme.primaryContainer
                                : scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(m.text),
                        ),
                      );
                    },
                  ),
          ),
          if (s.partial.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text('“${s.partial}”',
                  style: TextStyle(color: scheme.primary)),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    enabled: s.status == AssistantStatus.idle,
                    decoration: const InputDecoration(
                      hintText: 'Escríbele a Noelito…',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(24)),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submitText(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed:
                      s.status == AssistantStatus.idle ? _submitText : null,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 32, top: 8),
            child: _MicButton(status: s.status),
          ),
        ],
      ),
    );
  }
}

class _MicButton extends ConsumerWidget {
  final AssistantStatus status;
  const _MicButton({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, color, label) = switch (status) {
      AssistantStatus.idle => (Icons.mic, scheme.primary, 'Toca para hablar'),
      AssistantStatus.listening => (Icons.hearing, Colors.redAccent, 'Escuchando…'),
      AssistantStatus.thinking => (Icons.psychology, Colors.amber, 'Pensando…'),
      AssistantStatus.speaking => (Icons.volume_up, Colors.green, 'Hablando…'),
    };

    return Column(
      children: [
        GestureDetector(
          onTap: () => ref.read(assistantProvider.notifier).listenAndRespond(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.15),
              border: Border.all(color: color, width: 3),
            ),
            child: Icon(icon, size: 40, color: color),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: scheme.onSurfaceVariant)),
      ],
    );
  }
}
