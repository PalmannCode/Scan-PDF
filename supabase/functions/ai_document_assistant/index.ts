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

/// Free accounts may send this many AI messages per calendar month.
const FREE_AI_MESSAGE_LIMIT = 3;

/// Row shape returned by the consume_ai_message SQL function.
interface AiReservation {
  allowed: boolean;
  used: number;
  monthly_limit: number;
}

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
    // Validate the payload before reserving a message so a malformed
    // request cannot burn free-tier quota without an AI call.
    if (action !== "count" && !(body.text as string | undefined)?.trim()) {
      return json({ error: "Document text is required." }, 400);
    }
    if (
      action === "count" &&
      !(body.image_data_url as string | undefined)?.startsWith("data:image/")
    ) {
      return json({ error: "A captured image is required." }, 400);
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
    // Reserve the message atomically. A read-then-write here let concurrent
    // requests all observe the same pre-increment count and skip the cap.
    const { data: reservationData, error: reservationError } = await admin.rpc(
      "consume_ai_message",
      {
        p_user_id: user.id,
        p_limit: FREE_AI_MESSAGE_LIMIT,
        p_unlimited: active,
      },
    ).single();
    if (reservationError) throw reservationError;
    const reservation = reservationData as AiReservation | null;
    if (!reservation?.allowed) {
      return json(
        { error: "AI_LIMIT_REACHED", limit: FREE_AI_MESSAGE_LIMIT },
        402,
      );
    }
    const used = reservation.used;
    const result = await runOpenAI({
      action,
      text: body.text,
      question: body.question,
      targetLanguage: body.target_language,
      imageDataUrl: body.image_data_url,
      safetyIdentifier: await openAiSafetyIdentifier(user.id),
    });
    // consume_ai_message already persisted the increment and the period window.
    return json({
      result,
      usage: { used, limit: active ? null : FREE_AI_MESSAGE_LIMIT },
    });
  } catch (error) {
    return errorResponse(error);
  }
});
