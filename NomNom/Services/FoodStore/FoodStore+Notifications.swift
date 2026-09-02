import Foundation
import Supabase

private struct DeviceTokenUpsert: Encodable {
    let user_id: UUID
    let apns_token: String
    let environment: String
}

extension FoodStore {

    func registerDeviceToken(_ token: String, environment: String = "sandbox") async {
        guard !token.isEmpty else { return }

        let upsertPayload = DeviceTokenUpsert(
            user_id: userID,
            apns_token: token,
            environment: environment
        )

        do {
            try await supabase
                .from("device_tokens")
                .upsert(upsertPayload, onConflict: "user_id,apns_token")
                .execute()
            Self.log.info("Registered APNs device token with Supabase.")
        } catch {
            Self.log.error("Failed to register device token: \(error.localizedDescription)")
        }
    }

    func unregisterDeviceToken(_ token: String) async {
        guard !token.isEmpty else { return }

        do {
            try await supabase
                .from("device_tokens")
                .delete()
                .eq("user_id", value: userID.uuidString)
                .eq("apns_token", value: token)
                .execute()
            Self.log.info("Unregistered APNs device token.")
        } catch {
            Self.log.error("Failed to unregister device token: \(error.localizedDescription)")
        }
    }
}
