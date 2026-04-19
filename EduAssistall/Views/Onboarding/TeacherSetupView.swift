import SwiftUI

private let gradeRanges = ["K–2", "3–5", "6–8", "9–12", "College"]

struct TeacherSetupView: View {
    @Binding var school: String
    @Binding var grades: [String]
    let onComplete: () -> Void

    @State private var selectedGrades: Set<String> = []

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

    private func toggleGrade(_ grade: String) {
        if selectedGrades.contains(grade) {
            selectedGrades.remove(grade)
        } else {
            selectedGrades.insert(grade)
        }
    }
}
