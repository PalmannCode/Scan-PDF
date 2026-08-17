const OPENAI_URL = "https://api.openai.com/v1/responses";

export type AiAction = "ask" | "summary" | "extract" | "translate" | "count";

/// Produces a stable, non-reversible identifier for OpenAI abuse monitoring
/// without sending the Supabase user ID to the model provider.
export async function openAiSafetyIdentifier(userId: string): Promise<string> {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(`scanpdf:${userId}`),
  );
  return Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

function assistantSchema() {
  return {
    type: "object",
    properties: {
      answer: { type: "string" },
      summary: { type: "string" },
      key_points: { type: "array", items: { type: "string" } },
      action_items: { type: "array", items: { type: "string" } },
      translation: { type: "string" },
      detected_language: { type: "string" },
    },
    required: [
      "answer",
      "summary",
      "key_points",
      "action_items",
      "translation",
      "detected_language",
    ],
    additionalProperties: false,
  };
}

function extractionSchema() {
  return {
    type: "object",
    properties: {
      document_type: { type: ["string", "null"] },
      vendor_name: { type: ["string", "null"] },
      document_number: { type: ["string", "null"] },
      document_date: { type: ["string", "null"] },
      due_date: { type: ["string", "null"] },
      total_amount: { type: ["number", "null"] },
      tax_amount: { type: ["number", "null"] },
      currency: { type: ["string", "null"] },
      names: { type: "array", items: { type: "string" } },
      addresses: { type: "array", items: { type: "string" } },
      dates: { type: "array", items: { type: "string" } },
      tasks: { type: "array", items: { type: "string" } },
      line_items: {
        type: "array",
        items: {
          type: "object",
          properties: {
            description: { type: "string" },
            quantity: { type: ["number", "null"] },
            amount: { type: ["number", "null"] },
          },
          required: ["description", "quantity", "amount"],
          additionalProperties: false,
        },
      },
    },
    required: [
      "document_type",
      "vendor_name",
      "document_number",
      "document_date",
      "due_date",
      "total_amount",
      "tax_amount",
      "currency",
      "names",
      "addresses",
      "dates",
      "tasks",
      "line_items",
    ],
    additionalProperties: false,
  };
}

function countSchema() {
  return {
    type: "object",
    properties: {
      count: { type: "integer" },
      object_label: { type: "string" },
      confidence: { type: "number" },
      notes: { type: "string" },
    },
    required: ["count", "object_label", "confidence", "notes"],
    additionalProperties: false,
  };
}

function outputText(response: Record<string, unknown>): string {
  const output = response.output as Array<Record<string, unknown>> | undefined;
  for (const item of output ?? []) {
    if (item.type !== "message") continue;
    const content = item.content as Array<Record<string, unknown>> | undefined;
    for (const part of content ?? []) {
      if (part.type === "output_text" && typeof part.text === "string") {
        return part.text;
      }
      if (part.type === "refusal") {
        throw new Error("The AI request was refused.");
      }
    }
  }
  throw new Error("OpenAI returned no completed output.");
}

export async function runOpenAI(input: {
  action: AiAction;
  text?: string;
  question?: string;
  targetLanguage?: string;
  imageDataUrl?: string;
  safetyIdentifier: string;
}): Promise<unknown> {
  const apiKey = Deno.env.get("OPENAI_API_KEY");
  if (!apiKey) throw new Error("OPENAI_API_KEY is not configured.");
  const model = Deno.env.get("OPENAI_MODEL") ?? "gpt-5.6";
  const action = input.action;
  const schema = action === "extract"
    ? extractionSchema()
    : action === "count"
    ? countSchema()
    : assistantSchema();
  const formatName = action === "extract"
    ? "document_extraction"
    : action === "count"
    ? "object_count"
    : "document_assistant";
  const prompt = action === "count"
    ? `Count the visible objects requested by the user. ${
      input.question ?? "Count the dominant repeated object."
    }`
    : [
      `Task: ${action}.`,
      input.targetLanguage ? `Target language: ${input.targetLanguage}.` : "",
      input.question ? `User question: ${input.question}` : "",
      `Document OCR text:\n${(input.text ?? "").slice(0, 120000)}`,
    ].filter(Boolean).join("\n");
  const content: Array<Record<string, unknown>> = [{
    type: "input_text",
    text: prompt,
  }];
  if (input.imageDataUrl) {
    content.push({ type: "input_image", image_url: input.imageDataUrl });
  }
  const response = await fetch(OPENAI_URL, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model,
      store: false,
      safety_identifier: input.safetyIdentifier,
      input: [{ role: "user", content }],
      text: {
        format: { type: "json_schema", name: formatName, strict: true, schema },
      },
    }),
  });
  const payload = await response.json();
  if (!response.ok) {
    console.error("OpenAI error", response.status, payload);
    throw new Error("The AI provider request failed.");
  }
  if (payload.status === "incomplete") {
    throw new Error("The AI response was incomplete.");
  }
  return JSON.parse(outputText(payload));
}
