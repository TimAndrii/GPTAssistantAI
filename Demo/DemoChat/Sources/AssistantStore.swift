//
//  ChatStore.swift
//  DemoChat
//
//  Created by Sihao Lu on 3/25/23.
//

import Foundation
import Combine
import OpenAI

public final class AssistantStore: ObservableObject {
    public var openAIClient: OpenAIProtocol
    let idProvider: () -> String
    @Published var selectedAssistantId: String?

    @Published var availableAssistants: [Assistant] = []

    public init(
        openAIClient: OpenAIProtocol,
        idProvider: @escaping () -> String
    ) {
        self.openAIClient = openAIClient
        self.idProvider = idProvider
    }

    // MARK: Models

    @MainActor
    func createAssistant(name: String, description: String, instructions: String, codeInterpreter: Bool, retrievel: Bool, fileIds: [String]? = nil) async -> String? {
        do {
            let tools = createToolsArray(codeInterpreter: codeInterpreter, retrieval: retrievel, functions: [
                .init(name: "Hello",
                      description: "When user hello",
                      parameters: .init(type: .object,
                                        properties: ["Hello" : .init(type: .string, description: "Say hello back")],
                                        required: ["Hello"])
                     )
            ])

            let query = AssistantsQuery(model: Model.gpt4_1106_preview, name: name, description: description, instructions: instructions, tools:tools, fileIds: fileIds)
            let response = try await openAIClient.assistants(query: query, method: "POST", after: nil)

            // Returns assistantId
            return response.id

        } catch {
            // TODO: Better error handling
            print(error.localizedDescription)
        }
        return nil
    }

    @MainActor
    func modifyAssistant(asstId: String, name: String, description: String, instructions: String, codeInterpreter: Bool, retrievel: Bool, fileIds: [String]? = nil) async -> String? {
        do {
            let tools = createToolsArray(codeInterpreter: codeInterpreter, retrieval: retrievel, functions: [
                .init(name: "Hello",
                      description: "When user hello",
                      parameters: .init(type: .object,
                                        properties: ["Hello" : .init(type: .string, description: "Say hello back")],
                                        required: ["Hello"])
                     )
            ])
            let query = AssistantsQuery(model: Model.gpt4_1106_preview, name: name, description: description, instructions: instructions, tools: tools, fileIds: fileIds)
            let response = try await openAIClient.assistantModify(query: query, asstId: asstId)

            // Returns assistantId
            return response.id

        } catch {
            // TODO: Better error handling
            print(error.localizedDescription)
        }
        return nil
    }

    @MainActor
    func getAssistants(limit: Int = 20, after: String? = nil) async -> [Assistant] {
        do {
            let response = try await openAIClient.assistants(query: nil, method: "GET", after: after)

            var assistants = [Assistant]()
            for result in response.data ?? [] {
                let codeInterpreter = result.tools?.filter { $0.type == "code_interpreter" }.first != nil
                let retrieval = result.tools?.filter { $0.type == "retrieval" }.first != nil
                let fileIds = result.fileIds ?? []

                assistants.append(Assistant(id: result.id, name: result.name, description: result.description, instructions: result.instructions, codeInterpreter: codeInterpreter, retrieval: retrieval, fileIds: fileIds))
            }
            if after == nil {
                availableAssistants = assistants
            }
            else {
                availableAssistants = availableAssistants + assistants
            }
            return assistants

        } catch {
            // TODO: Better error handling
            print(error.localizedDescription)
        }
        return []
    }

    func selectAssistant(_ assistantId: String?) {
        selectedAssistantId = assistantId
    }

    @MainActor
    func uploadFile(url: URL) async -> String? {
        do {
            let fileData = try Data(contentsOf: url)

            // TODO: Support all the same types as openAI (not just pdf).
            let result = try await openAIClient.files(query: FilesQuery(purpose: "assistants", file: fileData, fileName: url.lastPathComponent, contentType: "application/pdf"))
            return result.id
        }
        catch {
            print("error = \(error)")
            return nil
        }
    }

    @MainActor
    func getAllFiles() async {

            do {
                let files: AllFilesResult?

                files = try await openAIClient.getFiles(method: "GET")

            } catch {

            }

    }

    func createToolsArray(codeInterpreter: Bool, retrieval: Bool, functions: [ChatFunctionDeclaration]?) -> [Tool] {
        var tools = [Tool]()
        if codeInterpreter {
            tools.append(Tool(type: "code_interpreter", function: nil))
        }
        if retrieval {
            tools.append(Tool(type: "retrieval", function: nil))
        }

        if let functions = functions {
            functions.forEach { tools.append(Tool(type: "function", function: $0))}
        }

        return tools
    }
}
