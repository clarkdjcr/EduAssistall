import SwiftUI

// Phase 3: Teacher spotlight view for students
struct StudentSpotlightView: View {
    let profile: UserProfile
    
    @State private var spotlights: [TeacherSpotlight] = []
    @State private var isLoading = true
    
    var body: some View {
        List {
            if isLoading {
                ProgressView("Loading spotlights...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if spotlights.isEmpty {
                emptyState
            } else {
                ForEach(spotlights) { spotlight in
                    SpotlightCard(spotlight: spotlight)
                }
            }
        }
        .navigationTitle("Teacher Spotlights")
        .task {
            await loadSpotlights()
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("No Spotlights Yet")
                .font(.headline)
            Text("Your teacher will highlight your great work here")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func loadSpotlights() async {
        isLoading = true
        spotlights = (try? await FirestoreService.shared.fetchTeacherSpotlights(studentId: profile.id)) ?? []
        isLoading = false
    }
}

// Phase 3: Teacher spotlight view for teachers
struct TeacherSpotlightView: View {
    let profile: UserProfile
    let students: [UserProfile]
    
    @State private var selectedStudent: UserProfile?
    @State private var reason: String = ""
    @State private var isSending = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Select Student", selection: $selectedStudent) {
                        Text("Choose a student").tag(nil as UserProfile?)
                        ForEach(students) { student in
                            Text(student.displayName).tag(student as UserProfile?)
                        }
                    }
                    
                    TextField("Reason for spotlight", text: $reason, axis: .vertical)
                        .lineLimit(3...5)
                    
                    Button {
                        createSpotlight()
                    } label: {
                        HStack {
                            if isSending {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: "star.fill")
                                Text("Create Spotlight")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedStudent != nil && !reason.isEmpty ? Color.blue : Color.gray)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(selectedStudent == nil || reason.isEmpty || isSending)
                } header: {
                    Text("Create Spotlight")
                }
            }
            .navigationTitle("Teacher Spotlight")
            .alert("Spotlight", isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func createSpotlight() {
        guard let selected = selectedStudent else { return }
        
        Task {
            isSending = true
            do {
                let spotlight = TeacherSpotlight(
                    teacherId: profile.id,
                    teacherName: profile.displayName,
                    studentId: selected.id,
                    studentName: selected.displayName,
                    reason: reason
                )
                try await FirestoreService.shared.createTeacherSpotlight(spotlight)
                
                // Award XP to student
                let xpAwarded = XPManager.awardBadgeXP(badgeRarity: .rare)
                try? await FirestoreService.shared.awardXP(studentId: selected.id, xpAmount: xpAwarded)
                
                alertMessage = "Spotlight created for \(selected.displayName)!"
                showAlert = true
                reason = ""
                selectedStudent = nil
            } catch {
                alertMessage = "Failed to create spotlight. Please try again."
                showAlert = true
            }
            isSending = false
        }
    }
}

private struct SpotlightCard: View {
    let spotlight: TeacherSpotlight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.yellow.opacity(0.15))
                        .frame(width: 50, height: 50)
                    Image(systemName: "star.fill")
                        .font(.title2)
                        .foregroundStyle(.yellow)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(spotlight.teacherName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Teacher Spotlight")
                        .font(.headline)
                }
                
                Spacer()
                
                Text(formatDate(spotlight.timestamp))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            Divider()
            
            Text(spotlight.reason)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.yellow.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
