//
//  AdminDetailView.swift
//  Oriva
//
//  Created by Shaik Imran on 10/24/26.
//

import Foundation
import SwiftUI

struct AdminDetailView: View {

    @Bindable var appState: AppState
    let item: AdminItem

    @Environment(\.dismiss) private var dismiss
    @State private var showingReminderSheet = false
    @State private var reminderDate = Date()
    @State private var showingReminderConfirmation = false
    @State private var reminderErrorMessage: String?
    private var currentItem: AdminItem {

        appState.adminItems.first(
            where: { $0.id == item.id }
        ) ?? item
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(item.action)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 18) {
                    
                    DetailField(
                        label: item.dateLabel,
                        value: item.formattedDueDate
                    )
                    
                    if let amount = item.amount {
                        Divider()
                        
                        DetailField(
                            label: "AMOUNT",
                            value: amount
                        )
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("WHAT HAPPENS IF I IGNORE THIS?")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                    
                    Text(item.consequence)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("SUGGESTED ACTION")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                    
                    Text(item.suggestedAction)
                }
                if let reminderDate = currentItem.reminderDate {

                    VStack(alignment: .leading, spacing: 8) {

                        Label(
                            "Reminder set",
                            systemImage: "bell.fill"
                        )
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)

                        Text(
                            reminderDate.formatted(
                                date: .long,
                                time: .shortened
                            )
                        )
                        .fontWeight(.medium)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(
                        RoundedRectangle(cornerRadius: 16)
                    )
                }
                
                Button {
                    // Completion comes next.
                    if currentItem.reminderDate != nil {
                           NotificationManager.cancelReminder(
                               for: currentItem
                           )
                       }

                       appState.markAsHandled(currentItem)
                       dismiss()
                } label: {
                    Label(
                        "Mark as Handled",
                        systemImage: "checkmark.circle"
                    )
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .buttonStyle(.borderedProminent)
                
                Button {
                    // Reminder support comes later.
                    prepareReminderDate()
                    showingReminderSheet = true
                } label: {
                    Label(
                        currentItem.reminderDate == nil
                            ? "Remind Me"
                            : "Change Reminder",
                        systemImage: "bell"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                if currentItem.reminderDate != nil {

                    Button(role: .destructive) {

                        NotificationManager.cancelReminder(
                            for: currentItem
                        )

                        appState.cancelReminder(
                            for: currentItem
                        )

                    } label: {

                        Label(
                            "Cancel Reminder",
                            systemImage: "bell.slash"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                
            }
            .padding()
        }
        .navigationTitle("Admin")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingReminderSheet) {
            
            NavigationStack {
                
                Form {
                    
                    Section {
                        
                        DatePicker(
                            "Remind me",
                            selection: $reminderDate,
                            in: Date()...,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        
                    } header: {
                        
                        Text("Reminder")
                        
                    } footer: {
                        
                        Text(
                            "Choose when you want Oriva to remind you about \(item.title)."
                        )
                    }
                    
                    Section {
                        
                        Button {
                            
                            Task {
                                
                                do {
                                    
                                    try await NotificationManager.scheduleReminder(
                                        for: item,
                                        at: reminderDate
                                    )

                                    appState.setReminder(
                                        for: item,
                                        at: reminderDate
                                    )

                                    showingReminderSheet = false
                                    showingReminderConfirmation = true
                                    
                                } catch {
                                    
                                    reminderErrorMessage = error.localizedDescription
                                }
                            }
                            
                        } label: {
                            
                            Text("Set Reminder")
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .navigationTitle("Remind Me")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    
                    ToolbarItem(placement: .cancellationAction) {
                        
                        Button("Cancel") {
                            showingReminderSheet = false
                        }
                    }
                }
            }
        }
        .alert(
            "Reminder Set",
            isPresented: $showingReminderConfirmation
        ) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(
                "Oriva will remind you on \(reminderDate.formatted(date: .long, time: .shortened))."
            )
        }
        .alert(
            "Unable to Set Reminder",
            isPresented: Binding(
                get: {
                    reminderErrorMessage != nil
                },
                set: { newValue in
                    if !newValue {
                        reminderErrorMessage = nil
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                reminderErrorMessage = nil
            }
        } message: {
            Text(reminderErrorMessage ?? "Something went wrong.")
        }
    }
    private func prepareReminderDate() {
        let now = Date()
        let calendar = Calendar.current

        if let existingReminder = currentItem.reminderDate,
           existingReminder > now {
            reminderDate = existingReminder
            return
        }

        if let dueDate = currentItem.dueDate {
            // Extracted document dates are stored as UTC calendar dates.
            // Preserve their year/month/day when choosing 9 AM local time.
            var utcCalendar = Calendar(identifier: .gregorian)
            utcCalendar.timeZone = TimeZone(secondsFromGMT: 0)!
            let components = utcCalendar.dateComponents(
                [.year, .month, .day],
                from: dueDate
            )

            if let year = components.year,
               let month = components.month,
               let day = components.day,
               let localNineAM = calendar.date(
                   from: DateComponents(
                       year: year,
                       month: month,
                       day: day,
                       hour: 9,
                       minute: 0
                   )
               ),
               localNineAM > now {
                reminderDate = localNineAM
                return
            }
        }

        // A past date must never preselect an invalid reminder.
        reminderDate = calendar.date(
            byAdding: .day,
            value: 1,
            to: now
        ) ?? now.addingTimeInterval(24 * 60 * 60)
    }
}


struct DetailField: View {

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

    let item = AdminItem(
        title: "Home insurance",
        action: "Review insurance renewal",
        dueDate: Calendar.current.date(
            from: DateComponents(
                year: 2026,
                month: 11,
                day: 28
            )
        ) ?? Date(),
        amount: "$1,486",
        consequence: "The policy may renew automatically if no action is taken.",
        suggestedAction: "Review the renewal before 21 November."
    )

    NavigationStack {
        AdminDetailView(
            appState: AppState(),
            item: item
        )
    }
}

