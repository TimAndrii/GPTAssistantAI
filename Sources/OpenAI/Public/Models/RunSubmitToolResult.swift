//
//  File.swift
//
//
//  Created by Andrii Tymoshchuk on 06.12.2023.
//

import Foundation

public struct RunSubmitToolResult: Codable {
    let id, object: String?
    let createdAt: Int?
    let assistantID, threadID, status: String?
    let startedAt, expiresAt: Int?
    let cancelledAt, failedAt, completedAt, lastError: String?
    let model, instructions: String?
    let tools: [Tool]?
    let fileIDS: [String]?
    let metadata: Metadata?

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
struct Metadata: Codable {
}
