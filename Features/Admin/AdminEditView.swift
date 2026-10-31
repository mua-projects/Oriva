//
//  AdminEditView.swift
//  Oriva
//
//  Created by Shaik Imran on 10/25/26.
//
import Foundation
import SwiftUI

struct AdminEditView: View {

    @Environment(\.dismiss) private var dismiss

    let analysis: AdminAnalysis
    let onSave: (AdminAnalysis) -> Void

    @State private var title: String
    @State private var action: String
    @State private var dueDate: Date
    @State private var hasDueDate: Bool
    @State private var amount: String

    init(
        analysis: AdminAnalysis,
        onSave: @escaping (AdminAnalysis) -> Void
    ) {
        self.analysis = analysis
        self.onSave = onSave

        _title = State(initialValue: analysis.title)
        _action = State(initialValue: analysis.action)

        if let detectedDate = analysis.dueDate {
            _dueDate = State(initialValue: detectedDate)
            _hasDueDate = State(initialValue: true)
        } else {
            _dueDate = State(initialValue: Date())
            _hasDueDate = State(initialValue: false)
        }

        _amount = State(initialValue: analysis.amount ?? "")
    }

    var body: some View {
        Form {

            Section("Details") {

                TextField("Type", text: $title)

                TextField("Needs attention", text: $action)

                TextField("Amount", text: $amount)
                    .keyboardType(.decimalPad)
            }

            Section("Due Date") {

                Toggle("Has due date", isOn: $hasDueDate)

                if hasDueDate {
                    DatePicker(
                        "Due date",
                        selection: $dueDate,
                        displayedComponents: .date
                    )
                }
            }

            Section {
                Button {
                    saveChanges()
                } label: {
                    Text("Save Changes")
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("Edit Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func saveChanges() {

        let cleanedTitle = title.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let cleanedAction = action.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let cleanedAmount = amount.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let updatedDueDate: Date? = hasDueDate ? dueDate : nil
        
        let updatedSuggestedAction: String

        if let updatedDueDate {
            let formattedDate = updatedDueDate.formatted(
                .dateTime
                    .day()
                    .month(.wide)
                    .year()
            )

            updatedSuggestedAction = "\(cleanedAction) before \(formattedDate)."
        } else {
            updatedSuggestedAction = "Review this item and add its due date."
        }
        
        let updatedAnalysis = AdminAnalysis(
            title: cleanedTitle,
            action: cleanedAction,
            dueDate: updatedDueDate,
            amount: cleanedAmount.isEmpty ? nil : cleanedAmount,
            consequence: analysis.consequence,
            suggestedAction: updatedSuggestedAction,
            dateType: analysis.dateType,
            validationWarnings: analysis.validationWarnings.filter { warning in
                let amountWarning = warning.contains("amount") || warning.contains("Amount") || warning.contains("balance owed")
                let dateWarning = warning.contains("date") || warning.contains("Date") || warning.contains("deadline")
                if amountWarning && !cleanedAmount.isEmpty { return false }
                if dateWarning && hasDueDate { return false }
                return true
            }
        )

        onSave(updatedAnalysis)

        dismiss()
    }
}

#Preview {
    NavigationStack {
        AdminEditView(
            analysis: AdminAnalysis(
                title: "Electricity bill",
                action: "Pay electricity bill",
                dueDate: nil,
                amount: "$200",
                consequence: "You may incur a late fee if the bill is not paid on time.",
                suggestedAction: "Review the electricity bill and add its due date."
            ),
            onSave: { _ in }
        )
    }
}
