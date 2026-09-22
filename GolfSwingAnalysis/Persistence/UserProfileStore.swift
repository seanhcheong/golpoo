import Foundation
import GolfSwingCore

/// Local-only storage for the one-time user profile field (height).
/// No account/cloud sync in v1 — this is a thin UserDefaults wrapper.
final class UserProfileStore {
    private let defaultsKey = "com.golfswinganalysis.userProfile"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> UserProfile? {
        guard let data = defaults.data(forKey: defaultsKey) else { return nil }
        return try? JSONDecoder().decode(UserProfile.self, from: data)
    }

    func save(_ profile: UserProfile) {
        guard let data = try? JSONEncoder().encode(profile) else { return }
        defaults.set(data, forKey: defaultsKey)
    }
}
