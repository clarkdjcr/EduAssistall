import SwiftUI

private let gradeRanges = ["K–2", "3–5", "6–8", "9–12", "College"]

struct TeacherSetupView: View {
    @Binding var school: String
    @Binding var grades: [String]
    let teacherId: String
    let onComplete: () -> Void

    @State private var selectedGrades: Set<String> = []
    @State private var classroomImportState: ClassroomImportState = .idle

    private enum ClassroomImportState {
        case idle, loading, success(Int), failure(String)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                VStack(spacing: 8) {
                    Image(systemName: "person.fill.checkmark")
                        .font(.system(size: 48))
                        .foregroundStyle(.blue)
                        .padding(.top, 32)

                    Text("Tell us about your class")
                        .font(.title.bold())

                    Text("We'll tailor your dashboard and tools to your students.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                VStack(alignment: .leading, spacing: 20) {
                    // School name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("School Name")
                            .font(.headline)
                        TextField("e.g. Lincoln Elementary", text: $school)
                            .padding()
                            .background(Color.appSecondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Grade ranges
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Grade Levels You Teach")
                            .font(.headline)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
                            ForEach(gradeRanges, id: \.self) { range in
                                Button {
                                    toggleGrade(range)
                                } label: {
                                    Text(range)
                                        .font(.subheadline.bold())
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(selectedGrades.contains(range) ? Color.blue : Color.appSecondaryBackground)
                                        .foregroundStyle(selectedGrades.contains(range) ? Color.white : Color.primary)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Google Classroom roster import
                    #if canImport(GoogleSignIn)
                    classroomImportSection
                    #endif
                }
                .padding(.horizontal, 24)

                Button {
                    grades = Array(selectedGrades)
                    onComplete()
                } label: {
                    Text("Continue")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Your Class")
        .inlineNavigationTitle()
    }

    // MARK: - Classroom Import Section

    #if canImport(GoogleSignIn)
    @Environment(AuthViewModel.self) private var authVM

    @ViewBuilder
    private var classroomImportSection: some View {
        VStack(spacing: 12) {
            HStack {
                Rectangle().frame(height: 1).foregroundStyle(.tertiary)
                Text("or").font(.caption).foregroundStyle(.secondary)
                Rectangle().frame(height: 1).foregroundStyle(.tertiary)
            }

            switch classroomImportState {
            case .idle:
                Button {
                    Task { await importClassroomRoster() }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "person.3.sequence.fill")
                        Text("Import Roster from Google Classroom")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.blue.opacity(0.08))
                    .foregroundStyle(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

            case .loading:
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Connecting to Google Classroom…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)

            case .success(let count):
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Imported \(count) student\(count == 1 ? "" : "s") — they'll appear in your roster after confirming.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

            case .failure(let message):
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.orange)
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    @MainActor
    private func importClassroomRoster() async {
        classroomImportState = .loading
        do {
            guard let vc = await UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first?.windows.first?.rootViewController else {
                classroomImportState = .failure("Could not present sign-in. Try again.")
                return
            }
            let token = try await authVM.requestClassroomScopes(presenting: vc)
            let count = try await CloudFunctionService.shared.importClassroomRoster(
                googleAccessToken: token, teacherId: teacherId
            )
            classroomImportState = .success(count)
        } catch {
            classroomImportState = .failure("Could not import roster: \(error.localizedDescription)")
        }
    }
    #endif

    private func toggleGrade(_ grade: String) {
        if selectedGrades.contains(grade) {
            selectedGrades.remove(grade)
        } else {
            selectedGrades.insert(grade)
        }
    }
}
