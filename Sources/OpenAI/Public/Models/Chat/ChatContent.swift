//
//  ChatContent.swift
//  
//
//  Created by Federico Vitale on 14/11/23.
//

import Foundation

import Foundation

public struct ChatContent: Codable, Equatable {
    public let type: ChatContentType
    public let value: String

    enum CodingKeys: CodingKey {
        case type
        case value
    }

    public enum ChatContentType: String, Codable {
        case text
        case imageUrl = "image_url"
        case imageFile = "image_file"
    }

    public struct ChatImageUrl: Codable, Equatable {
        let url: String

        enum CodingKeys: CodingKey {
            case url
        }
    }

    public struct ChatImageFile: Codable, Equatable {
        let fileId: String

        enum CodingKeys: String, CodingKey {
            case fileId = "file_id"
        }
    }

    public static func text(_ text: String) -> Self {
        Self.init(text)
    }

    public static func imageUrl(_ url: String) -> Self {
        Self.init(type: .imageUrl, value: url)
    }

    public static func imageFile(_ fileId: String) -> Self {
        Self.init(type: .imageFile, value: fileId)
    }

    public init(type: ChatContentType, value: String) {
        self.type = type
        self.value = value
    }

    public init(_ text: String) {
        self.type = .text
        self.value = text
    }

    // Custom encoding since the `value` key is variable based on the `type`
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: ChatContent.CodingKeys.self)
        var dynamicContainer = encoder.container(keyedBy: DynamicKey.self)

        try container.encode(type, forKey: .type)

        switch self.type {
            case .text:
                try dynamicContainer.encode(value, forKey: .init(stringValue: "text"))
            case .imageUrl:
                var nested = dynamicContainer.nestedContainer(keyedBy: ChatImageUrl.CodingKeys.self, forKey: .init(stringValue: "image_url"))
                try nested.encode(value, forKey: .url)
            case .imageFile:
                var nested = dynamicContainer.nestedContainer(keyedBy: ChatImageFile.CodingKeys.self, forKey: .init(stringValue: "image_file"))
                try nested.encode(value, forKey: .fileId)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decode(ChatContentType.self, forKey: .type)

        let dynamicContainer = try decoder.container(keyedBy: DynamicKey.self)

        switch self.type {
            case .text:
                self.value = try dynamicContainer.decode(String.self, forKey: .init(stringValue: "text"))
            case .imageUrl:
                let nested = try dynamicContainer.nestedContainer(keyedBy: ChatImageUrl.CodingKeys.self, forKey: .init(stringValue: "image_url"))
                self.value = try nested.decode(String.self, forKey: .url)
            case .imageFile:
                let nested = try dynamicContainer.nestedContainer(keyedBy: ChatImageFile.CodingKeys.self, forKey: .init(stringValue: "image_file"))
                self.value = try nested.decode(String.self, forKey: .fileId)
        }
    }
}
