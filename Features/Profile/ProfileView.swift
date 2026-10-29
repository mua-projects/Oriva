//
//  ProfileView.swift
//  Oriva
//
//  Created by Shaik Imran on 10/24/26.
//
import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            Text("Your Profile")
                .foregroundStyle(.secondary)
                .navigationTitle("Profile")
        }
    }
}

#Preview {
    ProfileView()
}
