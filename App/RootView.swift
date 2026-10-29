//
//  RootView.swift
//  Oriva
//
//  Created by Shaik Imran on 10/24/26.
//

import Foundation
import SwiftUI

struct RootView: View {

    @State private var appState = AppState()

    var body: some View {
        switch appState.authenticationState {

        case .loggedOut:
            LoginView(appState: appState)

        case .needsProfile:
            CreateProfileView(appState: appState)

        case .loggedIn:
            ContentView(appState: appState)
        }
    }
}

#Preview {
    RootView()
}
