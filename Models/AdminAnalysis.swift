//
//  AdminAnalysis.swift
//  Oriva
//
//  Created by Shaik Imran on 10/25/26.
//

import Foundation

struct AdminAnalysis {
    let title: String
    let action: String
    let dueDate: Date?
    let amount: String?
    let consequence: String
    let suggestedAction: String
    let dateType: AdminDateType
    let validationWarnings: [String]

    init(
        title: String,
        action: String,
        dueDate: Date?,
        amount: String?,
        consequence: String,
        suggestedAction: String,
        dateType: AdminDateType = .general,
        validationWarnings: [String] = []
    ) {
        self.title = title
        self.action = action
        self.dueDate = dueDate
        self.amount = amount
        self.consequence = consequence
        self.suggestedAction = suggestedAction
        self.dateType = dateType
        self.validationWarnings = validationWarnings
    }

    var formattedDueDate: String {
        guard let dueDate else {
            return "Not detected"
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: dueDate)
    }
}
