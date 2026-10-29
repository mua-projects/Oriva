//
//  ActivityView.swift
//  Oriva
//
//  Created by Shaik Imran on 10/24/26.
//
import SwiftUI

struct ActivityView: View {
    var body: some View {
        NavigationStack {
            Text("Your activity will appear here.")
                .foregroundStyle(.secondary)
                .navigationTitle("Activity")
        }
    }
}

#Preview {
    ActivityView()
}
