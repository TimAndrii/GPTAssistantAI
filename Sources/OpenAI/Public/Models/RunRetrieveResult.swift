//
//  RunsResult.swift
//  
//
//  Created by Chris Dillard on 11/07/2023.
//

import Foundation

public struct RunRetreiveResult: Codable, Equatable {

    public let status: String
    public let requiredAction: RequiredAction?

    enum CodingKeys: String, CodingKey {
        case status
        case requiredAction = "required_action"
    }
}

public struct RequiredAction: Codable, Equatable {
    public let toolCalls: [ToolCall]?

    enum CodingKeys: String, CodingKey {
        case toolCalls = "tool_calls"
    }
}

