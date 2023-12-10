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
    public let data: [DatumFiles]?
    public let object: String?
}

// MARK: - Datum
public struct DatumFiles: Codable {
    public let id, object: String?
    public let bytes, createdAt: Int?
    public let filename, purpose: String?

    enum CodingKeys: String, CodingKey {
        case id, object, bytes
        case createdAt = "created_at"
        case filename, purpose
    }
}
