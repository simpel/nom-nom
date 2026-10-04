// DS-GAP: pending design system — see Core/Design/DS-GAPS.md
import SwiftUI

/// The dinner party basics shared by create and edit: up to five photos (the first is the cover), the
/// party name (a `plain` Input in a SectionCard) and an optional "About" TextArea.
/// Return in the name field runs `onSubmitName`.
struct PartyFormFields: View {
    @Binding var photoDraft: FoodStore.PhotosDraft
    @Binding var name: String
    @Binding var about: String
    var onSubmitName: (() -> Void)?

    init(
        photoDraft: Binding<FoodStore.PhotosDraft>,
        name: Binding<String>,
        about: Binding<String>,
        onSubmitName: (() -> Void)? = nil
    ) {
        self._photoDraft = photoDraft
        self._name = name
        self._about = about
        self.onSubmitName = onSubmitName
    }

    var body: some View {
        AssetPhotosPickerSection(
            draft: $photoDraft,
            title: "Photos",
            bucket: SupabaseConfig.partyBucket,
            maxCount: FoodStore.PhotosDraft.maxCount
        )

        SectionCard("Party Name") {
            Input("Party name (e.g. Taco Night)", text: $name, appearance: .plain)
                .autocorrectionDisabled()
                .onSubmit { onSubmitName?() }
        }

        SectionCard("About", trailing: "Optional") {
            NoteField("What is this dinner party about?", text: $about, title: "About")
        }
    }
}

private struct PartyFormFieldsPreview: View {
    @State private var photos = FoodStore.PhotosDraft()
    @State private var name = "Taco Night"
    @State private var about = ""

    var body: some View {
        NomNomPreview(inNavigationStack: false) { _ in
            ScrollView {
                VStack(spacing: DS.Spacing.block) {
                    PartyFormFields(photoDraft: $photos, name: $name, about: $about)
                }
                .padding(DS.Spacing.gutter)
            }
            .background(DS.Color.bg)
        }
    }
}

#Preview("Light") { PartyFormFieldsPreview() }
#Preview("Dark") { PartyFormFieldsPreview().preferredColorScheme(.dark) }
