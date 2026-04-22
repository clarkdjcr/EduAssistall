import SwiftUI

struct SchoolAdminSetupView: View {
    let profile: UserProfile

    @State private var schoolName = ""
    @State private var cityState = ""
    @State private var emailDomain = ""
    @State private var isSaving = false
    @State private var savedBanner = false

    // Derived district ID: lowercase slug from school name + city
    private var districtId: String {
        let raw = "\(schoolName) \(cityState)"
            .lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
        // Strip characters that aren't alphanumeric or hyphens
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-"))
        return raw.unicodeScalars.filter { allowed.contains($0) }.map { String($0) }.joined()
    }

    private var anthropicCommand: String {
        "firebase functions:secrets:set ANTHROPIC_API_KEY --project \(districtId.isEmpty ? "<project-id>" : districtId)"
    }

    private var sendgridCommand: String {
        "firebase functions:secrets:set SENDGRID_API_KEY --project \(districtId.isEmpty ? "<project-id>" : districtId)"
    }

    var body: some View {
        List {
            schoolInfoSection
            districtIdSection
            instructionsSection
            saveSection
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.inset)
        #endif
        .navigationTitle("Admin Setup")
        .inlineNavigationTitle()
        .task { await loadExistingConfig() }
        .overlay(alignment: .bottom) {
            if savedBanner {
                Text("Configuration saved")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.green)
                    .clipShape(Capsule())
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: savedBanner)
    }

    // MARK: - Sections

    private var schoolInfoSection: some View {
        Section {
            LabeledField(label: "School Name", placeholder: "e.g. Lincoln Elementary", text: $schoolName)
            LabeledField(label: "City, State", placeholder: "e.g. Chicago, IL", text: $cityState)
            LabeledField(label: "School Email Domain", placeholder: "e.g. lincoln.edu", text: $emailDomain)
                .keyboardType(.URL)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        } header: {
            Text("School Information")
        } footer: {
            Text("These values personalize the setup instructions below.")
        }
    }

    private var districtIdSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Your District ID")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(districtId.isEmpty ? "Fill in school name and city above" : districtId)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(districtId.isEmpty ? .tertiary : .primary)
                }
                Spacer()
                if !districtId.isEmpty {
                    CopyButton(value: districtId)
                }
            }
        } header: {
            Text("District ID")
        } footer: {
            Text("This ID groups all users from your school. Share it with teachers and parents during signup.")
        }
    }

    private var instructionsSection: some View {
        Section {
            SetupStep(
                number: 1,
                title: "Anthropic API Key",
                description: "Enables the AI companion for all students at \(schoolName.isEmpty ? "your school" : schoolName). Run this command in Terminal on a machine with the Firebase CLI installed:",
                command: anthropicCommand,
                note: "You will be prompted to paste your Anthropic API key. Get one at console.anthropic.com."
            )

            SetupStep(
                number: 2,
                title: "Firebase Authentication — Authorized Domain",
                description: "Allows users signing in with \(emailDomain.isEmpty ? "your school email domain" : emailDomain) to authenticate. In the Firebase Console:",
                steps: [
                    "Open console.firebase.google.com",
                    "Select your project",
                    "Go to Authentication → Settings → Authorized Domains",
                    "Click Add domain and enter:"
                ],
                command: emailDomain.isEmpty ? "<your-school-domain>" : emailDomain,
                note: "Skip this step if you are using Google Sign-In only."
            )

            SetupStep(
                number: 3,
                title: "Email Alerts (SendGrid)",
                description: "Enables counselor distress alerts and daily teacher digests for \(schoolName.isEmpty ? "your school" : schoolName). Run this command in Terminal:",
                command: sendgridCommand,
                note: "You will be prompted to paste your SendGrid API key. Sign up at sendgrid.com. Set the sender address to a monitored school email."
            )

            SetupStep(
                number: 4,
                title: "Google Classroom (Optional)",
                description: "Lets teachers import their class roster automatically. In the Google Cloud Console:",
                steps: [
                    "Open console.cloud.google.com",
                    "Select the project linked to your Firebase app",
                    "Go to APIs & Services → Enable APIs",
                    "Search for and enable: Google Classroom API",
                    "Go to OAuth consent screen → Add scope: classroom.courses.readonly and classroom.rosters.readonly"
                ],
                command: nil,
                note: "Teachers can then tap \"Import from Google Classroom\" during their setup."
            )
        } header: {
            Text("Setup Instructions")
        }
    }

    private var saveSection: some View {
        Section {
            Button {
                Task { await saveConfig() }
            } label: {
                HStack {
                    Spacer()
                    if isSaving {
                        ProgressView()
                    } else {
                        Text("Save District Configuration")
                            .fontWeight(.semibold)
                    }
                    Spacer()
                }
            }
            .disabled(districtId.isEmpty || isSaving)
        } footer: {
            Text("Saves your school name, location, and domain to Firestore so new users can be grouped under \(districtId.isEmpty ? "your district" : districtId).")
        }
    }

    // MARK: - Data

    private func loadExistingConfig() async {
        guard let distId = profile.districtId,
              let config = try? await FirestoreService.shared.fetchDistrictConfig(districtId: distId)
        else { return }
        schoolName = config.districtName
    }

    private func saveConfig() async {
        guard !districtId.isEmpty else { return }
        isSaving = true
        let config = DistrictConfig(id: districtId, districtName: schoolName)
        try? await FirestoreService.shared.saveDistrictConfig(config)
        // Stamp the district ID onto the teacher's own profile
        try? await FirestoreService.shared.updateDistrictId(uid: profile.id, districtId: districtId)
        isSaving = false
        savedBanner = true
        Task {
            try? await Task.sleep(for: .seconds(3))
            savedBanner = false
        }
    }
}

// MARK: - Supporting Views

private struct LabeledField: View {
    let label: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField(placeholder, text: $text)
        }
        .padding(.vertical, 2)
    }
}

private struct SetupStep: View {
    let number: Int
    let title: String
    let description: String
    var steps: [String]? = nil
    let command: String?
    let note: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Text("\(number)")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .frame(width: 22, height: 22)
                    .background(Color.blue)
                    .clipShape(Circle())

                Text(title)
                    .font(.subheadline.bold())
            }

            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let steps {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { i, step in
                        HStack(alignment: .top, spacing: 6) {
                            Text("\(i + 1).")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 18, alignment: .leading)
                            Text(step)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.leading, 4)
            }

            if let command {
                HStack(spacing: 8) {
                    Text(command)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.primary)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    CopyButton(value: command)
                }
            }

            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.blue)
                Text(note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}

private struct CopyButton: View {
    let value: String
    @State private var copied = false

    var body: some View {
        Button {
            #if os(iOS)
            UIPasteboard.general.string = value
            #endif
            copied = true
            Task {
                try? await Task.sleep(for: .seconds(2))
                copied = false
            }
        } label: {
            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                .font(.subheadline)
                .foregroundStyle(copied ? .green : .blue)
                .animation(.easeInOut(duration: 0.15), value: copied)
        }
        .buttonStyle(.plain)
    }
}
