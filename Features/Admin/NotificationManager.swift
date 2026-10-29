//
//  NotificationManager.swift
//  Oriva
//
//  Created by Shaik Imran on 10/25/26.
//
import Foundation
import UserNotifications

struct NotificationManager {

    static func scheduleReminder(
        for item: AdminItem,
        at date: Date
    ) async throws {

        guard date > Date() else {
            throw NotificationError.dateMustBeInFuture
        }

        let center = UNUserNotificationCenter.current()

        let granted = try await center.requestAuthorization(
            options: [.alert, .sound, .badge]
        )

        guard granted else {
            throw NotificationError.permissionDenied
        }

        let content = UNMutableNotificationContent()

        content.title = item.title
        switch item.dateType {
        case .paymentDue:
            content.body = "Payment reminder: \(item.action)"
        case .policyExpiration:
            content.body = "Policy expiration reminder: \(item.action)"
        case .documentExpiration:
            content.body = "Document expiration reminder: \(item.action)"
        case .appointment:
            content.body = "Appointment reminder: \(item.action)"
        case .general:
            content.body = item.action
        }
        content.sound = .default

        let dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "admin-\(item.id.uuidString)",
            content: content,
            trigger: trigger
        )

        try await center.add(request)
    }
    static func cancelReminder(for item: AdminItem) {

        let identifier = "admin-\(item.id.uuidString)"

        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(
                withIdentifiers: [identifier]
            )
    }
}

enum NotificationError: LocalizedError {

    case permissionDenied
    case dateMustBeInFuture

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Notifications are turned off for Oriva."
        case .dateMustBeInFuture:
            return "Choose a reminder date and time in the future."
        }
    }
}
