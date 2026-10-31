//
//  DocumentClassifier.swift
//  Oriva
//
//  Created by Shaik Imran on 10/28/26.
//

//
//  DocumentClassifier.swift
//  Oriva
//
//  DOC-01E6-A: Document classification only.
//  Does not extract dates, infer payments, or save Admin items.
//
import Foundation

enum OrivaDocumentCategory: String, Codable, Equatable {
    case rentersInsuranceCertificate
    case liabilityInsuranceCertificate
    case insurancePolicy
    case electricityBill
    case appointment
    case passport
    case general
}

struct DocumentClassifier {
    func classify(_ originalText: String) -> OrivaDocumentCategory {
        let text = originalText.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = text.lowercased()

        // Certificates must be identified before generic insurance policies.
        if lower.contains("certificate (binder) of property insurance")
            || lower.contains("provisions of a tenant") {
            return .rentersInsuranceCertificate
        }

        if lower.contains("certificate of liability insurance")
            || (lower.contains("acord 25") && lower.contains("certificate holder")) {
            return .liabilityInsuranceCertificate
        }

        if lower.contains("renters insurance")
            || lower.contains("renter's insurance")
            || lower.contains("renters policy")
            || lower.contains("renters forms")
            || lower.contains("tenant insurance")
            || lower.contains("insurance policy")
            || lower.contains("policy period")
            || lower.contains("insurance") {
            return .insurancePolicy
        }

        if lower.contains("electricity") || lower.contains("power bill") {
            return .electricityBill
        }

        if lower.contains("dentist") || lower.contains("appointment") {
            return .appointment
        }

        if lower.contains("passport") {
            return .passport
        }

        return .general
    }
}

