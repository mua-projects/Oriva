//
//  AppState.swift
//  Oriva
//
//  Created by Shaik Imran on 10/24/26.
//

import Foundation
import SwiftUI


@Observable
final class AppState {

    // MARK: - Storage Keys

    private let adminItemsKey = "oriva.adminItems"
    private let handledItemsKey = "oriva.handledItems"
    private let documentsKey = "oriva.documents"


    // MARK: - Authentication

    enum AuthenticationState {

        case loggedOut
        case needsProfile
        case loggedIn
    }

    var authenticationState: AuthenticationState = .loggedOut


    // MARK: - Admin

    var adminItems: [AdminItem] = []
    var handledItems: [AdminItem] = []


    // MARK: - Documents

    var documents: [StoredDocument] = []


    // MARK: - Init

    init() {

        loadAdminItems()
        loadDocuments()
    }


    // MARK: - Authentication Actions

    func login() {

        authenticationState = .loggedIn
    }

    func signUp() {

        authenticationState = .needsProfile
    }

    func completeProfile() {

        authenticationState = .loggedIn
    }

    func logout() {

        authenticationState = .loggedOut
    }


    // MARK: - Admin Actions

    func addAdminItem(_ item: AdminItem) {

        adminItems.append(item)

        saveAdminItems()
    }

    func markAsHandled(_ item: AdminItem) {

        adminItems.removeAll {
            $0.id == item.id
        }

        handledItems.insert(
            item,
            at: 0
        )

        saveAdminItems()
    }


    // MARK: - Admin Persistence

    private func saveAdminItems() {

        if let adminData =
            try? JSONEncoder().encode(adminItems) {

            UserDefaults.standard.set(
                adminData,
                forKey: adminItemsKey
            )
        }

        if let handledData =
            try? JSONEncoder().encode(handledItems) {

            UserDefaults.standard.set(
                handledData,
                forKey: handledItemsKey
            )
        }
    }

    private func loadAdminItems() {

        if
            let adminData =
                UserDefaults.standard.data(
                    forKey: adminItemsKey
                ),
            let savedAdminItems =
                try? JSONDecoder().decode(
                    [AdminItem].self,
                    from: adminData
                )
        {

            adminItems = savedAdminItems
        }

        if
            let handledData =
                UserDefaults.standard.data(
                    forKey: handledItemsKey
                ),
            let savedHandledItems =
                try? JSONDecoder().decode(
                    [AdminItem].self,
                    from: handledData
                )
        {

            handledItems = savedHandledItems
        }
    }


    // MARK: - Reminders

    func setReminder(
        for item: AdminItem,
        at date: Date
    ) {

        guard
            let index = adminItems.firstIndex(
                where: {
                    $0.id == item.id
                }
            )
        else {
            return
        }

        adminItems[index].reminderDate = date

        saveAdminItems()
    }

    func cancelReminder(
        for item: AdminItem
    ) {

        guard
            let index = adminItems.firstIndex(
                where: {
                    $0.id == item.id
                }
            )
        else {
            return
        }

        adminItems[index].reminderDate = nil

        saveAdminItems()
    }


    // MARK: - Document Import

    func importDocument(
        from sourceURL: URL
    ) throws {

        let hasSecurityAccess =
            sourceURL.startAccessingSecurityScopedResource()

        defer {

            if hasSecurityAccess {

                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        guard
            let documentsDirectory =
                FileManager.default.urls(
                    for: .documentDirectory,
                    in: .userDomainMask
                ).first
        else {

            throw DocumentStorageError
                .documentsDirectoryUnavailable
        }

        let storedFileName =
            "\(UUID().uuidString)-\(sourceURL.lastPathComponent)"

        let destinationURL =
            documentsDirectory.appendingPathComponent(
                storedFileName
            )

        try FileManager.default.copyItem(
            at: sourceURL,
            to: destinationURL
        )

        let document = StoredDocument(
            fileName: sourceURL.lastPathComponent,
            storedFileName: storedFileName,
            dateAdded: Date()
        )

        documents.insert(
            document,
            at: 0
        )

        saveDocuments()
    }


    // MARK: - Delete Document

    func deleteDocument(
        _ document: StoredDocument
    ) {

        if
            let url = document.localURL,
            FileManager.default.fileExists(
                atPath: url.path
            )
        {

            do {

                try FileManager.default.removeItem(
                    at: url
                )

            } catch {

                print(
                    "Unable to delete document file:",
                    error.localizedDescription
                )
            }
        }

        documents.removeAll {
            $0.id == document.id
        }

        saveDocuments()
    }


    // MARK: - Document Persistence

    private func saveDocuments() {

        if let data =
            try? JSONEncoder().encode(documents) {

            UserDefaults.standard.set(
                data,
                forKey: documentsKey
            )
        }
    }

    private func loadDocuments() {

        guard
            let data =
                UserDefaults.standard.data(
                    forKey: documentsKey
                ),
            let savedDocuments =
                try? JSONDecoder().decode(
                    [StoredDocument].self,
                    from: data
                )
        else {

            return
        }

        documents = savedDocuments
    }
}


// MARK: - Document Storage Error

enum DocumentStorageError: LocalizedError {

    case documentsDirectoryUnavailable

    var errorDescription: String? {

        switch self {

        case .documentsDirectoryUnavailable:

            return "Oriva could not access its document storage."
        }
    }
}
