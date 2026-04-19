import SwiftUI

struct ComposeMessageView: View {
    let currentUser: UserProfile

    @Environment(\.dismiss) private var dismiss
    @State private var linkedStudents: [StudentAdultLink] = []
    @State private var selectedLink: StudentAdultLink?
    @State private var studentProfiles: [String: UserProfile] = [:]
    @State private var messageBody = ""
    @State private var isLoading = true
    @State private var isSending = false
    @State private var errorMessage: String?

    private var isValid: Bool {
        selectedLink != nil && !messageBody.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Regarding") {
                    if isLoading {
                        ProgressView()
                    } else if linkedStudents.isEmpty {
                        Text("No linked students found.")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Student", selection: $selectedLink) {
                            Text("Select a student").tag(StudentAdultLink?.none)
                            ForEach(linkedStudents) { link in
                                let name = studentProfiles[link.studentId]?.displayName ?? "Student"
                                Text(name).tag(StudentAdultLink?.some(link))
                            }
                        }
                    }
                }

                Section("Message") {
                    TextField("Write your message…", text: $messageBody, axis: .vertical)
                        .lineLimit(4...8)
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("New Message")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    if isSending {
                        ProgressView()
                    } else {
                        Button("Send") { Task { await send() } }
                            .fontWeight(.semibold)
                            .disabled(!isValid)
                    }
                }
            }
            .task { await loadStudents() }
        }
    }

    private func loadStudents() async {
        isLoading = true
        linkedStudents = (try? await FirestoreService.shared.fetchLinkedStudents(adultId: currentUser.id))?.filter(\.confirmed) ?? []
        // Fetch student profiles to display names
        for link in linkedStudents {
            if let profile = try? await FirestoreService.shared.fetchUserProfile(uid: link.studentId) {
                studentProfiles[link.studentId] = profile
            }
        }
        isLoading = false
    }

    private func send() async {
        guard let link = selectedLink else { return }
        isSending = true
        errorMessage = nil

        let studentName = studentProfiles[link.studentId]?.displayName ?? "Student"

        // Find other adults linked to the same student
        let otherLinks = (try? await FirestoreService.shared.fetchLinkedAdults(studentId: link.studentId)) ?? []
        let otherAdultIds = otherLinks.map(\.adultId).filter { $0 != currentUser.id }

        guard !otherAdultIds.isEmpty else {
            errorMessage = "No other contacts are linked to this student yet."
            isSending = false
            return
        }

        // Fetch other participant profiles
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
                body: messageBody.trimmingCharacters(in: .whitespaces)
            )
            try await FirestoreService.shared.sendMessage(message)
            dismiss()
        } catch {
            errorMessage = "Failed to send. Please try again."
        }
        isSending = false
    }
}
