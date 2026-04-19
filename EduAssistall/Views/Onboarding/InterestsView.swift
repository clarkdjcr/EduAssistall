import SwiftUI

private let availableInterests = [
    "Math", "Science", "Reading", "Writing", "History",
    "Art", "Music", "Sports", "Technology", "Coding",
    "Biology", "Chemistry", "Physics", "Geography",
    "Languages", "Drama", "Film", "Photography",
    "Engineering", "Medicine", "Law", "Business",
    "Environment", "Space", "Animals", "Psychology"
]

struct InterestsView: View {
    @Binding var profile: LearningProfile
    let onComplete: () -> Void

    @State private var selected: Set<String> = []

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("What are you into?")
                    .font(.title.bold())
                Text("Pick your top interests — we'll match content to what you love.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .padding(.top, 24)
            .padding(.bottom, 20)

            ScrollView {
                FlowLayout(spacing: 10) {
                    ForEach(availableInterests, id: \.self) { interest in
                        InterestChip(
                            label: interest,
                            isSelected: selected.contains(interest)
                        ) {
                            toggleInterest(interest)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }

            Spacer(minLength: 16)

            Button {
                profile.interests = Array(selected)
                onComplete()
            } label: {
                Text(selected.isEmpty ? "Skip for Now" : "Continue (\(selected.count) selected)")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selected.isEmpty ? Color.appSecondaryBackground : Color.blue)
                    .foregroundStyle(selected.isEmpty ? Color.secondary : Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .navigationTitle("Your Interests")
        .inlineNavigationTitle()
    }

    private func toggleInterest(_ interest: String) {
        if selected.contains(interest) {
            selected.remove(interest)
        } else {
            selected.insert(interest)
        }
    }
}

private struct InterestChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.appSecondaryBackground)
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
    }
}

// Simple flow layout for chips
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let height = rows.map { $0.map { $0.size.height }.max() ?? 0 }
            .reduce(0) { $0 + $1 + spacing } - spacing
        return CGSize(width: proposal.width ?? 0, height: max(height, 0))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            let rowHeight = row.map { $0.size.height }.max() ?? 0
            for item in row {
                item.view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(item.size))
                x += item.size.width + spacing
            }
            y += rowHeight + spacing
        }
    }

    private struct Item {
        let view: LayoutSubview
        let size: CGSize
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[Item]] {
        let maxWidth = proposal.width ?? 0
        var rows: [[Item]] = [[]]
        var rowWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
            if rowWidth + size.width > maxWidth, !rows[rows.count - 1].isEmpty {
                rows.append([])
                rowWidth = 0
            }
            rows[rows.count - 1].append(Item(view: subview, size: size))
            rowWidth += size.width + spacing
        }
        return rows
    }
}
