//
//  ThreadsMessagesResult.swift
//  
//
//  Created by Chris Dillard on 11/07/2023.
//

import Foundation

public struct ThreadsMessagesResult: Codable, Equatable {

    public struct ThreadsMessage: Codable, Equatable {

        public enum ThreadsMessageContent: Codable, Equatable {

            case text(ThreadsMessageContentText)
            case imageFile(ThreadsMessageContentImageFile)

            enum CodingKeys: String, CodingKey {
                case type
                case text
                case imageFile = "image_file"
            }

            enum ContentType: String, Codable {
                case text
                case imageFile = "image_file"
            }

            public struct ThreadsMessageContentText: Codable, Equatable {
                public let value: String

                enum CodingKeys: String, CodingKey {
                    case value
                }
            }

            public struct ThreadsMessageContentImageFile: Codable, Equatable {
                public let fileId: String
                public let detail: String

                enum CodingKeys: String, CodingKey {
                    case fileId = "file_id"
                    case detail
                }
            }

            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                let type = try container.decode(ContentType.self, forKey: .type)
                switch type {
                    case .text:
                        let text = try container.decode(ThreadsMessageContentText.self, forKey: .text)
                        self = .text(text)
                    case .imageFile:
                        let imageFile = try container.decode(ThreadsMessageContentImageFile.self, forKey: .imageFile)
                        self = .imageFile(imageFile)
                }
            }

            public func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                switch self {
                    case .text(let text):
                        try container.encode(ContentType.text, forKey: .type)
                        try container.encode(text, forKey: .text)
                    case .imageFile(let imageFile):
                        try container.encode(ContentType.imageFile, forKey: .type)
                        try container.encode(imageFile, forKey: .imageFile)
                }
            }
        }

        public let id: String
        public let role: String
        public let content: [ThreadsMessageContent]

        enum CodingKeys: String, CodingKey {
            case id
            case content
            case role
        }
    }

    public let data: [ThreadsMessage]

    enum CodingKeys: String, CodingKey {
        case data
    }
}
