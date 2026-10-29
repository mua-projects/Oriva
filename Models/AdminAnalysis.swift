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

    init(
        title: String,
        action: String,
        dueDate: Date?,
        amount: String?,
        consequence: String,
        suggestedAction: String,
        dateType: AdminDateType = .general
    ) {
        self.title = title
        self.action = action
        self.dueDate = dueDate
        self.amount = amount
        self.consequence = consequence
        self.suggestedAction = suggestedAction
        self.dateType = dateType
    }

    var formattedDueDate: String {
        guard let dueDate else {
            return "Not detected"
        }

        return dueDate.formatted(
            .dateTime
                .day()
                .month(.wide)
                .year()
        )
    }
}
