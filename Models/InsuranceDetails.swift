//
//  InsuranceDetails.swift
//  Oriva
//
//  Created by Shaik Imran on 10/28/26.
//

import Foundation

struct InsuranceDetails: Codable, Equatable {

    enum DocumentType: String, Codable {
        case rentersCertificate
        case liabilityCertificate
        case insurancePolicy
        case unknown
    }

    enum PaymentStatus: String, Codable {
        case paidInFull
        case unpaid
        case unknown
    }

    let documentType: DocumentType

    let policyStartDate: Date?
    let policyExpirationDate: Date?
    let endorsementEffectiveDate: Date?

    let coverageAmount: Decimal?
    let annualPremium: Decimal?
    let deductible: Decimal?

    let paymentStatus: PaymentStatus

    var displayTitle: String {
        switch documentType {
        case .rentersCertificate:
            return "Renters Insurance Certificate"
        case .liabilityCertificate:
            return "Liability Insurance Certificate"
        case .insurancePolicy:
            return "Insurance Policy"
        case .unknown:
            return "Insurance Document"
        }
    }

    var hasConfirmedPaymentDue: Bool {
        paymentStatus == .unpaid
    }
}
