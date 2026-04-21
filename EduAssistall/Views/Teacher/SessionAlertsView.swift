import SwiftUI

/// FR-201: Educator view showing auto-flagged alerts for a specific student session.
struct SessionAlertsView: View {
    let studentEmail: String
    let flags: [SessionFlag]

    var body: some View {
        Group {
            if flags.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)
                    Text("No Active Alerts")
                        .font(.title3.bold())
                    Text("All flags for this student have been acknowledged.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(flags) { flag in
                    FlagRow(flag: flag)
                }
                #if os(iOS)
                .listStyle(.insetGrouped)
                #else
                .listStyle(.inset)
                #endif
            }
        }
        .background(Color.appGroupedBackground)
        .navigationTitle("\(studentEmail) — Alerts")
        .inlineNavigationTitle()
    }
}

// MARK: - Flag Row

private struct FlagRow: View {
    let flag: SessionFlag

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: flag.type.iconName)
                .foregroundStyle(flag.type.color)
                .font(.system(size: 20))
                .frame(width: 36, height: 36)
                .background(flag.type.color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(flag.type.displayName)
                        .font(.subheadline.bold())
                    Spacer()
                    Text(flag.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(flag.reason.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let preview = flag.messagePreview {
                    Text("\"\(preview)\"")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .italic()
                }
            }
        }
        .padding(.vertical, 4)
    }
}
