import SwiftUI

import SwiftUI

struct ContentView: View {

    @Bindable var appState: AppState

    var body: some View {
        TabView {

            FeedView(appState: appState)
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            AdminListView(appState: appState)
                .tabItem {
                    Label("Admin", systemImage: "checklist")
                }

            CreatePostView(appState: appState)
                .tabItem {
                    Label("Add", systemImage: "plus")
                }

            DocumentsView(appState: appState)
                .tabItem {
                    Label("Documents", systemImage: "folder")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
        }
    }
}

#Preview {
    ContentView(appState: AppState())
}
