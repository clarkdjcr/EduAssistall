import SwiftUI

struct PendingParentalConsentView: View {
    let profile: UserProfile
    @Environment(AuthViewModel.self) private var authVM

    @State private var isChecking = false
    @State private var statusMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 32) {
                    Spacer().frame(height: 24)

                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.12))
                            .frame(width: 120, height: 120)
                        Image(systemName: "envelope.badge.clock")
                            .font(.system(size: 52))
                            .foregroundStyle(.orange)
                    }

                    VStack(spacing: 12) {
                        Text("Waiting for Parent Approval")
                            .font(.title2.bold())
                            .multilineTextAlignment(.center)

                        Text("Because you're under 13, a parent or guardian must approve your account before you can use EduAssist.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Label("An approval email was sent to:", systemImage: "envelope")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        Text(profile.parentEmail ?? "your parent's email")
                            .font(.subheadline.bold())
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.appSecondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        Text("Ask your parent to open the email and click \"Approve Account\". The link expires in 7 days.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 24)

                    if let msg = statusMessage {
                        Text(msg)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                }
                .padding(.horizontal, 8)
            }

            VStack(spacing: 12) {
                Divider()

                Button {
                    Task { await checkApproval() }
                } label: {
                    Group {
                        if isChecking {
                            ProgressView().tint(.white)
                        } else {
                            Text("Check for Approval")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isChecking)

                Button {
                    authVM.signOut()
                } label: {
                    Text("Sign Out")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer().frame(height: 16)
            }
            .padding(.horizontal, 24)
        }
        .background(Color.appBackground)
    }

    private func checkApproval() async {
        isChecking = true
        statusMessage = nil
        await authVM.reloadProfile()
        // If still pending after reload, the parent hasn't approved yet.
        if case .pendingParentalConsent = authVM.authState {
            statusMessage = "Not approved yet. Ask your parent to check their email."
        }
        isChecking = false
    }
}
