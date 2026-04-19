import SwiftUI

struct ContentCatalogView: View {
    let teacherId: String
    let gradeLevel: String
    let onSelect: (ContentItem) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var subject = "Math"
    @State private var items: [CatalogItem] = []
    @State private var isLoading = false
    @State private var hasSearched = false
    @State private var errorMessage: String?

    private let subjects = ["Math", "Science", "Computing", "History", "English", "Economics", "Art"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterBar
                Divider()
                content
            }
            .background(Color.appGroupedBackground)
            .navigationTitle("Khan Academy Catalog")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        VStack(spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(subjects, id: \.self) { s in
                        Button(s) { subject = s }
                            .font(.subheadline)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(subject == s ? Color.blue : Color.blue.opacity(0.08))
                            .foregroundStyle(subject == s ? Color.white : Color.blue)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 16)
            }

            Button {
                Task { await search() }
            } label: {
                HStack {
                    if isLoading {
                        ProgressView().tint(Color.white)
                    } else {
                        Image(systemName: "magnifyingglass")
                    }
                    Text(isLoading ? "Fetching from Khan Academy…" : "Find \(subject) Content")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.blue)
                .foregroundStyle(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isLoading)
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 12)
        .background(Color.appSecondaryGroupedBackground)
    }

    // MARK: - Content Area

    @ViewBuilder
    private var content: some View {
        if isLoading {
            VStack(spacing: 14) {
                ProgressView()
                Text("Searching Khan Academy…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = errorMessage {
            VStack(spacing: 12) {
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 40))
                    .foregroundStyle(.orange)
                Text("Could not load content")
                    .font(.headline)
                Text(error)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(40)
        } else if items.isEmpty && hasSearched {
            VStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 40))
                    .foregroundStyle(.tertiary)
                Text("No results found")
                    .font(.headline)
                Text("Try a different subject.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if !items.isEmpty {
            List(items) { item in
                Button {
                    let contentItem = item.toContentItem(teacherId: teacherId, gradeLevel: gradeLevel)
                    onSelect(contentItem)
                    dismiss()
                } label: {
                    CatalogItemRow(item: item)
                }
                .buttonStyle(.plain)
            }
            #if os(iOS)
            .listStyle(.insetGrouped)
            #else
            .listStyle(.inset)
            #endif
        } else {
            // Pre-search prompt
            VStack(spacing: 14) {
                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.blue.opacity(0.4))
                Text("Select a subject and tap Find")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Search

    private func search() async {
        isLoading = true
        hasSearched = true
        errorMessage = nil
        do {
            items = try await CloudFunctionService.shared.curateContent(
                subject: subject,
                gradeLevel: gradeLevel
            )
        } catch {
            errorMessage = error.localizedDescription
            items = []
        }
        isLoading = false
    }
}

// MARK: - Catalog Item Row

private struct CatalogItemRow: View {
    let item: CatalogItem

    private var typeIcon: String { item.contentType == "video" ? "play.rectangle.fill" : "doc.text.fill" }
    private var typeColor: Color { item.contentType == "video" ? .red : .blue }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: typeIcon)
                .font(.title3)
                .foregroundStyle(typeColor)
                .frame(width: 32)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                if !item.description.isEmpty {
                    Text(item.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 10) {
                    Label("\(item.estimatedMinutes) min", systemImage: "clock")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Label(item.source == "khanacademy" ? "Khan Academy" : item.source,
                          systemImage: "checkmark.seal.fill")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
            }

            Spacer()

            Image(systemName: "plus.circle.fill")
                .font(.title3)
                .foregroundStyle(.blue)
        }
        .padding(.vertical, 4)
    }
}
