//
//  ThreadAddMessageQuery.swift
//  
//
//  Created by Chris Dillard on 11/07/2023.
//

import Foundation

public struct ThreadAddMessageQuery: Equatable, Codable {
    
    public let role: String
    public let content: StringOrCodable<[ChatContent]>?

    enum CodingKeys: String, CodingKey {
        case role
        case content

    }
    
    public init(role: String, content: StringOrCodable<[ChatContent]>) {
        self.role = role
        self.content = content
    }
}
