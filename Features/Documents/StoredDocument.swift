//
//  StoredDocument.swift
//  Oriva
//
//  Created by Shaik Imran on 10/25/26.
//
import Foundation

struct StoredDocument: Identifiable, Codable {

    let id: UUID
    let fileName: String
    let storedFileName: String
    let dateAdded: Date

    init(
        id: UUID = UUID(),
        fileName: String,
        storedFileName: String,
        dateAdded: Date = Date()
    ) {
        self.id = id
        self.fileName = fileName
        self.storedFileName = storedFileName
        self.dateAdded = dateAdded
    }

    var formattedDateAdded: String {
        dateAdded.formatted(
            date: .abbreviated,
            time: .omitted
        )
    }
    var localURL: URL? {

        guard let documentsDirectory = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first else {
            return nil
        }

        return documentsDirectory
            .appendingPathComponent(storedFileName)
    }
}
