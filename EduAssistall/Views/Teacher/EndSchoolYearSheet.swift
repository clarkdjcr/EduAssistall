import SwiftUI

/// Confirmation sheet for the end-of-year class archival flow.
/// Marks all confirmed teacher→student links as archived, preserving all
/// student learning data while clearing the active roster.
struct EndSchoolYearSheet: View {
    let teacherProfile: UserProfile
    let activeLinks: [StudentAdultLink]
    let onArchived: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isArchiving = false
    @State private var errorMessage: String?
    @State private var done = false

    private var schoolYear: String { Self.currentSchoolYear() }

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Spacer()

                Image(systemName: "calendar.badge.checkmark")
                    .font(.system(size: 56))
                    .foregroundStyle(.orange)

                VStack(spacing: 10) {
                    Text("End School Year")
                        .font(.title2.bold())
                    Text("Archive \(activeLinks.count) student\(activeLinks.count == 1 ? "" : "s") from **\(schoolYear)**")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: 12) {
                    InfoRow(icon: "checkmark.circle.fill", color: .green,
                            text: "All student learning data and progress is preserved")
                    InfoRow(icon: "archivebox.fill", color: .blue,
                            text: "This class moves to Past Classes — accessible anytime")
                    InfoRow(icon: "person.badge.plus", color: .purple,
                            text: "Your roster will be empty, ready for a new class")
                }
                .padding(20)
                .background(Color.appSecondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 24)

                if let error = errorMessage {
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                Spacer()

                VStack(spacing: 12) {
                    Button {
                        Task { await archive() }
                    } label: {
                        Group {
                            if isArchiving {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                            } else {
                                Text("Archive Class & Start Fresh")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding()
                        .background(Color.orange)
                        .foregroundStyle(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(isArchiving || activeLinks.isEmpty)
                    .padding(.horizontal, 24)

                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 8)
                }
            }
            .navigationTitle("End School Year")
            .inlineNavigationTitle()
        }
        .alert("Class Archived", isPresented: $done) {
            Button("Done") {
                onArchived()
                dismiss()
            }
        } message: {
            Text("Your \(schoolYear) class has been archived. Your roster is now empty and ready for a new school year.")
        }
    }

    private func archive() async {
        isArchiving = true
        errorMessage = nil
        do {
            try await FirestoreService.shared.archiveClass(
                teacherId: teacherProfile.id,
                schoolYear: schoolYear,
                links: activeLinks
            )
            done = true
        } catch {
            errorMessage = "Archive failed. Please try again."
        }
        isArchiving = false
    }

    /// Returns the current academic school year string, e.g. "2025-2026".
    /// August onward = new year begins; January–July = still in prior year.
    static func currentSchoolYear() -> String {
        let year = Calendar.current.component(.year, from: Date())
        let month = Calendar.current.component(.month, from: Date())
        if month >= 8 {
            return "\(year)-\(year + 1)"
        } else {
            return "\(year - 1)-\(year)"
        }
    }
}

private struct InfoRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 22)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
    }
}
