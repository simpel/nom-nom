import SwiftUI

/// Profile setup step in onboarding collecting name and optional avatar photo.
struct OnboardingProfileStep: View {
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var photoDraft: FoodStore.PhotosDraft

    var body: some View {
        VStack(spacing: DS.Spacing.section) {
            PageHeader(
                "Your seat at the table",
                subtitle: "Introduce yourself so the people you eat with recognise you.",
                align: .center
            )

            AssetPhotosPickerSection(
                draft: $photoDraft,
                title: "Profile Photo",
                bucket: SupabaseConfig.profileBucket,
                maxCount: 1
            )

            NameFieldsCard(firstName: $firstName, lastName: $lastName)
        }
    }
}
