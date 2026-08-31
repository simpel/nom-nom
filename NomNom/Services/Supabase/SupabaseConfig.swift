import Foundation
import Supabase

/// Which Supabase this build talks to.
///
/// Debug points at the local stack from `supabase start`, because that is the only
/// environment where the email one-time code can actually be read: the local
/// server captures outgoing mail in Mailpit on :54324 instead of sending it. The
/// hosted project's built-in SMTP is rate limited to a couple of messages an hour
/// and only to authorised addresses, which is not something to develop against.
///
/// `127.0.0.1` resolves to the Mac from inside the simulator, since the simulator
/// shares the host's loopback interface. On a physical device it does not — that
/// needs the Mac's LAN address here instead.
enum SupabaseConfig {
    #if DEBUG
    static let url = URL(string: "http://127.0.0.1:54321")!
    /// The CLI's fixed local development key. Deliberately the long-lived demo JWT
    /// rather than the `sb_publishable_…` key printed by `supabase start`: this one
    /// is baked into the CLI and survives a `db reset`, so it doesn't need
    /// re-copying every time the stack is rebuilt. It only works against localhost.
    static let publishableKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"
    #else
    static let url = URL(string: "https://bctbqsrsmkyputxyiyzh.supabase.co")!
    /// Publishable, not secret: it identifies the project and carries no authority
    /// of its own. The baseline migration's final section takes every table
    /// privilege away from `anon`, so on its own this key cannot read or write a
    /// single row.
    static let publishableKey = "sb_publishable_bgIFelWFVC7Z8r6wIXJvjg_xoOJug4L"
    #endif

    /// Private bucket holding meal photos, keyed `<meal_id>/<uuid>.jpg` — the
    /// storage policies read the meal id out of that first path segment to decide
    /// who may see the object, so the layout is load-bearing.
    static let photoBucket = "meal-photos"
}

/// One client for the whole app. `SupabaseClient` keeps the session in the
/// keychain and refreshes the access token on its own, so nothing else needs to
/// think about token lifetime.
let supabase = SupabaseClient(
    supabaseURL: SupabaseConfig.url,
    supabaseKey: SupabaseConfig.publishableKey
)
