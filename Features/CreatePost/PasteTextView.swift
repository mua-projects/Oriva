//
//  PasteTextView.swift
//  Oriva
//
//  Created by Shaik Imran on 10/24/26.
//

import Foundation
import SwiftUI

struct PasteTextView: View {
    @Bindable var appState: AppState
    @State private var adminText = ""
    @State private var showAnalysis = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            VStack(alignment: .leading, spacing: 6) {
                Text("Paste Text")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Paste an email, message, notice or anything else you want Oriva to understand.")
                    .foregroundStyle(.secondary)
            }

            TextEditor(text: $adminText)
                .padding(12)
                .frame(minHeight: 260)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(alignment: .topLeading) {
                    if adminText.isEmpty {
                        Text("Paste or type something here…")
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 17)
                            .padding(.vertical, 20)
                            .allowsHitTesting(false)
                    }
                }

            Button {
                showAnalysis = true
            } label: {
                HStack {
                    Image(systemName: "sparkles")

                    Text("Analyze")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            .buttonStyle(.borderedProminent)
            .disabled(adminText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            HStack(spacing: 8) {
                Image(systemName: "lock.fill")

                Text("Oriva will show you what it understood before anything is tracked.")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
        .navigationTitle("Add Admin")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showAnalysis) {
            AdminAnalysisView(
                appState: appState,
                originalText: adminText
            )
        }
    }
}


#Preview {
    NavigationStack {
        PasteTextView(appState: AppState())
    }
}
