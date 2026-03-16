import Foundation
import Observation

@Observable
class ProfileViewModel {
    var profile: UserProfile = PreviewData.userProfile

    func uploadDocument(_ category: DocumentCategory) {
        guard let idx = profile.documents.firstIndex(where: { $0.category == category }) else { return }
        profile.documents[idx].isUploaded = true
        profile.documents[idx].uploadedAt = Date()
    }

    func removeDocument(_ category: DocumentCategory) {
        guard let idx = profile.documents.firstIndex(where: { $0.category == category }) else { return }
        profile.documents[idx].isUploaded = false
        profile.documents[idx].uploadedAt = nil
        profile.documents[idx].showOnProfile = false
        profile.documents[idx].publicTitle = ""
    }

    func toggleProfileVisibility(_ category: DocumentCategory) {
        guard let idx = profile.documents.firstIndex(where: { $0.category == category }) else { return }
        profile.documents[idx].showOnProfile.toggle()
    }

    func setPublicTitle(_ title: String, for category: DocumentCategory) {
        guard let idx = profile.documents.firstIndex(where: { $0.category == category }) else { return }
        profile.documents[idx].publicTitle = title
    }
}
