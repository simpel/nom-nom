import SwiftUI

/// Profile setup step in onboarding collecting name and optional avatar photo.
struct OnboardingProfileStep: View {
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var photoDraft: FoodStore.PhotosDraft

    var body: some View {
        VStack(spacing: DS.Spacing.section) {
            PageHeader(
                title: "About You",
                subtitle: "Help your dinner party companions recognize you."
            )

            AssetPhotosPickerSection(
                draft: $photoDraft,
                title: "Profile Photo",
                bucket: SupabaseConfig.profileBucket,
                maxCount: 1
            )

            SectionCard("Your Name") {
                VStack(spacing: 10) {
                    Input("First name", text: $firstName)
                        .textContentType(.givenName)
                        .textInputAutocapitalization(.words)

                    Input("Last name", text: $lastName)
                        .textContentType(.familyName)
                        .textInputAutocapitalization(.words)
                }
            }
        }
    }
}
