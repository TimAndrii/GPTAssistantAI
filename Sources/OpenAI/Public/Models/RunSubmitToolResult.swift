//
//  File.swift
//
//
//  Created by Andrii Tymoshchuk on 06.12.2023.
//

import Foundation

public struct RunSubmitToolResult: Codable {
    public let id, object: String?
    public let createdAt: Int?
    public let assistantID, threadID, status: String?
    public let startedAt, expiresAt: Int?
    public let cancelledAt, failedAt, completedAt, lastError: String?
    public let model, instructions: String?
    public let tools: [Tool]?
    public let fileIDS: [String]?
    public let metadata: Metadata?

    enum CodingKeys: String, CodingKey {
        case id, object
        case createdAt = "created_at"
        case assistantID = "assistant_id"
        case threadID = "thread_id"
        case status
        case startedAt = "started_at"
        case expiresAt = "expires_at"
        case cancelledAt = "cancelled_at"
        case failedAt = "failed_at"
        case completedAt = "completed_at"
        case lastError = "last_error"
        case model, instructions, tools
        case fileIDS = "file_ids"
        case metadata
    }
}

// MARK: - Metadata
public struct Metadata: Codable {
}
