import SwiftUI

struct DocumentResultView: View {
    let title: String
    let body: String
    let sharepointItemId: String?
    let documentType: String

    @State private var showCopied = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if sharepointItemId != nil {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Saved to OfficialDocuments")
                                    .font(.subheadline.bold())
                                Text("Pending your approval in SharePoint")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(12)
                        .background(Color.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                    }

                    Text(body)
                        .font(.body)
                        .textSelection(.enabled)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.appSecondaryBackground, in: RoundedRectangle(cornerRadius: 12))
                }
                .padding()
            }
            .background(Color.appGroupedBackground)
            .navigationTitle(title)
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        copyToClipboard(body)
                        showCopied = true
                        Task {
                            try? await Task.sleep(for: .seconds(2))
                            showCopied = false
                        }
                    } label: {
                        Label(
                            showCopied ? "Copied" : "Copy",
                            systemImage: showCopied ? "checkmark" : "doc.on.doc"
                        )
                    }

                    ShareLink(item: body, subject: Text(title), message: Text("Draft \(documentType) from EduAssist"))
                }
            }
        }
    }
}
