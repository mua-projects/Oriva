//
//  AdminTextAnalyzer.swift
//  Oriva
//
//  Created by Shaik Imran on 10/25/26.
//

import Foundation

struct AdminTextAnalyzer {
    func analyze(_ originalText: String) -> AdminAnalysis {
        let text = originalText.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = text.lowercased()
        let generalDate = firstDate(in: text)
        let generalAmount = firstMoney(in: text)

        if lower.contains("renters insurance") || lower.contains("renter's insurance") || lower.contains("renters policy") || lower.contains("renters forms") || lower.contains("tenant insurance") {
            return insuranceAnalysis(text, title: "Renters Insurance", action: "Review renters insurance", certificate: false)
        }
        if lower.contains("certificate of liability insurance") || (lower.contains("acord 25") && lower.contains("certificate holder")) {
            return insuranceAnalysis(text, title: "Certificate of Liability Insurance", action: "Review insurance certificate", certificate: true)
        }
        if lower.contains("electricity") || lower.contains("power bill") {
            let date = labeledDate(in: text, labels: ["payment due date", "due date", "pay by", "due"]) ?? generalDate
            return AdminAnalysis(title: "Electricity bill", action: "Pay electricity bill", dueDate: date, amount: generalAmount, consequence: lower.contains("late fee") ? "You may incur a late fee if the bill is not paid on time." : "Check the bill for payment requirements and any consequences of late payment.", suggestedAction: date.map { "Pay the electricity bill before \(format($0))." } ?? "Review the electricity bill and confirm its due date.", dateType: .paymentDue)
        }
        if lower.contains("dentist") || lower.contains("appointment") {
            return AdminAnalysis(title: "Appointment", action: "Attend appointment", dueDate: generalDate, amount: generalAmount, consequence: "You may miss the appointment if no action is taken.", suggestedAction: generalDate.map { "Prepare for the appointment on \(format($0))." } ?? "Review the appointment and confirm its date.", dateType: .appointment)
        }
        if lower.contains("passport") {
            let date = labeledDate(in: text, labels: ["date of expiry", "expiration date", "expiry date", "expires"])
            return AdminAnalysis(title: "Passport expiry", action: "Review passport expiry", dueDate: date, amount: nil, consequence: "An expired passport may affect travel.", suggestedAction: date.map { "Review passport renewal requirements before \(format($0))." } ?? "Confirm the passport expiry date.", dateType: .documentExpiration)
        }
        if lower.contains("insurance") || lower.contains("policy period") {
            return insuranceAnalysis(text, title: "Insurance", action: "Review insurance policy", certificate: false)
        }
        return AdminAnalysis(title: "Admin item", action: "Review information", dueDate: generalDate, amount: generalAmount, consequence: "This information may require your attention.", suggestedAction: generalDate.map { "Review this item before \(format($0))." } ?? "Review this item and confirm whether action is required.")
    }

    private func insuranceAnalysis(_ text: String, title: String, action: String, certificate: Bool) -> AdminAnalysis {
        let expiration = labeledDate(in: text, labels: ["policy expiration date", "policy expiration", "expiration date", "expiry date", "policy expiry", "expires", "expiration", "expiry", "policy exp"])
        let effective = labeledDate(in: text, labels: ["policy effective date", "effective date", "policy effective", "effective"])
        let premium = labeledMoney(in: text, labels: ["annual premium", "total premium", "policy premium", "premium due", "premium"])
        let deductible = labeledMoney(in: text, labels: ["deductible"])
        let coverage = labeledMoney(in: text, labels: ["personal property coverage", "personal property", "liability coverage", "personal liability", "coverage limit", "limit of liability", "coverage amount"])
        let date = expiration // Never substitute an issue or effective date for expiry.
        let amount = premium.map { "\($0) premium" } ?? coverage.map { "\($0) coverage" }
        var details: [String] = []
        if let expiration { details.append("Policy expiration: \(format(expiration)).") }
        if let effective { details.append("Policy effective date: \(format(effective)).") }
        if let premium { details.append("Detected premium: \(premium).") }
        if let deductible { details.append("Detected deductible: \(deductible).") }
        if let coverage { details.append("Detected coverage amount: \(coverage); this is not a bill.") }
        if details.isEmpty { details.append("Confirm the coverage, premium, and policy dates in the original document.") }
        let prefix = certificate ? "This certificate provides evidence of insurance coverage." : "This appears to be an insurance policy document."
        let suggestion = expiration.map { "Review coverage and renewal options before \(format($0)). Confirm any separate payment due date." } ?? "Review coverage, policy expiration, and any separate payment due date."
        return AdminAnalysis(title: title, action: action, dueDate: date, amount: amount, consequence: prefix + " " + details.joined(separator: " "), suggestedAction: suggestion, dateType: .policyExpiration)
    }

    // Label-based extraction deliberately does not fall back to the first date or amount.
    private func labeledDate(in text: String, labels: [String]) -> Date? {
        for label in labels {
            let escaped = NSRegularExpression.escapedPattern(for: label)
            let pattern = #"(?i)\b"# + escaped + #"\b[^\r\n0-9]{0,35}(\d{1,2}[/-]\d{1,2}[/-]\d{2,4}|(?:January|February|March|April|May|June|July|August|September|October|November|December)\s+\d{1,2}(?:st|nd|rd|th)?,?\s+\d{4}|\d{1,2}(?:st|nd|rd|th)?\s+(?:January|February|March|April|May|June|July|August|September|October|November|December)\s+\d{4})"#
            if let match = matches(pattern, in: text).first, let value = capture(match, 1, in: text), let date = parseDate(value) { return date }
        }
        return nil
    }

    private func labeledMoney(in text: String, labels: [String]) -> String? {
        for label in labels {
            let escaped = NSRegularExpression.escapedPattern(for: label)
            let pattern = #"(?i)\b"# + escaped + #"\b[^\r\n$]{0,45}(\$\s?\d[\d,]*(?:\.\d{1,2})?)"#
            if let match = matches(pattern, in: text).first, let value = capture(match, 1, in: text) { return value.replacingOccurrences(of: "$ ", with: "$") }
        }
        return nil
    }

    private func firstMoney(in text: String) -> String? {
        guard let match = matches(#"\$\s?\d[\d,]*(?:\.\d{1,2})?"#, in: text).first, let value = capture(match, 0, in: text) else { return nil }
        return value.replacingOccurrences(of: "$ ", with: "$")
    }

    private func firstDate(in text: String) -> Date? {
        let pattern = #"(?i)\b(?:\d{1,2}[/-]\d{1,2}[/-]\d{2,4}|(?:January|February|March|April|May|June|July|August|September|October|November|December)\s+\d{1,2}(?:st|nd|rd|th)?,?\s+\d{4}|\d{1,2}(?:st|nd|rd|th)?\s+(?:January|February|March|April|May|June|July|August|September|October|November|December)\s+\d{4})\b"#
        for match in matches(pattern, in: text) {
            if let value = capture(match, 0, in: text), let date = parseDate(value) { return date }
        }
        return nil
    }

    private func parseDate(_ value: String) -> Date? {
        let cleaned = value.replacingOccurrences(of: #"(?i)(\d)(st|nd|rd|th)\b"#, with: "$1", options: .regularExpression)
        let formats = ["M/d/yyyy", "MM/dd/yyyy", "M/d/yy", "MM/dd/yy", "M-d-yyyy", "MM-dd-yyyy", "M-d-yy", "MM-dd-yy", "MMMM d, yyyy", "MMMM d yyyy", "d MMMM yyyy"]
        for format in formats {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = format
            formatter.isLenient = false
            if let date = formatter.date(from: cleaned) { return date }
        }
        return nil
    }

    private func matches(_ pattern: String, in text: String) -> [NSTextCheckingResult] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        return regex.matches(in: text, range: NSRange(text.startIndex..<text.endIndex, in: text))
    }

    private func capture(_ match: NSTextCheckingResult, _ index: Int, in text: String) -> String? {
        guard index < match.numberOfRanges, let range = Range(match.range(at: index), in: text) else { return nil }
        return String(text[range])
    }

    
    private func format(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "MMMM d, yyyy"

        return formatter.string(from: date)
    }

}
