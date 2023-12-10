//
//  File.swift
//  
//
//  Created by Andrii Tymoshchuk on 06.12.2023.
//

import Foundation

public struct SubmitToolQuery: Codable, Equatable {

    public let toolOutputs: [ToolOutputs]

    enum CodingKeys: String, CodingKey {
        case toolOutputs = "tool_outputs"
    }

    public init(toolOutputs: [ToolOutputs]) {
        self.toolOutputs = toolOutputs
    }
}

public struct ToolOutputs: Codable, Equatable {
    public let toolCallId: String?
    public let output: String?

    enum CodingKeys: String, CodingKey {
        case toolCallId = "tool_call_id"
        case output
    }

    public init(toolCallId: String?, output: String?) {
        self.toolCallId = toolCallId
        self.output = output
    }
}
