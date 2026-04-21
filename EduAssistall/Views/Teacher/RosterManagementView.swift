import SwiftUI

struct RosterManagementView: View {
    let teacherProfile: UserProfile

    @State private var links: [StudentAdultLink] = []
    @State private var studentNames: [String: String] = [:]
    @State private var parentLinks: [String: [StudentAdultLink]] = [:]
    @State private var isLoading = true
    @State private var showImport = false
    @State private var transferTarget: StudentAdultLink?
    @State private var removeTarget: StudentAdultLink?
    @State private var showRemoveConfirm = false

    private var confirmed: [StudentAdultLink] { links.filter(\.confirmed) }
    private var pending:   [StudentAdultLink] { links.filter { !$0.confirmed } }

    var body: some View {
        List {
            if isLoading {
                ProgressView().frame(maxWidth: .infinity).listRowBackground(Color.clear)
            } else {
                if !confirmed.isEmpty {
                    Section("Active (\(confirmed.count))") {
                        ForEach(confirmed) { link in
                            StudentManagementRow(
                                link: link,
                                displayName: studentNames[link.studentId] ?? link.studentEmail,
                                parentLinks: parentLinks[link.studentId] ?? [],
                                onRemove: { removeTarget = link; showRemoveConfirm = true },
                                onTransfer: { transferTarget = link }
                            )
                        }
                    }
                }

                if !pending.isEmpty {
                    Section("Invitation Sent — Awaiting Sign-Up (\(pending.count))") {
                        ForEach(pending) { link in
                            StudentManagementRow(
                                link: link,
                                displayName: studentNames[link.studentId] ?? link.studentEmail,
                                parentLinks: [],
                                onRemove: { removeTarget = link; showRemoveConfirm = true },
                                onTransfer: nil
                            )
                        }
                    }
                }

                if links.isEmpty {
                    ContentUnavailableView(
                        "No Students Yet",
                        systemImage: "person.badge.plus",
                        description: Text("Import a spreadsheet or add students individually.")
                    )
                    .listRowBackground(Color.clear)
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.inset)
        #endif
        .background(Color.appGroupedBackground)
        .navigationTitle("Manage Roster")
        .inlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showImport = true
                } label: {
                    Label("Import", systemImage: "arrow.down.doc")
                }
            }
        }
        .sheet(isPresented: $showImport, onDismiss: { Task { await load() } }) {
            BulkImportView(teacherProfile: teacherProfile)
        }
        .sheet(item: $transferTarget) { link in
            TransferStudentView(
                link: link,
                studentName: studentNames[link.studentId] ?? link.studentEmail,
                onTransferred: {
                    links.removeAll { $0.id == link.id }
                }
            )
        }
        .confirmationDialog(
            "Remove \(removeTarget.map { studentNames[$0.studentId] ?? $0.studentEmail } ?? "student") from your class?",
            isPresented: $showRemoveConfirm,
            titleVisibility: .visible
        ) {
            Button("Remove from Class", role: .destructive) {
                if let link = removeTarget { remove(link) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The student's account and learning data are not deleted. They will no longer appear in your roster.")
        }
        .task { await load() }
        .refreshable { await load() }
    }

    // MARK: - Data

    private func load() async {
        isLoading = true
        links = (try? await FirestoreService.shared.fetchLinkedStudents(adultId: teacherProfile.id)) ?? []

        await withTaskGroup(of: Void.self) { group in
            for link in links {
                group.addTask {
                    let name = (try? await FirestoreService.shared.fetchUserProfile(uid: link.studentId))?.displayName
                    let parents = (try? await FirestoreService.shared.fetchLinkedAdults(studentId: link.studentId))
                        .map { $0.filter { $0.adultRole == .parent } } ?? []
                    await MainActor.run {
                        if let name { studentNames[link.studentId] = name }
                        parentLinks[link.studentId] = parents
                    }
                }
            }
        }
        isLoading = false
    }

    private func remove(_ link: StudentAdultLink) {
        Task {
            try? await FirestoreService.shared.declineLink(linkId: link.id)
            links.removeAll { $0.id == link.id }
        }
    }
}

// MARK: - Student Row

private struct StudentManagementRow: View {
    let link: StudentAdultLink
    let displayName: String
    let parentLinks: [StudentAdultLink]
    let onRemove: () -> Void
    let onTransfer: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Circle()
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 38, height: 38)
                    .overlay(
                        Text(displayName.prefix(1).uppercased())
                            .font(.subheadline.bold())
                            .foregroundStyle(.blue)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(displayName)
                        .font(.subheadline.bold())
                        .lineLimit(1)
                    Text(link.studentEmail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Menu {
                    if let transfer = onTransfer {
                        Button {
                            transfer()
                        } label: {
                            Label("Transfer to Another Teacher", systemImage: "arrow.triangle.2.circlepath")
                        }
                    }
                    Button(role: .destructive) {
                        onRemove()
                    } label: {
                        Label("Remove from Class", systemImage: "person.fill.xmark")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(.secondary)
                }
            }

            if !parentLinks.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "figure.2.and.child.holdinghands")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(parentLinks.map { $0.studentEmail }.joined(separator: ", "))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .padding(.leading, 48)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Transfer Sheet

private struct TransferStudentView: View {
    let link: StudentAdultLink
    let studentName: String
    let onTransferred: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var teacherEmail = ""
    @State private var isSearching = false
    @State private var foundTeacher: UserProfile?
    @State private var isTransferring = false
    @State private var errorMessage: String?
    @State private var transferred = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "person.fill")
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(studentName)
                                .font(.subheadline.bold())
                            Text(link.studentEmail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Student")
                }

                Section {
                    TextField("New teacher's email", text: $teacherEmail)
                        .emailInput()
                        .autocorrectionDisabled()

                    Button {
                        Task { await searchTeacher() }
                    } label: {
                        HStack {
                            Spacer()
                            if isSearching { ProgressView() }
                            else { Text("Find Teacher") }
                            Spacer()
                        }
                    }
                    .disabled(teacherEmail.isEmpty || isSearching)
                } header: {
                    Text("Transfer To")
                }

                if let teacher = foundTeacher {
                    Section("Found") {
                        HStack(spacing: 12) {
                            Image(systemName: "person.fill.checkmark")
                                .foregroundStyle(.green)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(teacher.displayName)
                                    .font(.subheadline.bold())
                                Text(teacher.email)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Button {
                            Task { await transfer(to: teacher) }
                        } label: {
                            HStack {
                                Spacer()
                                if isTransferring { ProgressView() }
                                else { Text("Confirm Transfer").fontWeight(.semibold) }
                                Spacer()
                            }
                        }
                        .disabled(isTransferring)
                        .foregroundStyle(.blue)
                    }
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.subheadline)
                    }
                }

                if transferred {
                    Section {
                        HStack {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                            Text("Transfer complete. Student removed from your roster.")
                                .font(.subheadline)
                        }
                    }
                }
            }
            .navigationTitle("Transfer Student")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(transferred ? "Done" : "Cancel") { dismiss() }
                }
            }
        }
    }

    private func searchTeacher() async {
        isSearching = true
        errorMessage = nil
        foundTeacher = nil
        do {
            foundTeacher = try await FirestoreService.shared.fetchTeacherByEmail(teacherEmail.lowercased().trimmingCharacters(in: .whitespaces))
            if foundTeacher == nil { errorMessage = "No teacher account found with that email." }
        } catch {
            errorMessage = "Could not search for teacher. Please try again."
        }
        isSearching = false
    }

    private func transfer(to newTeacher: UserProfile) async {
        isTransferring = true
        errorMessage = nil
        do {
            try await FirestoreService.shared.transferStudent(
                linkId: link.id,
                studentId: link.studentId,
                studentEmail: link.studentEmail,
                newTeacherId: newTeacher.id
            )
            transferred = true
            onTransferred()
        } catch {
            errorMessage = "Transfer failed. Please try again."
        }
        isTransferring = false
    }
}
