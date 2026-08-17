import {
  errorResponse,
  json,
  preflight,
  requireUser,
} from "../_shared/http.ts";
import { openAiSafetyIdentifier, runOpenAI } from "../_shared/openai.ts";

Deno.serve(async (req) => {
  const options = preflight(req);
  if (options) return options;
  try {
    const { user } = await requireUser(req);
    const body = await req.json();
    if (
      !(body.text as string | undefined)?.trim() ||
      !(body.target_language as string | undefined)?.trim()
    ) {
      return json({ error: "Text and target_language are required." }, 400);
    }
    const result = await runOpenAI({
      action: "translate",
      text: body.text,
      targetLanguage: body.target_language,
      safetyIdentifier: await openAiSafetyIdentifier(user.id),
    });
    return json({ result });
  } catch (error) {
    return errorResponse(error);
  }
});
