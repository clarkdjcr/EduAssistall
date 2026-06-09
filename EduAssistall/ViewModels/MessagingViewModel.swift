import Foundation

@Observable
final class MessagingViewModel {
    var threads: [MessageThread] = []
    var isLoading = false

    // Compose state
    var linkedStudents: [StudentAdultLink] = []
    var studentProfiles: [String: UserProfile] = [:]
    var composeLoading = false
    var composeSending = false
    var composeError: String?

    func loadThreads(userId: String) async {
        isLoading = true
        let loaded = (try? await FirestoreService.shared.fetchMessageThreads(userId: userId)) ?? []
        threads = loaded.sorted {
            ($0.lastMessageAt ?? $0.createdAt) > ($1.lastMessageAt ?? $1.createdAt)
        }
        isLoading = false
    }

    func loadLinkedStudents(adultId: String) async {
        composeLoading = true
        linkedStudents = (try? await FirestoreService.shared.fetchLinkedStudents(adultId: adultId))?.filter(\.confirmed) ?? []
        for link in linkedStudents {
            if let profile = try? await FirestoreService.shared.fetchUserProfile(uid: link.studentId) {
                studentProfiles[link.studentId] = profile
            }
        }
        composeLoading = false
    }

    /// Returns true on success; sets `composeError` and returns false on failure.
    func sendNewThread(currentUser: UserProfile, link: StudentAdultLink, body: String) async -> Bool {
        composeSending = true
        composeError = nil
        let studentName = studentProfiles[link.studentId]?.displayName ?? "Student"

        let otherLinks = (try? await FirestoreService.shared.fetchLinkedAdults(studentId: link.studentId)) ?? []
        let otherAdultIds = otherLinks.map(\.adultId).filter { $0 != currentUser.id }

        guard !otherAdultIds.isEmpty else {
            composeError = "No other contacts are linked to this student yet."
            composeSending = false
            return false
        }

        var participantNames: [String: String] = [currentUser.id: currentUser.displayName]
        for adultId in otherAdultIds {
            if let profile = try? await FirestoreService.shared.fetchUserProfile(uid: adultId) {
                participantNames[adultId] = profile.displayName
            }
        }

        let allParticipants = [currentUser.id] + otherAdultIds
        let thread = MessageThread(
            participants: allParticipants,
            participantNames: participantNames,
            studentId: link.studentId,
            studentName: studentName
        )

        do {
            try await FirestoreService.shared.createMessageThread(thread)
            let message = Message(
                threadId: thread.id,
                senderId: currentUser.id,
                senderName: currentUser.displayName,
                body: body
            )
            try await FirestoreService.shared.sendMessage(message)
            composeSending = false
            return true
        } catch {
            composeError = "Failed to send. Please try again."
            composeSending = false
            return false
        }
    }
}
