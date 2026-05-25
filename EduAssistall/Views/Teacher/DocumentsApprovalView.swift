import SwiftUI
import FirebaseFirestore

struct DocumentsApprovalView: View {
    let teacherProfile: UserProfile

    @State private var pendingDocs: [PendingDoc] = []
    @State private var isLoading       = true
    @State private var errorMessage: String?
    @State private var actionInProgress = Set<String>()
    @State private var actionError: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading documents…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let err = errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.orange)
                    Text(err).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else if pendingDocs.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)
                    Text("All Caught Up")
                        .font(.title3.bold())
                    Text("No documents are waiting for your approval.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    if let err = actionError {
                        Section {
                            Label(err, systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange).font(.subheadline)
                        }
                    }
                    Section {
                        ForEach(pendingDocs) { doc in
                            DocRow(
                                doc: doc,
                                inProgress: actionInProgress.contains(doc.id),
                                onApprove: { Task { await act(documentId: doc.id, action: "approve") } },
                                onReject:  { Task { await act(documentId: doc.id, action: "reject") } }
                            )
                        }
                    } header: {
                        Text("\(pendingDocs.count) pending approval")
                    }
                }
                #if os(iOS)
                .listStyle(.insetGrouped)
                #else
                .listStyle(.inset)
                #endif
            }
        }
        .background(Color.appGroupedBackground)
        .navigationTitle("Documents Approval")
        .inlineNavigationTitle()
        .task { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let db = Firestore.firestore()
            let snap = try await db.collection("officialDocuments")
                .whereField("teacherUid", isEqualTo: teacherProfile.id)
                .whereField("approvalStatus", isEqualTo: "PendingApproval")
                .order(by: "createdAt", descending: true)
                .limit(to: 50)
                .getDocuments()
            pendingDocs = snap.documents.compactMap { PendingDoc(from: $0) }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func act(documentId: String, action: String) async {
        actionInProgress.insert(documentId)
        actionError = nil
        do {
            try await CloudFunctionService.shared.approveDocument(documentId: documentId, action: action)
            pendingDocs.removeAll { $0.id == documentId }
        } catch {
            actionError = error.localizedDescription
        }
        actionInProgress.remove(documentId)
    }
}

// MARK: - Supporting Types

struct PendingDoc: Identifiable {
    let id: String
    let title: String
    let documentType: String
    let gradeLevel: String
    let subject: String
    let createdAt: Date?

    init?(from snap: DocumentSnapshot) {
        guard let data = snap.data() else { return nil }
        id           = snap.documentID
        title        = data["title"]        as? String ?? "Untitled"
        documentType = data["documentType"] as? String ?? "Document"
        gradeLevel   = data["gradeLevel"]   as? String ?? ""
        subject      = data["subject"]      as? String ?? ""
        createdAt    = (data["createdAt"] as? Timestamp)?.dateValue()
    }
}

// MARK: - Doc Row

private struct DocRow: View {
    let doc: PendingDoc
    let inProgress: Bool
    let onApprove: () -> Void
    let onReject: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: iconName(for: doc.documentType))
                    .foregroundStyle(.blue)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(doc.title)
                        .font(.subheadline.bold())
                        .lineLimit(2)
                    HStack(spacing: 6) {
                        if !doc.gradeLevel.isEmpty { chip("Grade \(doc.gradeLevel)") }
                        if !doc.subject.isEmpty    { chip(doc.subject) }
                        chip(doc.documentType)
                    }
                }
            }
            if let date = doc.createdAt {
                Text("Generated \(date.formatted(.relative(presentation: .named)))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            if inProgress {
                ProgressView().frame(maxWidth: .infinity, alignment: .center)
            } else {
                HStack(spacing: 12) {
                    Button(action: onReject) {
                        Label("Reject", systemImage: "xmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)

                    Button(action: onApprove) {
                        Label("Approve", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func chip(_ text: String) -> some View {
        Text(text)
            .font(.caption2.bold())
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(Color.secondary.opacity(0.12))
            .clipShape(Capsule())
    }

    private func iconName(for type: String) -> String {
        switch type {
        case "LessonPlan":   return "book.fill"
        case "ParentLetter": return "envelope.fill"
        default:             return "doc.fill"
        }
    }
}
