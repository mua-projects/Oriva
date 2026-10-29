//
//  InsuranceTextAnalyzer.swift
//  Oriva
//
//  Created by Shaik Imran on 10/28/26.
//
import Foundation

struct InsuranceTextAnalyzer {

    func analyze(_ text: String) -> InsuranceDetails {

        let lower = text.lowercased()

        let documentType: InsuranceDetails.DocumentType

        if lower.contains("certificate (binder) of property insurance")
            || lower.contains("provisions of a tenant") {

            documentType = .rentersCertificate

        } else if lower.contains("certificate of liability insurance") {

            documentType = .liabilityCertificate

        } else if lower.contains("insurance policy") {

            documentType = .insurancePolicy

        } else {

            documentType = .unknown
        }

        let policyDates = extractPolicyPeriod(from: text)

        let expiration = policyDates?.end
            ?? extractDate(
                after: [
                    "policy expiration date",
                    "policy expiry date",
                    "expiration date",
                    "expiry date"
                ],
                in: text
            )

        let start = policyDates?.start
            ?? extractDate(
                after: [
                    "policy effective date",
                    "policy start date",
                    "inception date"
                ],
                in: text
            )

        let endorsementDate = extractDate(
            after: ["endorsement effective date"],
            in: text
        )

        let coverage = extractMoney(
            before: [
                "coverage amount",
                "coverage limit",
                "personal property coverage"
            ],
            in: text
        ) ?? extractTenantCoverage(from: text)

        let premium = extractMoney(
            after: ["annual premium", "total annual premium"],
            in: text
        )

        let deductible = extractMoney(
            after: ["deductible of", "deductible"],
            in: text
        )

        let paymentStatus: InsuranceDetails.PaymentStatus

        if lower.contains("paid in full") {

            paymentStatus = .paidInFull

        } else if lower.contains("payment due")
                    || lower.contains("balance due") {

            paymentStatus = .unpaid

        } else {

            paymentStatus = .unknown
        }

        return InsuranceDetails(
            documentType: documentType,
            policyStartDate: start,
            policyExpirationDate: expiration,
            endorsementEffectiveDate: endorsementDate,
            coverageAmount: coverage,
            annualPremium: premium,
            deductible: deductible,
            paymentStatus: paymentStatus
        )
    }

    // MARK: - Policy Period

    private func extractPolicyPeriod(
        from text: String
    ) -> (start: Date, end: Date)? {

        let pattern =
            #"(?i)\bfrom\s+(\d{1,2}/\d{1,2}/\d{4})\s+to\s+(\d{1,2}/\d{1,2}/\d{4})"#

        guard
            let match = firstMatch(pattern, in: text),
            let startText = captured(1, from: match, in: text),
            let endText = captured(2, from: match, in: text),
            let start = parseDate(startText),
            let end = parseDate(endText),
            end >= start
        else {
            return nil
        }

        return (start, end)
    }

    // MARK: - Dates

    private func extractDate(
        after labels: [String],
        in text: String
    ) -> Date? {

        for label in labels {

            let escaped = NSRegularExpression.escapedPattern(
                for: label
            )

            let pattern =
                #"(?i)"# + escaped +
                #"\s*[:\-]?\s*(\d{1,2}/\d{1,2}/\d{4})"#

            if let match = firstMatch(pattern, in: text),
               let value = captured(1, from: match, in: text),
               let date = parseDate(value) {

                return date
            }
        }

        return nil
    }

    private func parseDate(_ value: String) -> Date? {

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "MM/dd/yyyy"
        formatter.isLenient = false

        return formatter.date(from: value)
    }

    // MARK: - Money

    private func extractMoney(
        after labels: [String],
        in text: String
    ) -> Decimal? {

        for label in labels {

            let escaped = NSRegularExpression.escapedPattern(
                for: label
            )

            let pattern =
                #"(?i)"# + escaped +
                #"\s*[:\-]?\s*\$\s*([\d,]+(?:\.\d{1,2})?)"#

            if let match = firstMatch(pattern, in: text),
               let value = captured(1, from: match, in: text) {

                return parseMoney(value)
            }
        }

        return nil
    }

    private func extractMoney(
        before labels: [String],
        in text: String
    ) -> Decimal? {

        for label in labels {

            let escaped = NSRegularExpression.escapedPattern(
                for: label
            )

            let pattern =
                #"\$\s*([\d,]+(?:\.\d{1,2})?)\s*"# +
                escaped

            if let match = firstMatch(pattern, in: text),
               let value = captured(1, from: match, in: text) {

                return parseMoney(value)
            }
        }

        return nil
    }

    private func extractTenantCoverage(
        from text: String
    ) -> Decimal? {

        let pattern =
            #"(?i)provisions\s+of\s+a\s+tenant[\s\S]{0,160}?for\s+\$\s*([\d,]+(?:\.\d{1,2})?)"#

        guard
            let match = firstMatch(pattern, in: text),
            let value = captured(1, from: match, in: text)
        else {
            return nil
        }

        return parseMoney(value)
    }

    private func parseMoney(_ value: String) -> Decimal? {

        let cleaned = value.replacingOccurrences(
            of: ",",
            with: ""
        )

        return Decimal(
            string: cleaned,
            locale: Locale(identifier: "en_US_POSIX")
        )
    }

    // MARK: - Regex Helpers

    private func firstMatch(
        _ pattern: String,
        in text: String
    ) -> NSTextCheckingResult? {

        guard let regex = try? NSRegularExpression(
            pattern: pattern
        ) else {
            return nil
        }

        let range = NSRange(
            text.startIndex..<text.endIndex,
            in: text
        )

        return regex.firstMatch(
            in: text,
            range: range
        )
    }

    private func captured(
        _ index: Int,
        from match: NSTextCheckingResult,
        in text: String
    ) -> String? {

        guard
            let range = Range(
                match.range(at: index),
                in: text
            )
        else {
            return nil
        }

        return String(text[range])
    }
}

