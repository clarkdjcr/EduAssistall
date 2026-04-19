import SwiftUI

struct ParentSetupView: View {
    @Binding var studentEmail: String
    let adultId: String
    let onComplete: () -> Void

    @State private var isLinking = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    var body: some View {
        VStack(spacing: 28) {
            VStack(spacing: 8) {
                Image(systemName: "figure.2.and.child.holdinghands")
                    .font(.system(size: 56))
                    .foregroundStyle(.blue)
                    .padding(.top, 40)

                Text("Link to Your Child")
                    .font(.title.bold())

                Text("Enter your child's email address to request a link to their account.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(spacing: 14) {
                TextField("Child's email address", text: $studentEmail)
                    .emailInput()
                    .padding()
                    .background(Color.appSecondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                if let error = errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let success = successMessage {
                    Text(success)
                        .font(.footnote)
                        .foregroundStyle(.green)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    Task { await linkToStudent() }
                } label: {
                    Group {
                        if isLinking {
                            ProgressView().tint(Color.white)
                        } else {
                            Text("Send Link Request")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(studentEmail.isEmpty ? Color.appSecondaryBackground : Color.blue)
                    .foregroundStyle(studentEmail.isEmpty ? Color.secondary : Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(studentEmail.isEmpty || isLinking)
            }
            .padding(.horizontal, 24)

            Button {
                onComplete()
            } label: {
                Text("Skip for Now")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .navigationTitle("Link Account")
        .inlineNavigationTitle()
    }

    private func linkToStudent() async {
        isLinking = true
        errorMessage = nil
        do {
            guard let student = try await FirestoreService.shared.findStudentByEmail(studentEmail) else {
                errorMessage = "No student account found with that email. Check the address and try again."
                isLinking = false
                return
            }
            let link = StudentAdultLink(
                studentId: student.id,
                adultId: adultId,
                adultRole: .parent,
                studentEmail: studentEmail
            )
            try await FirestoreService.shared.createStudentAdultLink(link)
            successMessage = "Link request sent! Your child will see it in their account."
            // Auto-advance after a brief pause
            try? await Task.sleep(for: .seconds(1.5))
            onComplete()
        } catch {
            errorMessage = "Something went wrong. Please try again."
        }
        isLinking = false
    }
}
