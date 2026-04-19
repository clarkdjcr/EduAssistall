import SwiftUI

private let gradeOptions = [
    "K", "1", "2", "3", "4", "5",
    "6", "7", "8", "9", "10", "11", "12"
]

struct GradeSelectionView: View {
    @Binding var profile: LearningProfile
    let onComplete: () -> Void

    @State private var selectedGrade: String = ""

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Image(systemName: "ruler.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.blue)
                    .padding(.top, 32)

                Text("What grade are you in?")
                    .font(.title.bold())

                Text("This helps us match content to your level.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.bottom, 32)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                ForEach(gradeOptions, id: \.self) { grade in
                    Button {
                        selectedGrade = grade
                    } label: {
                        let isSelected = selectedGrade == grade
                        Text(grade == "K" ? "K" : "Grade \(grade)")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(isSelected ? Color.blue : Color.appSecondaryBackground)
                            .foregroundStyle(isSelected ? Color.white : Color.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            Button {
                profile.grade = selectedGrade
                onComplete()
            } label: {
                Text(selectedGrade.isEmpty ? "Skip" : "Continue")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedGrade.isEmpty ? Color.appSecondaryBackground : Color.blue)
                    .foregroundStyle(selectedGrade.isEmpty ? Color.secondary : Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .navigationTitle("Your Grade")
        .inlineNavigationTitle()
    }
}
