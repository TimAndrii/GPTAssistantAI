//
//  AssistantsQuery.swift
//  
//
//  Created by Chris Dillard on 11/07/2023.
//

import Foundation

public struct RunsQuery: Codable {

    public let assistantId: String
    public let parallelToolCalls: Bool

    enum CodingKeys: String, CodingKey {
        case assistantId = "assistant_id"
        case parallelToolCalls = "parallel_tool_calls"
    }
    
    public init(assistantId: String, parallelToolCalls: Bool = true) {

        self.assistantId = assistantId
        self.parallelToolCalls = parallelToolCalls
    }
}
