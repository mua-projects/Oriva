//
//  SearchView.swift
//  Oriva
//
//  Created by Shaik Imran on 10/24/26.
//

import SwiftUI

struct SearchView: View {
    var body: some View {
        NavigationStack {
            Text("Discover people and posts")
                .foregroundStyle(.secondary)
                .navigationTitle("Discover")
        }
    }
}

#Preview {
    SearchView()
}
