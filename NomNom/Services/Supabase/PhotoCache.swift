import Foundation
import Supabase

/// Fetches meal photos out of the private `meal-photos` bucket, once each.
///
/// A private bucket has no plain URL to hand to `AsyncImage`: every read is an
/// authenticated request carrying the user's token, which the storage policy checks
/// against the meal id in the object path. So the app downloads bytes itself and
/// has to do its own caching — without it, scrolling the calendar would re-download
/// a photo for every cell that came back on screen.
///
/// Cache entries never need invalidating. A replaced photo is written to a brand
/// new `<meal_id>/<uuid>.jpg`, so a path always refers to the same bytes.
@MainActor
final class PhotoCache {
    static let shared = PhotoCache()

    /// `NSCache` rather than a dictionary so photos are evicted under memory
    /// pressure instead of growing without bound.
    private let memory: NSCache<NSString, NSData> = {
        let cache = NSCache<NSString, NSData>()
        cache.totalCostLimit = 48 * 1024 * 1024
        return cache
    }()

    /// One download per path even when several cells ask at once.
    private var inFlight: [String: Task<Data?, Never>] = [:]

    private let directory: URL?

    private init() {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        directory = base?.appending(path: "MealPhotos", directoryHint: .isDirectory)
        if let directory {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
    }

    /// Already in memory, so a view can draw on first layout without a flash.
    func cached(_ path: String) -> Data? {
        memory.object(forKey: path as NSString) as Data?
    }

    func data(for path: String, bucket: String = SupabaseConfig.photoBucket) async -> Data? {
        if let hit = cached(path) { return hit }

        if let onDisk = readFromDisk(path) {
            store(onDisk, for: path, writeToDisk: false)
            return onDisk
        }

        if let running = inFlight[path] {
            return await running.value
        }

        let task = Task<Data?, Never> {
            do {
                let data = try await supabase.storage
                    .from(bucket)
                    .download(path: path)
                return data
            } catch {
                #if DEBUG
                print("[PhotoCache] download failed for \(path) from \(bucket): \(error)")
                #endif
                return nil
            }
        }
        inFlight[path] = task
        let data = await task.value
        inFlight[path] = nil

        if let data { store(data, for: path, writeToDisk: true) }
        return data
    }

    /// Seeds the cache with bytes we already hold, right after an upload, so the
    /// photo the user just picked isn't downloaded straight back.
    func put(_ data: Data, for path: String) {
        store(data, for: path, writeToDisk: true)
    }

    func forget(_ path: String) {
        memory.removeObject(forKey: path as NSString)
        if let file = fileURL(for: path) {
            try? FileManager.default.removeItem(at: file)
        }
    }

    // MARK: - Disk

    private func store(_ data: Data, for path: String, writeToDisk: Bool) {
        memory.setObject(data as NSData, forKey: path as NSString, cost: data.count)
        guard writeToDisk, let file = fileURL(for: path) else { return }
        try? data.write(to: file, options: .atomic)
    }

    private func readFromDisk(_ path: String) -> Data? {
        guard let file = fileURL(for: path) else { return nil }
        return try? Data(contentsOf: file)
    }

    /// Object paths contain a `/`, which cannot appear in a file name.
    private func fileURL(for path: String) -> URL? {
        guard let directory else { return nil }
        let safe = path.replacingOccurrences(of: "/", with: "_")
        guard !safe.isEmpty else { return nil }
        return directory.appending(path: safe, directoryHint: .notDirectory)
    }
}
