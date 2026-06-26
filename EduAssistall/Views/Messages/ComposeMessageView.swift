import SwiftUI

struct ComposeMessageView: View {
    let currentUser: UserProfile
    @Bindable var vm: MessagingViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var selectedLink: StudentAdultLink?
    @State private var messageBody = ""

    private var isValid: Bool {
        selectedLink != nil && !messageBody.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Regarding") {
                    if vm.composeLoading {
                        ProgressView()
                    } else if vm.linkedStudents.isEmpty {
                        Text("No linked students found.")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Student", selection: $selectedLink) {
                            Text("Select a student").tag(StudentAdultLink?.none)
                            ForEach(vm.linkedStudents) { link in
                                let name = vm.studentProfiles[link.studentId]?.displayName ?? "Student"
                                Text(name).tag(StudentAdultLink?.some(link))
                            }
                        }
                    }
                }

                Section("Message") {
                    TextField("Write your message…", text: $messageBody, axis: .vertical)
                        .lineLimit(4...8)
                }

                if let error = vm.composeError {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundStyle(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.primary)
                        }
                        .padding(4)
                    }
                }
            }
            .navigationTitle("New Message")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    if vm.composeSending {
                        ProgressView()
                    } else {
                        Button("Send") {
                            Task {
                                guard let link = selectedLink else { return }
                                let body = messageBody.trimmingCharacters(in: .whitespaces)
                                let success = await vm.sendNewThread(currentUser: currentUser, link: link, body: body)
                                if success { dismiss() }
                            }
                        }
                        .fontWeight(.semibold)
                        .disabled(!isValid)
                    }
                }
            }
            .task { await vm.loadLinkedStudents(adultId: currentUser.id) }
        }
    }
}
