//
//  CreateProfileView.swift
//  Oriva
//
//  Created by Shaik Imran on 10/24/26.
//
import SwiftUI

struct CreateProfileView: View {

    @Bindable var appState: AppState

    @State private var username = ""
    @State private var displayName = ""
    @State private var bio = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {

                Spacer()

                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 70))
                    .foregroundStyle(.secondary)

                Text("Create Your Profile")
                    .font(.system(size: 32, weight: .bold))

                Text("Tell the Oriva community a little about yourself.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                TextField("Username", text: $username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                TextField("Display Name", text: $displayName)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                TextField("Bio", text: $bio, axis: .vertical)
                    .lineLimit(3...5)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Button {
                    appState.completeProfile()
                } label: {
                    Text("Continue")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)

                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    CreateProfileView(appState: AppState())
}
