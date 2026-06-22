import SwiftUI

// Phase 3: Kudos giving and receiving view
struct KudosView: View {
    let profile: UserProfile
    let classmates: [UserProfile]
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedStudentId = ""
    @State private var reason: String = ""
    @State private var kudosStats: KudosStats?
    @State private var recentKudos: [Kudos] = []
    @State private var isSending = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            List {
                // Kudos stats section
                if let stats = kudosStats {
                    Section {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Kudos Given")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(stats.givenCount)")
                                    .font(.title2.bold())
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Kudos Received")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(stats.receivedCount)")
                                    .font(.title2.bold())
                            }
                        }
                        .padding(.vertical, 8)
                        
                        if stats.remainingKudosToday() > 0 {
                            HStack {
                                Image(systemName: "hand.thumbsup.fill")
                                    .foregroundStyle(.green)
                                Text("\(stats.remainingKudosToday()) kudos remaining today")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            HStack {
                                Image(systemName: "clock.fill")
                                    .foregroundStyle(.orange)
                                Text("You've used all your kudos for today")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } header: {
                        Text("Your Stats")
                    }
                }
                
                // Give kudos section
                Section {
                    Picker("Select Classmate", selection: $selectedStudentId) {
                        Text("Choose a classmate").tag("")
                        ForEach(classmates) { classmate in
                            if classmate.id != profile.id {
                                Text(classmate.displayName).tag(classmate.id)
                            }
                        }
                    }
                    
                    TextField("Why are you giving kudos?", text: $reason, axis: .vertical)
                        .lineLimit(3...5)
                    
                    Button {
                        sendKudos()
                    } label: {
                        HStack {
                            if isSending {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: "hand.thumbsup.fill")
                                Text("Send Kudos")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(!selectedStudentId.isEmpty && !reason.isEmpty ? Color.blue : Color.gray)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(selectedStudentId.isEmpty || reason.isEmpty || isSending)
                } header: {
                    Text("Give Kudos")
                }
                
                // Recent kudos received
                if !recentKudos.isEmpty {
                    Section {
                        ForEach(recentKudos) { kudo in
                            KudosRow(kudo: kudo, classmates: classmates)
                        }
                    } header: {
                        Text("Recent Kudos Received")
                    }
                }
            }
            .navigationTitle("Kudos")
            .task {
                await loadData()
            }
            .alert("Kudos", isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func loadData() async {
        async let statsTask = loadKudosStats()
        async let kudosTask = loadRecentKudos()
        
        kudosStats = await statsTask
        recentKudos = await kudosTask
    }
    
    private func loadKudosStats() async -> KudosStats? {
        return try? await FirestoreService.shared.fetchKudosStats(studentId: profile.id)
    }
    
    private func loadRecentKudos() async -> [Kudos] {
        return (try? await FirestoreService.shared.fetchRecentKudos(studentId: profile.id)) ?? []
    }
    
    private func sendKudos() {
        guard let selected = classmates.first(where: { $0.id == selectedStudentId }) else { return }
        
        Task {
            isSending = true
            do {
                let kudos = Kudos(fromStudentId: profile.id, toStudentId: selected.id, reason: reason)
                try await FirestoreService.shared.sendKudos(kudos)
                
                // Update local stats
                var updatedStats = kudosStats ?? KudosStats(studentId: profile.id)
                updatedStats.givenCount += 1
                updatedStats.lastGivenDate = Date()
                kudosStats = updatedStats
                
                // Check for mentor badge
                let totalReceived = updatedStats.receivedCount + 1
                if totalReceived == 5 {
                    try? await FirestoreService.shared.awardBadge(studentId: profile.id, type: .helpfulAnswer)
                } else if totalReceived == 20 {
                    try? await FirestoreService.shared.awardBadge(studentId: profile.id, type: .mentor)
                }
                
                // Award XP for giving kudos
                let xpAwarded = XPManager.awardHelpfulAnswer()
                try? await FirestoreService.shared.awardXP(studentId: profile.id, xpAmount: xpAwarded)
                
                alertMessage = "Kudos sent to \(selected.displayName)!"
                showAlert = true
                reason = ""
                selectedStudentId = ""
            } catch {
                alertMessage = "Failed to send kudos. Please try again."
                showAlert = true
            }
            isSending = false
        }
    }
}

private struct KudosRow: View {
    let kudo: Kudos
    let classmates: [UserProfile]
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.blue.opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(getSenderName().prefix(1).uppercased())
                        .font(.headline)
                        .foregroundStyle(.blue)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(getSenderName())
                    .font(.subheadline.bold())
                Text(kudo.reason)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Text(formatDate(kudo.timestamp))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
    
    private func getSenderName() -> String {
        classmates.first { $0.id == kudo.fromStudentId }?.displayName ?? "Classmate"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
