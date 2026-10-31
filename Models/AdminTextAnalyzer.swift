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
            // Do not substitute an issue date or an unrelated date for a payment deadline.
            let detectedDate = labeledDate(in: text, labels: ["payment due date", "due date", "pay by"])
            // A random dollar amount may be a previous payment, credit, or account balance.
            let detectedAmount = labeledMoney(in: text, labels: ["amount due", "total due", "balance due", "amount payable", "payment amount"])
            let dateLabels = ["payment due date", "due date", "pay by"]
            let amountLabels = ["amount due", "total due", "balance due", "amount payable", "payment amount"]
            var warnings: [String] = []
            let dates = dateLabels.flatMap { labeledDateValues(in: text, label: $0) }
            let conflictingDates = Set(dates.map { format($0) }).count > 1
            if conflictingDates {
                warnings.append("Different payment due dates were detected. Verify the correct deadline.")
            }
            let amounts = amountLabels.flatMap { labeledValues(in: text, label: $0, valuePattern: #"(\$\s?\d[\d,]*(?:\.\d{1,2})?)"#) }
            let normalizedAmounts = Set(amounts.map { $0.replacingOccurrences(of: " ", with: "") })
            let conflictingAmounts = normalizedAmounts.count > 1
            if conflictingAmounts {
                warnings.append("Different amounts due were detected. Verify the payable amount.")
            }
            let date = conflictingDates ? nil : detectedDate
            let amount = conflictingAmounts ? nil : detectedAmount
            if date == nil && !conflictingDates { warnings.append("Payment due date was not found. Confirm the deadline in the bill.") }
            if amount == nil && !conflictingAmounts { warnings.append("Amount payable was not found. Confirm the balance owed.") }
            let action = date == nil || amount == nil || !warnings.isEmpty ? "Review electricity bill" : "Pay electricity bill"
            return AdminAnalysis(title: "Electricity bill", action: action, dueDate: date, amount: amount, consequence: lower.contains("late fee") ? "You may incur a late fee if the bill is not paid on time." : "Check the bill for payment requirements and any consequences of late payment.", suggestedAction: (date != nil && amount != nil) ? "Check the amount owed and pay the electricity bill before \(format(date!))." : "Review the electricity bill and confirm its payment due date and amount owed.", dateType: .paymentDue, validationWarnings: warnings)
        }
        if lower.contains("dentist") || lower.contains("appointment") {
            return AdminAnalysis(title: "Appointment", action: "Attend appointment", dueDate: generalDate, amount: generalAmount, consequence: "You may miss the appointment if no action is taken.", suggestedAction: generalDate.map { "Prepare for the appointment on \(format($0))." } ?? "Review the appointment and confirm its date.", dateType: .appointment, validationWarnings: generalDate == nil ? ["Appointment date was not found. Confirm the date and time."] : [])
        }
        if lower.contains("passport") {
            let date = labeledDate(in: text, labels: ["date of expiry", "expiration date", "expiry date", "expires"])
            return AdminAnalysis(title: "Passport expiry", action: "Review passport expiry", dueDate: date, amount: nil, consequence: "An expired passport may affect travel.", suggestedAction: date.map { "Review passport renewal requirements before \(format($0))." } ?? "Confirm the passport expiry date.", dateType: .documentExpiration, validationWarnings: date == nil ? ["Passport expiration date was not found. Confirm it from the document."] : [])
        }
        if lower.contains("insurance") || lower.contains("policy period") {
            return insuranceAnalysis(text, title: "Insurance", action: "Review insurance policy", certificate: false)
        }
        // Unclassified documents must not turn their first date or dollar value into a deadline or debt.
        return AdminAnalysis(title: "Admin item", action: "Review information", dueDate: nil, amount: nil, consequence: "This information may require your attention.", suggestedAction: "Review this item and confirm whether action is required.", validationWarnings: ["Document type could not be identified. Confirm what needs attention."])
    }

    private func insuranceAnalysis(_ text: String, title: String, action: String, certificate: Bool) -> AdminAnalysis {
        let expiration = labeledDate(in: text, labels: ["policy expiration date", "policy expiration", "expiration date", "expiry date", "policy expiry", "expires", "expiration", "expiry", "policy exp"])
        let effective = labeledDate(in: text, labels: ["policy effective date", "effective date", "policy effective", "effective"])
        let premium = labeledMoney(in: text, labels: ["annual premium", "total premium", "policy premium", "premium due", "premium"])
        let deductible = labeledMoney(in: text, labels: ["deductible"])
        let coverage = labeledMoney(in: text, labels: ["personal property coverage", "personal property", "liability coverage", "personal liability", "coverage limit", "limit of liability", "coverage amount"])
        let date = expiration // Never substitute an issue or effective date for expiry.
        // Premium and coverage are informational; neither proves a payment is owed.
        let amount: String? = nil
        var details: [String] = []
        if let expiration { details.append("Policy expiration: \(format(expiration)).") }
        if let effective { details.append("Policy effective date: \(format(effective)).") }
        if let premium { details.append("Detected premium: \(premium); this is not a confirmed amount due.") }
        if let deductible { details.append("Detected deductible: \(deductible).") }
        if let coverage { details.append("Detected coverage amount: \(coverage); this is not a bill.") }
        if details.isEmpty { details.append("Confirm the coverage, premium, and policy dates in the original document.") }
        let prefix = certificate ? "This certificate provides evidence of insurance coverage." : "This appears to be an insurance policy document."
        let suggestion = expiration.map { "Review coverage and renewal options before \(format($0)). Confirm any separate payment due date." } ?? "Review coverage, policy expiration, and any separate payment due date."
        return AdminAnalysis(title: title, action: action, dueDate: date, amount: amount, consequence: prefix + " " + details.joined(separator: " "), suggestedAction: suggestion, dateType: .policyExpiration, validationWarnings: date == nil ? ["Policy expiration date was not found. Confirm the renewal date."] : [])
    }

    // Keep label/value matching on one line or the immediately following line.
    // OCR commonly separates a field label and its value into two lines.
    private func labeledDate(in text: String, labels: [String]) -> Date? {
        let datePattern = #"(\d{1,2}[/-]\d{1,2}[/-]\d{2,4}|(?:January|February|March|April|May|June|July|August|September|October|November|December)\s+\d{1,2}(?:st|nd|rd|th)?,?\s+\d{4}|\d{1,2}(?:st|nd|rd|th)?\s+(?:January|February|March|April|May|June|July|August|September|October|November|December)\s+\d{4})"#
        for label in labels {
            for candidate in labeledValues(in: text, label: label, valuePattern: datePattern) {
                if let date = parseDate(candidate) { return date }
            }
        }
        return nil
    }

    private func labeledDateValues(in text: String, label: String) -> [Date] {
        let pattern = #"(\d{1,2}[/-]\d{1,2}[/-]\d{2,4}|(?:January|February|March|April|May|June|July|August|September|October|November|December)\s+\d{1,2}(?:st|nd|rd|th)?,?\s+\d{4}|\d{1,2}(?:st|nd|rd|th)?\s+(?:January|February|March|April|May|June|July|August|September|October|November|December)\s+\d{4})"#
        return labeledValues(in: text, label: label, valuePattern: pattern).compactMap { parseDate($0) }
    }

    private func labeledMoney(in text: String, labels: [String]) -> String? {
        let moneyPattern = #"(\$\s?\d[\d,]*(?:\.\d{1,2})?)"#
        for label in labels {
            if let value = labeledValues(in: text, label: label, valuePattern: moneyPattern).first {
                return value.replacingOccurrences(of: "$ ", with: "$")
            }
        }
        return nil
    }

    private func labeledValues(in text: String, label: String, valuePattern: String) -> [String] {
        let lines = text.components(separatedBy: .newlines)
        let escapedLabel = NSRegularExpression.escapedPattern(for: label)
        let labelPattern = #"(?i)\b"# + escapedLabel + #"\b"#
        var results: [String] = []

        for index in lines.indices {
            let line = lines[index].trimmingCharacters(in: .whitespacesAndNewlines)
            guard let labelMatch = matches(labelPattern, in: line).first,
                  let labelRange = Range(labelMatch.range, in: line) else { continue }

            let suffix = String(line[labelRange.upperBound...])
            // Same-line values must immediately follow the label and punctuation.
            let sameLinePattern = #"(?i)^[ \t:–—-]{0,12}"# + valuePattern
            if let match = matches(sameLinePattern, in: suffix).first,
               let value = capture(match, 1, in: suffix) {
                results.append(value)
                continue
            }

            // Only use the next line when the label occupies the entire current line.
            // Never skip other fields or scan a column of unrelated amounts.
            guard suffix.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  index + 1 < lines.count else { continue }
            let next = lines[index + 1].trimmingCharacters(in: .whitespacesAndNewlines)
            let nextLinePattern = #"(?i)^"# + valuePattern + #"[ \t]*$"#
            if let match = matches(nextLinePattern, in: next).first,
               let value = capture(match, 1, in: next) {
                results.append(value)
            }
        }
        return results
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
