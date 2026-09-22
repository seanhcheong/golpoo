import Foundation
import GolfSwingCore

final class SwingSetupViewModel: ObservableObject {
    @Published var cameraAngle: CameraAngle = .faceOn
    @Published var heightFeet: Int = 5
    @Published var heightInches: Int = 10

    /// Fixed in v1 — Full Swing is the only supported club category.
    let clubCategory: ClubCategory = .fullSwing

    private let profileStore: UserProfileStore

    init(profileStore: UserProfileStore = UserProfileStore()) {
        self.profileStore = profileStore
        if let profile = profileStore.load() {
            let totalInches = Int(profile.heightInInches.rounded())
            heightFeet = totalInches / 12
            heightInches = totalInches % 12
        }
    }

    var heightInInches: Double {
        Double(heightFeet * 12 + heightInches)
    }

    @discardableResult
    func confirmProfile() -> UserProfile {
        let profile = UserProfile(heightInInches: heightInInches)
        profileStore.save(profile)
        return profile
    }
}
