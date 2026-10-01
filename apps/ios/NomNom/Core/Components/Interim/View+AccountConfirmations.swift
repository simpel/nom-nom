// DS-GAP: pending design system — see Core/Design/DS-GAPS.md
import SwiftUI

// The one copy of the sign-out and delete-account confirmations (native alerts),
// shared by AccountActionsSection and SettingsDropdownMenu.

extension View {
    /// "Sign out?" alert; confirming unregisters this device and signs out.
    func signOutConfirmation(isPresented: Binding<Bool>) -> some View {
        modifier(SignOutConfirmationModifier(isPresented: isPresented))
    }

    /// "Delete your account?" alert, then a "Couldn't delete your account" alert on failure.
    func deleteAccountConfirmation(isPresented: Binding<Bool>) -> some View {
        modifier(DeleteAccountConfirmationModifier(isPresented: isPresented))
    }
}

private struct SignOutConfirmationModifier: ViewModifier {
    @Binding var isPresented: Bool
    @Environment(FoodStore.self) private var store
    @Environment(AuthController.self) private var auth

    func body(content: Content) -> some View {
        content.alert("Sign out?", isPresented: $isPresented) {
            Button("Sign out", role: .destructive) {
                Task {
                    await store.unregisterCurrentDevice()
                    await auth.signOut()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your food log stays on the server and comes back when you sign in again.")
        }
    }
}

private struct DeleteAccountConfirmationModifier: ViewModifier {
    @Binding var isPresented: Bool
    @Environment(AuthController.self) private var auth

    func body(content: Content) -> some View {
        content
            .alert("Delete your account?", isPresented: $isPresented) {
                Button("Delete everything", role: .destructive) {
                    Task { await auth.deleteAccount() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes your account, every meal and photo you've logged, and the people you track. It cannot be undone.")
            }
            .alert(
                "Couldn't delete your account",
                isPresented: Binding(
                    get: { auth.errorMessage != nil },
                    set: { if !$0 { auth.errorMessage = nil } }
                )
            ) {
                Button("OK") { auth.errorMessage = nil }
            } message: {
                Text(auth.errorMessage ?? "")
            }
    }
}
