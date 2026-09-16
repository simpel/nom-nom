import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

// Basic RevenueCat Webhook interface
interface RevenueCatEvent {
  event: {
    type: string;
    app_user_id: string;
    expiration_at_ms: number;
    environment: string;
  };
}

serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  try {
    const payload = await req.json() as RevenueCatEvent;
    const event = payload.event;
    
    // RevenueCat sends the app_user_id exactly as you set it in the SDK. 
    // We assume it's the UUID of the Supabase auth.users ID.
    const userId = event.app_user_id;
    
    if (!userId) {
      return new Response("Missing app_user_id", { status: 400 });
    }

    // Convert ms timestamp to Date string for Postgres timestamptz
    const expiresAt = new Date(event.expiration_at_ms).toISOString();
    
    // Status mapping based on event type
    let subscriptionStatus = "active";
    if (event.type === "CANCELLATION") {
      subscriptionStatus = "canceled"; // Still active until expiresAt, but auto-renew is off
    } else if (event.type === "EXPIRATION") {
      subscriptionStatus = "expired";
    }

    // Initialize Supabase Admin Client
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    // Update the profile in the database
    const { error } = await supabaseAdmin
      .from('profiles')
      .update({
        subscription_status: subscriptionStatus,
        subscription_expires_at: expiresAt,
        revenuecat_app_user_id: userId
      })
      .eq('id', userId);

    if (error) {
      console.error("Supabase update error:", error);
      return new Response(JSON.stringify({ error: error.message }), { status: 500 });
    }

    return new Response(JSON.stringify({ success: true }), {
      headers: { "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error) {
    console.error("Webhook processing error:", error);
    return new Response("Internal Server Error", { status: 500 });
  }
});
