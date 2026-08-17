import {
  errorResponse,
  json,
  preflight,
  requireUser,
} from "../_shared/http.ts";
import {
  type AiAction,
  openAiSafetyIdentifier,
  runOpenAI,
} from "../_shared/openai.ts";

Deno.serve(async (req) => {
  const options = preflight(req);
  if (options) return options;
  try {
    const { user, admin } = await requireUser(req);
    const body = await req.json();
    const action = body.action as AiAction;
    if (!["ask", "summary", "extract", "translate", "count"].includes(action)) {
      return json({ error: "Unsupported AI action." }, 400);
    }
    const { data: subscription } = await admin
      .from("subscriptions")
      .select("status,current_period_end")
      .eq("user_id", user.id)
      .maybeSingle();
    const active =
      ["active", "trialing"].includes(subscription?.status ?? "") &&
      (!subscription?.current_period_end ||
        new Date(subscription.current_period_end) > new Date());
    const { data: usage } = await admin
      .from("usage_limits")
      .select("ai_messages_used,period_end")
      .eq("user_id", user.id)
      .single();
    let used = usage?.ai_messages_used ?? 0;
    if (!usage?.period_end || new Date(usage.period_end) <= new Date()) {
      used = 0;
    }
    if (!active && used >= 3) {
      return json({ error: "AI_LIMIT_REACHED", limit: 3 }, 402);
    }
    if (action !== "count" && !(body.text as string | undefined)?.trim()) {
      return json({ error: "Document text is required." }, 400);
    }
    if (
      action === "count" &&
      !(body.image_data_url as string | undefined)?.startsWith("data:image/")
    ) {
      return json({ error: "A captured image is required." }, 400);
    }
    const result = await runOpenAI({
      action,
      text: body.text,
      question: body.question,
      targetLanguage: body.target_language,
      imageDataUrl: body.image_data_url,
      safetyIdentifier: await openAiSafetyIdentifier(user.id),
    });
    const now = new Date();
    const periodEnd = new Date(
      Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + 1, 1),
    );
    await admin.from("usage_limits").upsert({
      user_id: user.id,
      ai_messages_used: used + 1,
      period_start: new Date(
        Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1),
      ).toISOString(),
      period_end: periodEnd.toISOString(),
      updated_at: now.toISOString(),
    }, { onConflict: "user_id" });
    return json({
      result,
      usage: { used: used + 1, limit: active ? null : 3 },
    });
  } catch (error) {
    return errorResponse(error);
  }
});
