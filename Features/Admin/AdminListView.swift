//
//  AdminListView.swift
//  Oriva
//
//  Created by Shaik Imran on 10/24/26.
//

import Foundation
import SwiftUI

struct AdminListView: View {

    @Bindable var appState: AppState

    var body: some View {
        NavigationStack {
            Group {
                if appState.adminItems.isEmpty {

                    ContentUnavailableView(
                        "No Admin Yet",
                        systemImage: "tray",
                        description: Text(
                            "Things you ask Oriva to track will appear here."
                        )
                    )

                } else {

                    List(appState.adminItems) { item in

                        NavigationLink {
                            AdminDetailView(
                                appState: appState,
                                item: item
                            )
                        } label: {

                            HStack(spacing: 14) {

                                Image(systemName: "doc.text.fill")
                                    .font(.title2)
                                    .frame(width: 36)

                                VStack(alignment: .leading, spacing: 5) {

                                    Text(item.title)
                                        .fontWeight(.semibold)

                                    Text(item.action)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)

                                    HStack(spacing: 5) {

                                        Text(item.formattedDueDate)

                                        if let amount = item.amount {
                                            Text("·")
                                            Text(amount)
                                        }
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }

                                Spacer()
                            }
                            .padding(.vertical, 6)
                        }
                    }
                }
            }
            .navigationTitle("Admin")
        }
    }
}


#Preview {
    AdminListView(appState: AppState())
}
