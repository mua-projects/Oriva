//
//  AdminAnalysisView.swift
//  Oriva
//
//  Created by Shaik Imran on 10/24/26.
//

import Foundation
import SwiftUI

struct AdminAnalysisView: View {

    @Bindable var appState: AppState
    @Environment(\.dismiss) private var dismiss

    let originalText: String
      
    @State private var analysis: AdminAnalysis
    
    init(
            appState: AppState,
            originalText: String
        ) {
            self.appState = appState
            self.originalText = originalText

            _analysis = State(
                initialValue: AdminTextAnalyzer().analyze(originalText)
            )
        }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                VStack(alignment: .leading, spacing: 6) {
                    Label("Oriva understood", systemImage: "sparkles")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Review this before Oriva tracks anything.")
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 18) {

                    AnalysisField(
                        label: "TYPE",
                        value: analysis.title
                    )

                    Divider()

                    AnalysisField(
                        label: "NEEDS ATTENTION",
                        value: analysis.action
                    )

                    Divider()

                    AnalysisField(
                        label: "DUE DATE",
                        value: analysis.formattedDueDate
                    )

                    if analysis.amount == nil && analysis.validationWarnings.contains(where: { $0.contains("Different amounts due") }) {
                        Divider()
                        AnalysisField(label: "AMOUNT", value: "Needs verification")
                    }

                    if let amount = analysis.amount {
                        Divider()

                        AnalysisField(
                            label: "AMOUNT",
                            value: amount
                        )
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                if !analysis.validationWarnings.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Please verify", systemImage: "exclamationmark.triangle")
                            .font(.headline)
                        ForEach(analysis.validationWarnings, id: \.self) { warning in
                            Text("• " + warning)
                                .font(.subheadline)
                        }
                        Text("Compare these details with the original before tracking. You can use Edit Details to correct them.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("WHAT HAPPENS IF I IGNORE THIS?")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)

                    Text(analysis.consequence)
                        .font(.body)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("SUGGESTED ACTION")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)

                    Text(analysis.suggestedAction)
                }

                Button {
                    let item = AdminItem(
                        title: analysis.title,
                        action: analysis.action,
                        dueDate: analysis.dueDate,
                        amount: analysis.amount,
                        consequence: analysis.consequence,
                        suggestedAction: analysis.suggestedAction,
                        dateType: analysis.dateType
                    )

                    appState.addAdminItem(item)
                    dismiss()

                } label: {
                    Text("Confirm & Track")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)

                NavigationLink {
                    AdminEditView(
                        analysis: analysis,
                        onSave: { updatedAnalysis in
                            analysis = updatedAnalysis
                        }
                    )
                } label: {
                    Text("Edit Details")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                DisclosureGroup("Original text") {
                    Text(originalText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                        .textSelection(.enabled)
                }
            }
            .padding()
        }
        .navigationTitle("Review")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AnalysisField: View {

    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.body)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    NavigationStack {
        AdminAnalysisView(
            appState: AppState(),
            originalText: """
            Electricity bill of $185 is due on 29 October 2026.
            I need to pay it before the due date or I may incur a late fee.
            """
        )
    }
}
