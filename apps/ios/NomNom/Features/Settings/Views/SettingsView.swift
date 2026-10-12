import SwiftUI

/// App settings: notifications and debug tools. Account actions live on the profile.
struct SettingsView: View {
    @Environment(FoodStore.self) private var store

    @State private var isSeeding = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.s8) {
                NotificationPreferencesSection()
                #if DEBUG
                sampleDataSection
                #endif
            }
            .padding(.horizontal, DS.Spacing.gutter)
            .padding(.top, DS.Spacing.s5)
            .padding(.bottom, DS.Spacing.s11)
        }
        .background(DS.Color.bg)
        .screenTitle("Settings")
    }

    #if DEBUG
    private var sampleDataSection: some View {
        SectionCard("Debug tools") {
            AppButton(
                "Fill with sample history",
                variant: .secondary,
                appearance: .outline,
                fullWidth: true,
                isLoading: isSeeding
            ) {
                isSeeding = true
                Task {
                    await SampleData.populate(store)
                    isSeeding = false
                }
            }

            Text("Debug builds only — adds a few months of made-up meals so the suggestions have something to work with. Writes to whichever Supabase this build points at.")
                .textStyle(.sansSm, tone: .tertiary)
        }
    }
    #endif
}

#Preview {
    NomNomPreview {
        SettingsView()
    }
}
