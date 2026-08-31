import SwiftUI
import PhotosUI

/// Add or edit one meal: photo, title (autofilled), date, dinner party serving, per-person verdicts, notes.
struct MealEditorView: View {
    var mealID: UUID?
    var initialDate: Date?
    var prefilledDishID: UUID?

    @Environment(FoodStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var linkedDishID: UUID?
    @State private var date = Date.now
    @State private var notes = ""
    @State private var verdicts: [RaterRef: Reaction] = [:]
    @State private var tagsText = ""
    @State private var selectedParties: Set<UUID> = []

    @State private var existingPath: String?
    @State private var pickedData: Data?
    @State private var didRemovePhoto = false

    @State private var pickerItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var loadingPhoto = false
    @State private var isSaving = false
    @State private var didLoad = false

    @State private var showingCreateParty = false
    @State private var newPartyName = ""
    @State private var navigateToVerdict = false

    private var meal: Meal? { mealID.flatMap { store.meal($0) } }
    private var isEditing: Bool { mealID != nil }
    private var canProceed: Bool { !title.trimmedName.isEmpty && !isSaving }

    private var currentDraft: FoodStore.MealDraft {
        let name = title.trimmedName
        let tags = tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }

        let photo: FoodStore.PhotoChange = {
            if let pickedData { return .replaced(pickedData) }
            if didRemovePhoto, existingPath != nil { return .removed }
            return .unchanged
        }()

        return FoodStore.MealDraft(mealID: mealID,
                                   dishName: name,
                                   linkedDishID: linkedDishID,
                                   eatenOn: date,
                                   notes: notes,
                                   tags: tags,
                                   photo: photo,
                                   verdicts: verdicts,
                                   servedParties: selectedParties)
    }

    var body: some View {
        NavigationStack {
            Form {
                MealEditorPhotoSection(pickedData: $pickedData,
                                       didRemovePhoto: $didRemovePhoto,
                                       pickerItem: $pickerItem,
                                       showCamera: $showCamera,
                                       existingPath: existingPath,
                                       loadingPhoto: loadingPhoto)
                titleSection
                partiesSection
                detailsSection
                if isEditing { inviteSection }
                if isEditing { deleteSection }
            }
            .navigationTitle(isEditing ? "Edit meal" : "New meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else if isEditing {
                        Button("Save") { save() }
                            .disabled(!canProceed)
                            .fontWeight(.semibold)
                    } else {
                        Button("Next") { navigateToVerdict = true }
                            .disabled(!canProceed)
                            .fontWeight(.semibold)
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToVerdict) {
                MealVerdictStepView(draft: currentDraft,
                                    pickedData: pickedData,
                                    existingPath: existingPath,
                                    onDismiss: { dismiss() })
            }
            .alert("New Dinner Party", isPresented: $showingCreateParty) {
                TextField("Party name", text: $newPartyName)
                Button("Create") {
                    let name = newPartyName.trimmedName
                    guard !name.isEmpty else { return }
                    Task {
                        if let created = await store.createParty(name: name) {
                            selectedParties.insert(created.id)
                            newPartyName = ""
                        }
                    }
                }
                Button("Cancel", role: .cancel) { newPartyName = "" }
            }
            .sheet(isPresented: $showCamera) {
                CameraPicker { image in
                    pickedData = PhotoTools.prepare(image)
                    didRemovePhoto = false
                }
                .ignoresSafeArea()
            }
            .task(id: pickerItem) { await loadPickedPhoto() }
            .onAppear(perform: loadIfNeeded)
            .interactiveDismissDisabled(isSaving)
        }
    }

    // MARK: - Form Sections

    private var titleSection: some View {
        Section("What was it?") {
            DishNameField(text: $title,
                          linkedDishID: $linkedDishID,
                          dishes: store.myDishes,
                          history: store.dishHistory)
        }
    }

    private var partiesSection: some View {
        Section {
            ForEach(store.myParties) { party in
                Toggle(isOn: Binding(
                    get: { selectedParties.contains(party.id) },
                    set: { isSelected in
                        if isSelected {
                            selectedParties.insert(party.id)
                        } else {
                            selectedParties.remove(party.id)
                        }
                    }
                )) {
                    Label(party.name, systemImage: "person.2.fill")
                }
            }

            Button {
                showingCreateParty = true
            } label: {
                Label("Create new party...", systemImage: "plus")
                    .font(.subheadline)
            }
        } header: {
            Text("Serve to Dinner Parties")
        }
    }

    private var detailsSection: some View {
        Section("Details") {
            DatePicker("When", selection: $date, displayedComponents: [.date])
            TextField("Tags, comma separated", text: $tagsText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            TextField("Notes", text: $notes, axis: .vertical)
                .lineLimit(2...5)
        }
    }

    @ViewBuilder
    private var inviteSection: some View {
        if let meal, meal.createdBy == store.userID {
            Section {
                NavigationLink {
                    InviteView(mealID: meal.id)
                } label: {
                    let count = store.invites(forMeal: meal.id).count
                    Label(count == 0 ? "Ask someone to rate this"
                                     : "Invited \(count) \(count == 1 ? "person" : "people")",
                          systemImage: "person.badge.plus")
                }
            } footer: {
                Text("They'll get this meal in their inbox and can leave their own verdict.")
            }
        }
    }

    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                guard let meal else { return }
                Task {
                    await store.delete(meal: meal)
                    dismiss()
                }
            } label: {
                Label("Delete this meal", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .disabled(isSaving)
        }
    }

    // MARK: - Load / save

    private func loadIfNeeded() {
        guard !didLoad else { return }
        didLoad = true

        guard let meal else {
            if let initialDate { date = initialDate }
            if let prefilledDishID, let dish = store.dish(prefilledDishID) {
                title = dish.name
                linkedDishID = dish.id
                tagsText = dish.tags.joined(separator: ", ")
            }
            if let party = store.currentParty {
                selectedParties.insert(party.id)
            }
            return
        }

        let dish = store.dish(meal.dishID)
        title = dish?.name ?? ""
        linkedDishID = dish?.id
        date = meal.eatenOn
        notes = meal.notes
        existingPath = meal.photoPath
        tagsText = (dish?.tags ?? []).joined(separator: ", ")
        selectedParties = Set(store.parties(forMeal: meal.id).map(\.id))

        let mine = Set(store.myEaters.map(\.id))
        var loaded: [RaterRef: Reaction] = [:]
        for rating in store.ratings(forMeal: meal.id) {
            switch rating.source {
            case .eater(let id) where mine.contains(id):
                loaded[.eater(id)] = rating.reaction
            case .account(let id) where id == store.userID:
                loaded[.account(id)] = rating.reaction
            default:
                continue
            }
        }
        verdicts = loaded
    }

    private func loadPickedPhoto() async {
        guard let pickerItem else { return }
        loadingPhoto = true
        defer { loadingPhoto = false }
        if let data = try? await pickerItem.loadTransferable(type: Data.self) {
            pickedData = PhotoTools.prepare(data) ?? data
            didRemovePhoto = false
        }
    }

    private func save() {
        let name = title.trimmedName
        guard !name.isEmpty else { return }

        let tags = tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }

        let photo: FoodStore.PhotoChange = {
            if let pickedData { return .replaced(pickedData) }
            if didRemovePhoto, existingPath != nil { return .removed }
            return .unchanged
        }()

        let draft = FoodStore.MealDraft(mealID: mealID,
                                        dishName: name,
                                        linkedDishID: linkedDishID,
                                        eatenOn: date,
                                        notes: notes,
                                        tags: tags,
                                        photo: photo,
                                        verdicts: verdicts,
                                        servedParties: selectedParties)

        isSaving = true
        Task {
            let ok = await store.save(draft)
            isSaving = false
            if ok { dismiss() }
        }
    }
}
