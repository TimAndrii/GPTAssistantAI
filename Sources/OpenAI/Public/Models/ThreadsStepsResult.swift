//
//  File.swift
//
//
//  Created by Andrii Tymoshchuk on 06.12.2023.
//

import Foundation

public struct ThreadsStepsResult: Codable {
    public let object: String?
    public let data: [Datum]?
    public let firstID, lastID: String?
    public let hasMore: Bool?

    enum CodingKeys: String, CodingKey {
        case object, data
        case firstID = "first_id"
        case lastID = "last_id"
        case hasMore = "has_more"
    }
}

// MARK: - Datum
public struct Datum: Codable {
    public let id, object: String?
    public let createdAt: Int?
    public let runID, assistantID, threadID, type: String?
    public let status: String?
    public let cancelledAt, completedAt: Int?
    public let expiresAt: Int?
    public let failedAt, lastError: String?
    public let stepDetails: StepDetails?

    enum CodingKeys: String, CodingKey {
        case id, object
        case createdAt = "created_at"
        case runID = "run_id"
        case assistantID = "assistant_id"
        case threadID = "thread_id"
        case type, status
        case cancelledAt = "cancelled_at"
        case completedAt = "completed_at"
        case expiresAt = "expires_at"
        case failedAt = "failed_at"
        case lastError = "last_error"
        case stepDetails = "step_details"
    }
}

// MARK: - StepDetails
public struct StepDetails: Codable {
    public let type: String?
    public let toolCalls: [StepsToolCall]?

    enum CodingKeys: String, CodingKey {
        case type
        case toolCalls = "tool_calls"
    }
}

// MARK: - ToolCall
public struct StepsToolCall: Codable {
    public let id, type: String?
    public let function: Function?
}

// MARK: - Function
public struct Function: Codable {
    public let name, arguments: String?
}
