import "dotenv/config";
import OpenAI from "openai";
import cors from "cors";
import express from "express";

const app = express();
app.use(cors());
app.use(express.json());

const openrouter = new OpenAI({
  apiKey: process.env.OPENROUTER_API_KEY,
  baseURL: "https://openrouter.ai/api/v1",
  defaultHeaders: {
    "HTTP-Referer": "https://github.com/dilio/noelito",
    "X-Title": "Noelito",
  },
});
const MODEL = process.env.NOELITO_MODEL ?? "openai/gpt-4o-mini";

// ---------- Herramientas que Noelito puede ejecutar en el teléfono ----------
const tools: OpenAI.Chat.ChatCompletionTool[] = [
  {
    type: "function",
    function: {
      name: "set_alarm",
      description: "Crea una alarma en el teléfono a una hora específica.",
      parameters: {
        type: "object",
        properties: {
          hour: { type: "integer", description: "Hora en formato 24h (0-23)" },
          minute: { type: "integer", description: "Minutos (0-59)" },
          label: { type: "string", description: "Etiqueta de la alarma" },
        },
        required: ["hour", "minute"],
      },
    },
  },
  {
    type: "function",
    function: {
      name: "set_timer",
      description: "Inicia un temporizador (cuenta regresiva).",
      parameters: {
        type: "object",
        properties: {
          seconds: { type: "integer", description: "Duración total en segundos" },
          label: { type: "string" },
        },
        required: ["seconds"],
      },
    },
  },
  {
    type: "function",
    function: {
      name: "open_app",
      description: "Abre una aplicación instalada en el teléfono por su nombre.",
      parameters: {
        type: "object",
        properties: { name: { type: "string", description: "Nombre de la app, ej. 'spotify'" } },
        required: ["name"],
      },
    },
  },
  {
    type: "function",
    function: {
      name: "call_contact",
      description: "Marca a un contacto de la agenda por nombre. La llamada requiere confirmación del usuario en pantalla.",
      parameters: {
        type: "object",
        properties: { name: { type: "string", description: "Nombre o apodo del contacto" } },
        required: ["name"],
      },
    },
  },
  {
    type: "function",
    function: {
      name: "send_whatsapp",
      description: "Abre un chat de WhatsApp con un contacto y el mensaje prellenado (el usuario da enviar).",
      parameters: {
        type: "object",
        properties: {
          name: { type: "string", description: "Nombre del contacto" },
          text: { type: "string", description: "Texto del mensaje" },
        },
        required: ["name", "text"],
      },
    },
  },
  {
    type: "function",
    function: {
      name: "create_calendar_event",
      description: "Crea un evento de calendario. Pásale los tiempos en milisegundos epoch.",
      parameters: {
        type: "object",
        properties: {
          title: { type: "string" },
          begin_millis: { type: "number" },
          end_millis: { type: "number" },
          location: { type: "string" },
        },
        required: ["title", "begin_millis"],
      },
    },
  },
  {
    type: "function",
    function: {
      name: "open_settings_panel",
      description: "Abre un panel de configuración del teléfono.",
      parameters: {
        type: "object",
        properties: {
          panel: { type: "string", enum: ["wifi", "internet", "volume", "bluetooth", "settings"] },
        },
        required: ["panel"],
      },
    },
  },
];

const SYSTEM = `Eres Noelito, el asistente personal de voz de Dilio (San Pedro Sula, Honduras).
Personalidad: servicial, directo, con calidez hondureña sutil. Nada de discursos largos.

Reglas:
- Respondes SIEMPRE en español.
- Tus respuestas se leen en voz alta (TTS): frases cortas, sin markdown, sin listas, sin emojis, sin asteriscos.
- Máximo 2-3 oraciones salvo que pidan explicación larga.
- Fecha/hora actual del servidor: {{NOW}} (zona América/Tegucigalpa).
- Si el usuario pide una acción del teléfono, usa la herramienta adecuada. Si pide algo que ninguna herramienta cubre, dilo honestamente y sugiere alternativa.
- Para eventos de calendario calcula los milisegundos epoch correctamente usando la fecha actual.
- Si te preguntan tu nombre: te llamas Noelito.`;

// ---------- Endpoint principal ----------
app.post("/chat", async (req, res) => {
  try {
    const messages = (req.body?.messages ?? []) as OpenAI.Chat.ChatCompletionMessageParam[];
    if (!Array.isArray(messages) || messages.length === 0) {
      return res.status(400).json({ error: "messages requerido" });
    }

    const now = new Date().toLocaleString("es-HN", { timeZone: "America/Tegucigalpa" });

    // Búsqueda web activada en toda consulta que llega al backend, para que
    // Noelito responda con información actualizada en vez de solo lo que el
    // modelo ya sabía. Tiene un costo extra por consulta (~$0.005, Exa).
    const response = await openrouter.chat.completions.create({
      model: MODEL,
      max_tokens: 600,
      messages: [
        { role: "system", content: SYSTEM.replace("{{NOW}}", now) },
        ...messages,
      ],
      tools,
      plugins: [{ id: "web", max_results: 3 }],
    } as OpenAI.Chat.ChatCompletionCreateParamsNonStreaming & {
      plugins: { id: string; max_results: number }[];
    });

    const message = response.choices[0]?.message;
    const toolCall = message?.tool_calls?.find((c) => c.type === "function");
    const text = message?.content?.trim();

    if (toolCall) {
      return res.json({
        speak: text || null, // el modelo puede acompañar la acción con una frase
        action: { name: toolCall.function.name, args: JSON.parse(toolCall.function.arguments || "{}") },
      });
    }
    return res.json({ speak: text || "No estoy seguro de cómo ayudarte con eso." });
  } catch (err: any) {
    console.error(err);
    return res.status(500).json({ error: err?.message ?? "error interno" });
  }
});

app.get("/health", (_req, res) => res.json({ ok: true, name: "noelito" }));

const PORT = Number(process.env.PORT ?? 3000);
app.listen(PORT, () => console.log(`🤖 Noelito backend escuchando en :${PORT}`));
