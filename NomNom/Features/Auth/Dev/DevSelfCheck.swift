import Foundation
import OSLog
import UIKit

#if DEBUG
/// Exercises the store's write paths against the local stack and logs the result.
///
///     xcrun simctl launch <device> se.joelsanden.nomnom \
///         -dev-sign-in cook@foodlog.test -dev-selfcheck
///     xcrun simctl spawn <device> log stream --predicate 'subsystem == "NomNom"'
///
/// This exists because the interesting writes — inviting somebody, rating a meal
/// you were invited to, uploading and then removing a photo — are only reachable
/// by tapping, and a headless simulator has no way to tap. Every step here calls
/// the same `FoodStore` method the corresponding button calls, so what it covers is
/// the store and its round trip through PostgREST and Storage. It says nothing
/// about whether the buttons are wired to those methods.
///
/// Local stack only, and compiled out of release builds.
enum DevSelfCheck {

    private static let log = Logger(subsystem: "NomNom", category: "selfcheck")

    static var isRequested: Bool {
        LaunchArgumentsParser.parse().devSelfCheck
    }

    private static var isLocalStack: Bool {
        let host = SupabaseConfig.url.host() ?? ""
        return host == "127.0.0.1" || host == "localhost" || host == "::1"
    }

    @MainActor
    static func runIfRequested(_ store: FoodStore) async {
        guard isRequested else { return }
        guard isLocalStack else {
            log.error("refusing to run against \(SupabaseConfig.url.absoluteString, privacy: .public)")
            return
        }

        var passes = 0
        var failures: [String] = []

        func check(_ name: String, _ condition: Bool, _ detail: String = "") {
            if condition {
                passes += 1
                log.info("PASS  \(name, privacy: .public)")
            } else {
                failures.append(name)
                log.error("FAIL  \(name, privacy: .public)  \(detail, privacy: .public)")
            }
        }

        log.info("--- self check start ---")

        // 1. Create a meal with a photo, the way the editor does.
        let created = await store.save(FoodStore.MealDraft(
            mealID: nil,
            dishName: "Selfcheck Stew",
            linkedDishID: nil,
            eatenOn: .now,
            notes: "written by the self check",
            tags: ["selfcheck"],
            photos: FoodStore.PhotosDraft(addedData: [swatch()]),
            verdicts: store.activeEaters.first.map { [$0.raterRef: .amazing] } ?? [:]
        ))
        check("save a new meal with a photo", created, store.errorMessage ?? "")

        guard let meal = store.myMeals.first(where: {
            store.dish($0.dishID)?.normalizedName == "selfcheck stew"
        }) else {
            log.error("FAIL  the saved meal is not in the store; stopping")
            return
        }

        check("the photo got a storage path", meal.photoPath != nil)
        if let path = meal.photoPath {
            PhotoCache.shared.forget(path)
            let downloaded = await PhotoCache.shared.data(for: path)
            check("the photo downloads back out of the private bucket",
                  (downloaded?.count ?? 0) > 0)
        }
        check("the verdict was recorded",
              store.activeEaters.isEmpty || !store.ratings(forMeal: meal.id).isEmpty)

        // 2. Invite an address that already has an account. The trigger should
        //    resolve it, which is what makes the invite visible to them at all.
        //
        //    Create that account first. This used to depend on one surviving from an
        //    earlier run, so the check passed on a database that had been used before
        //    and failed on a freshly reset one.
        let guestEmail = "guest@foodlog.test"
        check("the guest account exists to be invited",
              await DevSignIn.ensureAccount(guestEmail))
        let invited = await store.invite(email: guestEmail, toMeal: meal.id)
        check("invite an existing account by email", invited, store.errorMessage ?? "")
        let invite = store.invites(forMeal: meal.id).first
        check("the invite resolved to an account", invite?.inviteeID != nil,
              String(describing: invite?.inviteeEmail))

        // 3. Change a verdict, which is the update-not-insert branch of the diff.
        if let eater = store.activeEaters.first {
            let changed = await store.save(FoodStore.MealDraft(
                mealID: meal.id,
                dishName: "Selfcheck Stew",
                linkedDishID: meal.dishID,
                eatenOn: meal.eatenOn,
                notes: meal.notes,
                tags: [],
                photos: FoodStore.PhotosDraft(existingPaths: meal.photoPaths),
                verdicts: [eater.raterRef: .bad]
            ))
            check("edit an existing verdict", changed, store.errorMessage ?? "")
            check("the verdict actually changed",
                  store.ratings(forMeal: meal.id).first { $0.eaterID == eater.id }?.reaction == .bad)
            check("one verdict per person, not a duplicate",
                  store.ratings(forMeal: meal.id).filter { $0.eaterID == eater.id }.count == 1)
        }

        // 4. Rate a meal somebody else invited me to.
        if let theirs = store.awaitingMyRating.first {
            let before = store.myRating(forMeal: theirs.id)
            await store.rate(mealID: theirs.id, as: .good)
            check("rate a meal I was invited to",
                  store.myRating(forMeal: theirs.id) == .good,
                  "was \(String(describing: before)); \(store.errorMessage ?? "")")
            check("the invite was marked answered",
                  store.invites(forMeal: theirs.id)
                      .first { $0.inviteeID == store.userID }?.status == .accepted)
        } else {
            log.info("SKIP  no pending invitation to rate")
        }

        // 5. Inbox.
        if store.unreadCount > 0 {
            await store.markAllRead()
            check("mark every notification read", store.unreadCount == 0, store.errorMessage ?? "")
        } else {
            log.info("SKIP  nothing unread")
        }

        // 6. Remove the photo, then the meal.
        let oldPath = meal.photoPath
        let cleared = await store.save(FoodStore.MealDraft(
            mealID: meal.id,
            dishName: "Selfcheck Stew",
            linkedDishID: meal.dishID,
            eatenOn: meal.eatenOn,
            notes: meal.notes,
            tags: [],
            photos: FoodStore.PhotosDraft(removedPaths: meal.photoPaths),
            verdicts: [:]
        ))
        check("remove a photo", cleared, store.errorMessage ?? "")
        check("the path was cleared", store.meal(meal.id)?.photoPath == nil)
        check("clearing the verdicts deleted them", store.ratings(forMeal: meal.id).isEmpty)
        if oldPath != nil {
            // Listed rather than downloaded, and not asked of PhotoCache.
            //
            // Two layers of caching sit in front of a download and both lie here.
            // PhotoCache gets re-populated by the live list behind this screen,
            // which renders the new meal and fetches its photo concurrently with the
            // removal. And `URLSession.shared` keeps the earlier 200 in `URLCache`,
            // so a GET for the deleted path is answered from disk without touching
            // the server. `list` is a POST, so nothing caches it.
            var remaining = -1
            do {
                remaining = try await supabase.storage
                    .from(SupabaseConfig.photoBucket)
                    .list(path: meal.id.uuidString.lowercased())
                    .count
            } catch {
                log.error("could not list the meal's folder: \(error.localizedDescription, privacy: .public)")
            }
            check("the storage object is gone", remaining == 0, "\(remaining) object(s) left")
        }

        await store.delete(meal: meal)
        check("delete the meal", store.meal(meal.id) == nil, store.errorMessage ?? "")

        // The store surfaces errors through an alert; a self check that left one
        // set would pop a dialog over whatever gets screenshotted next.
        store.errorMessage = nil

        if failures.isEmpty {
            log.info("--- self check: \(passes, privacy: .public)/\(passes, privacy: .public) passed ---")
        } else {
            log.error("--- self check: \(passes, privacy: .public) passed, FAILED: \(failures.joined(separator: ", "), privacy: .public) ---")
        }
    }

    /// A small solid JPEG, so there is something real to upload.
    private static func swatch() -> Data {
        let size = CGSize(width: 240, height: 240)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor.systemTeal.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        return image.jpegData(compressionQuality: 0.8) ?? Data()
    }
}
#endif
