import SwiftUI

// MARK: - Luminaries List (sheet from Career Explorer)

struct LuminariesListView: View {
    let interests: [String]
    @Environment(\.dismiss) private var dismiss

    private var luminaries: [Luminary] {
        interests.isEmpty
            ? CareerDataProvider.luminaries
            : CareerDataProvider.luminaries(matchingInterests: interests)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(luminaries) { luminary in
                        NavigationLink {
                            LuminaryDetailView(luminary: luminary)
                        } label: {
                            LuminaryRow(luminary: luminary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
            }
            .background(Color.appGroupedBackground)
            .navigationTitle("Luminaries")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Luminary Detail

struct LuminaryDetailView: View {
    let luminary: Luminary

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Hero
                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 90, height: 90)
                        Image(systemName: luminary.icon)
                            .font(.system(size: 38))
                            .foregroundStyle(.blue)
                    }
                    Text(luminary.name)
                        .font(.title2.bold())
                    Text(luminary.field)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)

                // Quote
                VStack(alignment: .leading, spacing: 8) {
                    Label("Famous Quote", systemImage: "quote.bubble.fill")
                        .font(.caption.bold())
                        .foregroundStyle(.blue)
                    Text("\u{201C}\(luminary.quote)\u{201D}")
                        .font(.body.italic())
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .background(Color.blue.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 20)

                // Bio
                VStack(alignment: .leading, spacing: 8) {
                    Text("Biography")
                        .font(.headline)
                    Text(luminary.bio)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 20)

                // Related interests
                if !luminary.relatedInterests.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Related Interests")
                            .font(.headline)
                            .padding(.horizontal, 20)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(luminary.relatedInterests, id: \.self) { interest in
                                    Text(interest)
                                        .font(.subheadline)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 7)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundStyle(.blue)
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }

                Spacer(minLength: 32)
            }
        }
        .background(Color.appGroupedBackground)
        .navigationTitle(luminary.name)
        .inlineNavigationTitle()
    }
}
