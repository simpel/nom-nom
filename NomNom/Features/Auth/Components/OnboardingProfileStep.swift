import SwiftUI

/// Profile setup step in onboarding collecting name and optional avatar photo.
struct OnboardingProfileStep: View {
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var photoDraft: FoodStore.PhotosDraft

    var body: some View {
        VStack(spacing: DS.Spacing.section) {
            PageHeader(
                title: "Your Seat at the Table",
                subtitle: "Welcome to Nom Nom. Introduce yourself so companions recognize you at dinner."
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
