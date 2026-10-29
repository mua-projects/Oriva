//
//  AdminItem.swift
//  Oriva
//
//  Created by Shaik Imran on 10/24/26.
//

import Foundation


enum AdminDateType: String, Codable, CaseIterable {
    case general
    case paymentDue
    case policyExpiration
    case documentExpiration
    case appointment

    var displayLabel: String {
        switch self {
        case .general: return "IMPORTANT DATE"
        case .paymentDue: return "PAYMENT DUE"
        case .policyExpiration: return "POLICY EXPIRES"
        case .documentExpiration: return "DOCUMENT EXPIRES"
        case .appointment: return "APPOINTMENT DATE"
        }
    }
}

struct AdminItem: Identifiable, Codable {
    
    let id: UUID
    
    let title: String
    
    let action: String
    
    let dueDate: Date?
    
    let dateType: AdminDateType
    
    let amount: String?
    
    let consequence: String
    
    let suggestedAction: String
    
    var reminderDate: Date?
    
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
    var dateLabel: String {
        dateType.displayLabel
    }
    
    // MARK: - Source Document
    
    /// The document that created this Admin item.
    ///
    /// This is optional so Admin items created manually,
    /// from pasted text, or before document linking was
    /// introduced continue to work normally.
    let sourceDocumentID: UUID?
    
    
    init(
        id: UUID = UUID(),
        title: String,
        action: String,
        dueDate: Date?,
        amount: String?,
        consequence: String,
        suggestedAction: String,
        reminderDate: Date? = nil,
        sourceDocumentID: UUID? = nil,
        dateType: AdminDateType = .general
    ) {
        
        self.id = id
        
        self.title = title
        
        self.action = action
        
        self.dueDate = dueDate
        
        self.dateType = dateType
        
        self.amount = amount
        
        self.consequence = consequence
        
        self.suggestedAction = suggestedAction
        
        self.reminderDate = reminderDate
        
        self.sourceDocumentID = sourceDocumentID
    }
}
    
    // MARK: - Formatting
