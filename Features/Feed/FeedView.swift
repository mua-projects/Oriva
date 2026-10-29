//
//  FeedView.swift
//  Oriva
//
//  Created by Shaik Imran on 10/24/26.
//

import SwiftUI

struct FeedView: View {
    @Bindable var appState: AppState
    
    private var needsAttentionItems: [AdminItem] {
        let sevenDaysFromNow = Calendar.current.date(
            byAdding: .day,
            value: 7,
            to: Date()
        ) ?? Date()

        return appState.adminItems.filter { item in
            guard let dueDate = item.dueDate else {
                // No date detected means the item needs user attention.
                return true
            }

            return dueDate <= sevenDaysFromNow
        }
    }

    private var comingUpItems: [AdminItem] {
        let sevenDaysFromNow = Calendar.current.date(
            byAdding: .day,
            value: 7,
            to: Date()
        ) ?? Date()

        return appState.adminItems
            .filter { item in
                guard let dueDate = item.dueDate else {
                    return false
                }

                return dueDate > sevenDaysFromNow
            }
            .sorted { firstItem, secondItem in
                guard
                    let firstDate = firstItem.dueDate,
                    let secondDate = secondItem.dueDate
                else {
                    return false
                }

                return firstDate < secondDate
            }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {

                    header

                    needsYouSection

                    comingUpSection

                    handledSection
                }
                .padding()
            }
            .navigationTitle("Oriva")
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Your Personal Admin")
                .font(.title2)
                .fontWeight(.bold)

            Text("Here's what needs your attention.")
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Needs You

    private var needsYouSection: some View {
        VStack(alignment: .leading, spacing: 14) {

            HStack {
                Text("NEEDS YOU")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(needsAttentionItems.count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
            }

            if needsAttentionItems.isEmpty {

                VStack(spacing: 10) {
                    Image(systemName: "tray")
                        .font(.title2)
                        .foregroundStyle(.secondary)

                    Text("Nothing needs your attention")
                        .fontWeight(.semibold)

                    Text("Add something for Oriva to track.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)

            } else {

                ForEach(needsAttentionItems) { item in
                    NavigationLink {
                        AdminDetailView(
                            appState: appState,
                            item: item
                        )
                    } label: {
                        AdminCard(
                            icon: "doc.text.fill",
                            title: item.title,
                            detail: adminDetail(for: item),
                            status: item.action
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    private func adminDetail(for item: AdminItem) -> String {
        if let amount = item.amount {
            return "\(item.formattedDueDate) · \(amount)"
        }

        return item.formattedDueDate
    }

    // MARK: - Coming Up

    private var comingUpSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("COMING UP")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)

            if comingUpItems.isEmpty {
                Text("Nothing coming up.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(comingUpItems.enumerated()), id: \.element.id) { index, item in
                    NavigationLink {
                        AdminDetailView(
                            appState: appState,
                            item: item
                        )
                    } label: {
                        UpcomingRow(
                            icon: "calendar",
                            title: item.title,
                            time: relativeDueText(for: item)
                        )
                    }
                    .buttonStyle(.plain)

                    if index < comingUpItems.count - 1 {
                        Divider()
                    }
                }
            }
        }
    }

    private func relativeDueText(for item: AdminItem) -> String {
        guard let dueDate = item.dueDate else {
            return "No date"
        }

        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfDueDate = calendar.startOfDay(for: dueDate)

        let days = calendar.dateComponents(
            [.day],
            from: startOfToday,
            to: startOfDueDate
        ).day ?? 0

        switch days {
        case ...0:
            return "Today"

        case 1:
            return "Tomorrow"

        case 2...30:
            return "\(days) days"

        default:
            let months = calendar.dateComponents(
                [.month],
                from: startOfToday,
                to: startOfDueDate
            ).month ?? 0

            return months == 1 ? "1 month" : "\(months) months"
        }
    }
    // MARK: - Handled

    private var handledSection: some View {
        VStack(alignment: .leading, spacing: 14) {

            Text("HANDLED")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)

            if appState.handledItems.isEmpty {

                Text("Nothing handled yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

            } else {

                ForEach(appState.handledItems) { item in
                    HStack(spacing: 12) {

                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)

                        VStack(alignment: .leading, spacing: 3) {

                            Text(item.title)
                                .fontWeight(.medium)

                            Text(item.action)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                }
            }
        }
    }
}


// MARK: - Admin Card

struct AdminCard: View {

    let icon: String
    let title: String
    let detail: String
    let status: String

    var body: some View {
        HStack(spacing: 14) {

            Image(systemName: icon)
                .font(.title2)
                .frame(width: 38)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .fontWeight(.semibold)

                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(status)
                    .font(.caption)
                    .fontWeight(.semibold)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
}


// MARK: - Upcoming Row

struct UpcomingRow: View {

    let icon: String
    let title: String
    let time: String

    var body: some View {
        HStack(spacing: 14) {

            Image(systemName: icon)
                .frame(width: 30)

            Text(title)

            Spacer()

            Text(time)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
}


#Preview {
    FeedView(appState: AppState())
}
