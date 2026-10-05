import SwiftUI

/// Profile setup step in onboarding: the header's avatar (pen to add a photo; initials
/// once the name is typed) over the name fields.
struct OnboardingProfileStep: View {
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var photoDraft: FoodStore.PhotosDraft

    private var fullName: String { "\(firstName.trimmedName) \(lastName.trimmedName)" }
    /// Paths the draft started with, kept as removed when the photo is replaced.
    private var previousPaths: [String] { photoDraft.existingPaths + photoDraft.removedPaths }

    var body: some View {
        VStack(spacing: DS.Spacing.s8) {
            ScreenHeader(
                "Your seat at the table",
                summary: "Introduce yourself so the people you eat with recognise you.",
                avatar: Avatar(
                    name: fullName,
                    photoPath: photoDraft.existingPaths.first,
                    photoData: photoDraft.addedData.first
                ),
                avatarEdit: ScreenHeaderAvatarEdit(
                    hasPhoto: !photoDraft.isEmpty,
                    onPick: { photoDraft = FoodStore.PhotosDraft(addedData: [$0], removedPaths: previousPaths) },
                    onRemove: { photoDraft = FoodStore.PhotosDraft(removedPaths: previousPaths) }
                ),
                role: .moment
            )

            NameFieldsCard(firstName: $firstName, lastName: $lastName)
        }
    }
}
