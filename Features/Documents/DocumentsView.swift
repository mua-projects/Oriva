//
//  DocumentsView.swift
//  Oriva
//
//  Created by Shaik Imran on 10/24/26.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers
import QuickLook
import PDFKit


struct DocumentsView: View {

    @Bindable var appState: AppState

    @State private var showingDocumentPicker = false
    @State private var importErrorMessage: String?
    @State private var previewURL: URL?

    @State private var documentReadResult: DocumentReadResult?
    @State private var documentReadErrorMessage: String?

    var body: some View {

        NavigationStack {

            Group {

                if appState.documents.isEmpty {

                    ContentUnavailableView {

                        Label(
                            "No Documents Yet",
                            systemImage: "folder"
                        )

                    } description: {

                        Text(
                            "Documents you give Oriva will be stored here."
                        )

                    } actions: {

                        Button {

                            showingDocumentPicker = true

                        } label: {

                            Label(
                                "Add Document",
                                systemImage: "plus"
                            )
                        }
                        .buttonStyle(.borderedProminent)
                    }

                } else {

                    List {

                        ForEach(appState.documents) { document in

                            Button {

                                openDocument(document)

                            } label: {

                                DocumentRow(
                                    document: document
                                )
                            }
                            .buttonStyle(.plain)
                            .swipeActions(
                                edge: .trailing,
                                allowsFullSwipe: false
                            ) {

                                Button(
                                    role: .destructive
                                ) {

                                    appState.deleteDocument(
                                        document
                                    )

                                } label: {

                                    Label(
                                        "Delete",
                                        systemImage: "trash"
                                    )
                                }
                            }
                            .contextMenu {

                                Button {

                                    readDocument(
                                        document
                                    )

                                } label: {

                                    Label(
                                        "Read Document",
                                        systemImage: "text.viewfinder"
                                    )
                                }

                                Button {

                                    openDocument(
                                        document
                                    )

                                } label: {

                                    Label(
                                        "Preview",
                                        systemImage: "eye"
                                    )
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Documents")
            .toolbar {

                if !appState.documents.isEmpty {

                    ToolbarItem(
                        placement: .topBarTrailing
                    ) {

                        Button {

                            showingDocumentPicker = true

                        } label: {

                            Image(
                                systemName: "plus"
                            )
                        }
                    }
                }
            }
            .fileImporter(
                isPresented: $showingDocumentPicker,
                allowedContentTypes: [
                    .pdf,
                    .image,
                    .plainText
                ],
                allowsMultipleSelection: false
            ) { result in

                switch result {

                case .success(let urls):

                    guard let url = urls.first else {
                        return
                    }

                    do {

                        try appState.importDocument(
                            from: url
                        )

                    } catch {

                        importErrorMessage =
                            error.localizedDescription
                    }

                case .failure(let error):

                    importErrorMessage =
                        error.localizedDescription
                }
            }
            .alert(
                "Unable to Add Document",
                isPresented: Binding(
                    get: {
                        importErrorMessage != nil
                    },
                    set: { isPresented in

                        if !isPresented {
                            importErrorMessage = nil
                        }
                    }
                )
            ) {

                Button(
                    "OK",
                    role: .cancel
                ) {

                    importErrorMessage = nil
                }

            } message: {

                Text(
                    importErrorMessage
                    ?? "Something went wrong."
                )
            }
            .alert(
                "Unable to Read Document",
                isPresented: Binding(
                    get: {
                        documentReadErrorMessage != nil
                    },
                    set: { isPresented in

                        if !isPresented {
                            documentReadErrorMessage = nil
                        }
                    }
                )
            ) {

                Button(
                    "OK",
                    role: .cancel
                ) {

                    documentReadErrorMessage = nil
                }

            } message: {

                Text(
                    documentReadErrorMessage
                    ?? "Oriva could not read this document."
                )
            }
            .sheet(
                isPresented: Binding(
                    get: {
                        previewURL != nil
                    },
                    set: { isPresented in

                        if !isPresented {
                            previewURL = nil
                        }
                    }
                )
            ) {

                if let previewURL {

                    DocumentPreviewSheet(
                        url: previewURL
                    ) {

                        self.previewURL = nil
                    }
                }
            }
            .sheet(
                item: $documentReadResult
            ) { result in
                
                ExtractedDocumentTextView(
                    result: result,
                    appState: appState
                )
            }
        }
    }
    


    // MARK: - Open Document

    private func openDocument(
        _ document: StoredDocument
    ) {

        guard
            let url = document.localURL,
            FileManager.default.fileExists(
                atPath: url.path
            )
        else {

            importErrorMessage =
                "This document could not be found on this device."

            return
        }

        previewURL = url
    }


    // MARK: - Read Document

    private func readDocument(
        _ document: StoredDocument
    ) {

        guard
            let url = document.localURL,
            FileManager.default.fileExists(
                atPath: url.path
            )
        else {

            documentReadErrorMessage =
                "This document could not be found on this device."

            return
        }

        guard
            url.pathExtension.lowercased() == "pdf"
        else {

            documentReadErrorMessage =
                "Text extraction is currently available for PDF documents only."

            return
        }

        guard
            let pdfDocument = PDFDocument(
                url: url
            )
        else {

            documentReadErrorMessage =
                "Oriva could not open this PDF."

            return
        }

        var pageText: [String] = []

        for pageIndex in 0..<pdfDocument.pageCount {

            guard
                let page = pdfDocument.page(
                    at: pageIndex
                ),
                let text = page.string?
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ),
                !text.isEmpty
            else {

                continue
            }

            pageText.append(text)
        }

        let combinedText = pageText.joined(
            separator: "\n\n"
        )

        guard !combinedText.isEmpty else {

            documentReadErrorMessage =
                """
                Oriva could not find readable text in this PDF. \
                It may be a scanned document or image-based PDF.
                """

            return
        }

        documentReadResult = DocumentReadResult(
            document: document,
            text: combinedText
        )
    }
}


// MARK: - Document Read Result

struct DocumentReadResult: Identifiable {

    let id = UUID()

    let document: StoredDocument

    let text: String
}


// MARK: - Document Row

struct DocumentRow: View {

    let document: StoredDocument

    var body: some View {

        HStack(spacing: 14) {

            Image(
                systemName: "doc.fill"
            )
            .font(.title2)
            .frame(width: 36)

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text(
                    document.fileName
                )
                .fontWeight(.medium)
                .foregroundStyle(.primary)

                Text(
                    "Added \(document.formattedDateAdded)"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Image(
                systemName: "chevron.right"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}


// MARK: - Document Understanding

struct ExtractedDocumentTextView: View {
    
    let result: DocumentReadResult
    
    @Bindable var appState: AppState
    
    @Environment(\.dismiss)
    private var dismiss
    
    @State private var showingExtractedText = false
    
    @State private var showingTrackedConfirmation = false
    
    
    
    private var analysis: AdminAnalysis {

        let insurance = InsuranceTextAnalyzer().analyze(result.text)

        if insurance.documentType == .rentersCertificate {

            let expiration = insurance.policyExpirationDate

            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = "MMMM d, yyyy"

            let expirationText = expiration.map {
                formatter.string(from: $0)
            } ?? "Not detected"

            let paymentText: String

            switch insurance.paymentStatus {
            case .paidInFull:
                paymentText = "The annual premium is marked paid in full."
            case .unpaid:
                paymentText = "The document indicates an outstanding payment. Verify the amount and due date."
            case .unknown:
                paymentText = "Payment status has not been confirmed."
            }

            return AdminAnalysis(
                title: "Renters Insurance Certificate",
                action: "Review insurance renewal",
                dueDate: expiration,
                amount: nil,
                consequence: "This certificate provides evidence of renters insurance coverage; it is not the insurance policy itself. Policy expiration: \(expirationText). \(paymentText)",
                suggestedAction: "Keep this certificate for your records and review coverage before \(expirationText).",
                dateType: .policyExpiration
            )
        }

        return AdminTextAnalyzer().analyze(result.text)
    }

    
    
    private var insuranceDetails: InsuranceDetails? {
        let text = result.text.lowercased()
        let insuranceSignals = [
            "insurance", "policyholder", "policy holder",
            "annual premium", "certificate (binder)"
        ]
        guard insuranceSignals.contains(where: { text.contains($0) }) else {
            return nil
        }
        return InsuranceTextAnalyzer().analyze(result.text)
    }


    private var isAlreadyTracked: Bool {
        
        appState.adminItems.contains {
            $0.sourceDocumentID == result.document.id
        }
        ||
        appState.handledItems.contains {
            $0.sourceDocumentID == result.document.id
        }
    }
    
    
    var body: some View {
        
            
            NavigationStack {
                
                ScrollView {
                    
                    VStack(
                        alignment: .leading,
                        spacing: 20
                    ) {
                        
                        // MARK: Header
                        
                        VStack(
                            alignment: .leading,
                            spacing: 6
                        ) {
                            
                            Label(
                                "Oriva can read this document",
                                systemImage: "text.viewfinder"
                            )
                            .font(.title2)
                            .fontWeight(.bold)
                            
                            Text(
                                result.document.fileName
                            )
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }
                        
                        
                        Divider()
                        
                        
                        // MARK: Structured Understanding
                        
                        DocumentAnalysisView(
                            analysis: analysis
                        )

                        if let insuranceDetails {
                            Divider()
                            InsuranceExtractionValidationView(
                                details: insuranceDetails
                            )
                        }
                        
                        
                        Divider()
                        
                        
                        // MARK: Extracted Text
                        
                        DisclosureGroup(
                            isExpanded: $showingExtractedText
                        ) {
                            
                            Text(
                                result.text
                            )
                            .font(.body)
                            .textSelection(.enabled)
                            .frame(
                                maxWidth: .infinity,
                                alignment: .leading
                            )
                            .padding(.top, 12)
                            
                        } label: {
                            
                            Label(
                                showingExtractedText
                                ? "Hide Extracted Text"
                                : "View Extracted Text",
                                systemImage: "doc.text"
                            )
                            .font(.headline)
                        }
                        
                        
                        Divider()
                        
                        
                        // MARK: Confirm
                        
                        // MARK: Confirm
                        
                        // MARK: Confirm
                        
                        VStack(
                            alignment: .leading,
                            spacing: 12
                        ) {
                            
                            if isAlreadyTracked {
                                
                                Label(
                                    "Tracked in Admin",
                                    systemImage: "checkmark.circle.fill"
                                )
                                .font(.headline)
                                .foregroundStyle(.secondary)
                                .frame(
                                    maxWidth: .infinity,
                                    alignment: .leading
                                )
                                .padding()
                                .background(
                                    Color.secondary.opacity(0.10)
                                )
                                .clipShape(
                                    RoundedRectangle(
                                        cornerRadius: 14
                                    )
                                )
                                
                                Text(
                                    "This document is already linked to an Admin item."
                                )
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                
                            } else {
                                
                                Button {
                                    
                                    confirmAndTrack()
                                    
                                } label: {
                                    
                                    Label(
                                        "Confirm & Track",
                                        systemImage: "checkmark.circle.fill"
                                    )
                                    .fontWeight(.semibold)
                                    .frame(
                                        maxWidth: .infinity
                                    )
                                }
                                .buttonStyle(
                                    .borderedProminent
                                )
                                .controlSize(.large)
                                
                                Text(
                                    "Oriva will add this to your admin items. The original document will remain in Documents."
                                )
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding()
                }
                .navigationTitle(
                    "Document Review"
                )
                .navigationBarTitleDisplayMode(
                    .inline
                )
                .toolbar {
                    
                    ToolbarItem(
                        placement: .topBarTrailing
                    ) {
                        
                        Button(
                            "Done"
                        ) {
                            
                            dismiss()
                        }
                    }
                }
                .alert(
                    "Added to Oriva",
                    isPresented: $showingTrackedConfirmation
                ) {
                    
                    Button(
                        "Done"
                    ) {
                        
                        dismiss()
                    }
                    
                } message: {
                    
                    Text(
                        trackingConfirmationMessage
                    )
                }
            }
        }
        
        
        // MARK: - Confirm & Track
        
        private func confirmAndTrack() {
            
            let item = AdminItem(
                title: analysis.title,
                action: analysis.action,
                dueDate: analysis.dueDate,
                amount: analysis.amount,
                consequence: analysis.consequence,
                suggestedAction: analysis.suggestedAction,
                sourceDocumentID: result.document.id,
                dateType: analysis.dateType
            )
            
            appState.addAdminItem(
                item
            )
            
            showingTrackedConfirmation = true
        }
        
        
        private var trackingConfirmationMessage: String {
            
            if analysis.dueDate == nil {
                
                return
                "This item has been added to Needs You because no important date was detected."
            }
            
            return
            "This item has been added to your admin items."
        }
    }
    
    
    // MARK: - Document Analysis
    
    struct DocumentAnalysisView: View {
        
        let analysis: AdminAnalysis
        
        var body: some View {
            
            VStack(
                alignment: .leading,
                spacing: 18
            ) {
                
                VStack(
                    alignment: .leading,
                    spacing: 5
                ) {
                    
                    Label(
                        "Oriva understands this as",
                        systemImage: "checkmark.circle.fill"
                    )
                    .font(.headline)
                    
                    Text(
                        analysis.title
                    )
                    .font(.title2)
                    .fontWeight(.bold)
                }
                
                
                DocumentAnalysisField(
                    title: "Action",
                    value: analysis.action
                )
                
                
                DocumentAnalysisField(
                    title: "Important Date",
                    value:
                        formattedDate(
                            analysis.dueDate
                        )
                )
                
                
                DocumentAnalysisField(
                    title: "Amount",
                    value:
                        analysis.amount
                    ?? "Not detected"
                )
                
                
                DocumentAnalysisField(
                    title: "What It Means",
                    value:
                        analysis.consequence
                )
                
                
                DocumentAnalysisField(
                    title: "Suggested Action",
                    value:
                        analysis.suggestedAction
                )
                
                
                Text(
                    "Review this before Oriva tracks anything."
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
        }
        
        
       
        private func formattedDate(_ date: Date?) -> String {
            guard let date else {
                return "Not detected"
            }

            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = "MMMM d, yyyy"

            return formatter.string(from: date)
        }

    }
    
    
    // MARK: - Insurance Extraction Validation

    private struct InsuranceExtractionValidationView: View {

        let details: InsuranceDetails

        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                Label(
                    "Insurance Details — Validation",
                    systemImage: "checkmark.shield"
                )
                .font(.headline)

                Text("Detected from document text. Verify against the original PDF before relying on these values.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                DocumentAnalysisField(
                    title: "Document Type",
                    value: details.displayTitle
                )
                DocumentAnalysisField(
                    title: "Policy Starts",
                    value: dateText(details.policyStartDate)
                )
                DocumentAnalysisField(
                    title: "Policy Expires",
                    value: dateText(details.policyExpirationDate)
                )
                DocumentAnalysisField(
                    title: "Coverage",
                    value: moneyText(details.coverageAmount)
                )
                DocumentAnalysisField(
                    title: "Annual Premium",
                    value: moneyText(details.annualPremium)
                )
                DocumentAnalysisField(
                    title: "Deductible",
                    value: moneyText(details.deductible)
                )
                DocumentAnalysisField(
                    title: "Payment Status",
                    value: paymentText
                )
                DocumentAnalysisField(
                    title: "Endorsement Effective",
                    value: dateText(details.endorsementEffectiveDate)
                )

                Text("Validation only — these extracted fields do not change saved Admin items or payment reminders.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }

        private var paymentText: String {
            switch details.paymentStatus {
            case .paidInFull: return "Paid in full"
            case .unpaid: return "Possible outstanding payment — verify"
            case .unknown: return "Not confirmed"
            }
        }

        private func dateText(_ date: Date?) -> String {
            guard let date else { return "Not detected" }
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = "MMMM d, yyyy"
            return formatter.string(from: date)
        }

        private func moneyText(_ amount: Decimal?) -> String {
            guard let amount else { return "Not detected" }
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = "USD"
            formatter.locale = Locale(identifier: "en_US")
            return formatter.string(from: NSDecimalNumber(decimal: amount))
                ?? "Not detected"
        }
    }


    // MARK: - Document Analysis Field
    
    struct DocumentAnalysisField: View {
        
        let title: String
        
        let value: String
        
        var body: some View {
            
            VStack(
                alignment: .leading,
                spacing: 5
            ) {
                
                Text(
                    title.uppercased()
                )
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                
                Text(
                    value
                )
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
            }
        }
    }
    
    
    // MARK: - Preview Sheet
    
    struct DocumentPreviewSheet: View {
        
        let url: URL
        
        let onClose: () -> Void
        
        var body: some View {
            
            NavigationStack {
                
                QuickLookPreview(
                    url: url
                )
                .ignoresSafeArea(
                    edges: .bottom
                )
                .navigationTitle(
                    url.lastPathComponent
                )
                .navigationBarTitleDisplayMode(
                    .inline
                )
                .toolbar {
                    
                    ToolbarItem(
                        placement: .topBarLeading
                    ) {
                        
                        Button {
                            
                            onClose()
                            
                        } label: {
                            
                            Label(
                                "Close",
                                systemImage: "xmark"
                            )
                        }
                    }
                }
            }
        }
    }
    
    
    // MARK: - Quick Look
    
    struct QuickLookPreview:
        UIViewControllerRepresentable {
        
        let url: URL
        
        func makeCoordinator() -> Coordinator {
            
            Coordinator(
                url: url
            )
        }
        
        func makeUIViewController(
            context: Context
        ) -> QLPreviewController {
            
            let controller =
            QLPreviewController()
            
            controller.dataSource =
            context.coordinator
            
            return controller
        }
        
        func updateUIViewController(
            _ uiViewController: QLPreviewController,
            context: Context
        ) {
            
            // Nothing to update.
        }
        
        
        final class Coordinator:
            NSObject,
            QLPreviewControllerDataSource {
            
            let url: URL
            
            init(
                url: URL
            ) {
                
                self.url = url
            }
            
            func numberOfPreviewItems(
                in controller: QLPreviewController
            ) -> Int {
                
                1
            }
            
            func previewController(
                _ controller: QLPreviewController,
                previewItemAt index: Int
            ) -> QLPreviewItem {
                
                url as NSURL
            }
        }
    }

