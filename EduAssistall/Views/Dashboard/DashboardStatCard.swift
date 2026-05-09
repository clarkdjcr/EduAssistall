import SwiftUI

/// Shared stat card used by ParentDashboardView and TeacherDashboardView.
struct DashboardStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    var highlight = false

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.title3).foregroundStyle(color)
            Text(value).font(.title2.bold()).foregroundStyle(highlight ? color : .primary)
            Text(label).font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(highlight ? color.opacity(0.08) : Color.appSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(highlight ? color.opacity(0.3) : Color.clear, lineWidth: 1.5))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value)")
    }
}
