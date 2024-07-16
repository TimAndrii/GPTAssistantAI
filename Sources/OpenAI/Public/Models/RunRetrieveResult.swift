//
//  RunsResult.swift
//  
//
//  Created by Chris Dillard on 11/07/2023.
//

import Foundation

public struct RunRetreiveResult: Codable, Equatable {

    public let status: String
    public let requiredAction: RequiredAction

    enum CodingKeys: String, CodingKey {
        case status
        case requiredAction = "required_action"
    }
}

// MARK: - RequiredAction
public struct RequiredAction: Codable, Equatable {
    public let submitToolOutputs: SubmitToolOutputs

    enum CodingKeys: String, CodingKey {
        case submitToolOutputs = "submit_tool_outputs"
    }
}

// MARK: - SubmitToolOutputs
public struct SubmitToolOutputs: Codable, Equatable {
    public let toolCalls: [ToolCallValue]

    enum CodingKeys: String, CodingKey {
        case toolCalls = "tool_calls"
    }
}

// MARK: - ToolCall
public struct ToolCallValue: Codable, Equatable {
    public let id: String
}
