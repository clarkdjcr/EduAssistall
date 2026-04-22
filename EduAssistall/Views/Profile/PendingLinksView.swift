import SwiftUI

struct PendingLinksView: View {
    let studentId: String

    @State private var links: [StudentAdultLink] = []
    @State private var adultNames: [String: String] = [:]
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if links.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.badge.checkmark")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No Pending Requests")
                        .font(.title3.bold())
                    Text("You'll see link requests from parents and teachers here.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    Section {
                        ForEach(links) { link in
                            LinkRequestRow(
                                link: link,
                                adultName: adultNames[link.adultId] ?? link.studentEmail,
                                onAccept: { accept(link) },
                                onDecline: { decline(link) }
                            )
                        }
                    } footer: {
                        Text("Accepting a request lets this person view your progress, reports, and message your teacher.")
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
        .navigationTitle("Link Requests")
        .inlineNavigationTitle()
        .task { await load() }
    }

    private func load() async {
        isLoading = true
        let all = (try? await FirestoreService.shared.fetchPendingLinks(studentId: studentId)) ?? []
        // Filter out expired requests — the nightly purge removes them from Firestore but they
        // can persist until the next run. Don't show them as actionable.
        links = all.filter { $0.expiresAt > Date() }
        // Resolve adult display names
        for link in links {
            let name = (try? await FirestoreService.shared.fetchUserProfile(uid: link.adultId))?.displayName
            if let name { adultNames[link.adultId] = name }
        }
        isLoading = false
    }

    private func accept(_ link: StudentAdultLink) {
        Task {
            try? await FirestoreService.shared.confirmLink(linkId: link.id)
            links.removeAll { $0.id == link.id }
        }
    }

    private func decline(_ link: StudentAdultLink) {
        Task {
            try? await FirestoreService.shared.declineLink(linkId: link.id)
            links.removeAll { $0.id == link.id }
        }
    }
}

// MARK: - Row

private struct LinkRequestRow: View {
    let link: StudentAdultLink
    let adultName: String
    let onAccept: () -> Void
    let onDecline: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: link.adultRole == .parent ? "figure.2.and.child.holdinghands" : "person.fill.checkmark")
                    .font(.title2)
                    .foregroundStyle(.blue)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(adultName)
                        .font(.subheadline.bold())
                    Text(link.adultRole == .parent ? "Parent / Guardian" : "Teacher")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Requested \(link.createdAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            HStack(spacing: 10) {
                Button {
                    onDecline()
                } label: {
                    Text("Decline")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.secondary.opacity(0.12))
                        .foregroundStyle(.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)

                Button {
                    onAccept()
                } label: {
                    Text("Accept")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .foregroundStyle(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 6)
    }
}
