//
//  Untitled.swift
//  Oriva
//
//  Created by Shaik Imran on 10/24/26.
//
import SwiftUI

struct SignUpView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @Bindable var appState: AppState

    var body: some View {
        VStack(spacing: 20) {

            Spacer()

            Text("Create Account")
                .font(.system(size: 34, weight: .bold))

            Text("Join Oriva and start sharing.")
                .foregroundStyle(.secondary)

            Spacer()
                .frame(height: 20)

            TextField("Email", text: $email)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            SecureField("Password", text: $password)
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            SecureField("Confirm Password", text: $confirmPassword)
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Button {
                // Real account creation comes later.
                appState.signUp()
            } label: {
                Text("Create Account")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)

            Button("Already have an account? Log In") {
                dismiss()
            }

            Spacer()
        }
        .padding()
        .navigationBarBackButtonHidden(false)
    }
}

#Preview {
    NavigationStack {
        SignUpView(appState:AppState())
    }
}
