//
//  FilesResult.swift
//  
//
//  Created by Chris Dillard on 11/07/2023.
//

import Foundation

public struct FilesResult: Codable, Equatable {

    public let id: String

}

public struct AllFilesResult: Codable {
    let data: [DatumFiles]?
    let object: String?
}

// MARK: - Datum
public struct DatumFiles: Codable {
    let id, object: String?
    let bytes, createdAt: Int?
    let filename, purpose: String?

    enum CodingKeys: String, CodingKey {
        case id, object, bytes
        case createdAt = "created_at"
        case filename, purpose
    }
}
