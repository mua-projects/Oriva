//
//  LoginView.swift
//  Oriva
//
//  Created by Shaik Imran on 10/24/26.
//

import Foundation
import SwiftUI

struct LoginView: View {

    @State private var email = ""
    @State private var password = ""
    @Bindable var appState: AppState

    var body: some View {
        NavigationStack {

            VStack(spacing: 20) {

                Spacer()

                Text("Oriva")
                    .font(.system(size: 42, weight: .bold))

                Text("Share what moves you.")
                    .foregroundStyle(.secondary)

                Spacer()
                    .frame(height: 30)

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

                Button {
                    // Login will be connected later.
                    appState.login()
                } label: {
                    Text("Log In")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)

                NavigationLink {
                    SignUpView(appState: appState)
                } label: {
                    Text("Don't have an account? Sign Up")
                }

                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    LoginView(appState: AppState())
}
