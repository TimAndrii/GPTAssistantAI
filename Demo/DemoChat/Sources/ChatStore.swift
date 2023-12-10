//
//  ChatStore.swift
//  DemoChat
//
//  Created by Sihao Lu on 3/25/23.
//

import Foundation
import Combine
import OpenAI
import SwiftUI

public final class ChatStore: ObservableObject {
    public var openAIClient: OpenAIProtocol
    let idProvider: () -> String

    @Published var conversations: [Conversation] = []
    @Published var conversationErrors: [Conversation.ID: Error] = [:]
    @Published var selectedConversationID: Conversation.ID?

    // Used for assistants API state.
    private var timer: Timer?
    private var timeInterval: TimeInterval = 1.0
    private var currentRunId: String?
    private var currentThreadId: String?
    private var currentConversationId: String?
    private var userMassage: MessageModel?

    @Published var isSendingMessage = false

    var selectedConversation: Conversation? {
        selectedConversationID.flatMap { id in
            conversations.first { $0.id == id }
        }
    }

    var selectedConversationPublisher: AnyPublisher<Conversation?, Never> {
        $selectedConversationID.receive(on: RunLoop.main).map { id in
            self.conversations.first(where: { $0.id == id })
        }
        .eraseToAnyPublisher()
    }

    public init(
        openAIClient: OpenAIProtocol,
        idProvider: @escaping () -> String
    ) {
        self.openAIClient = openAIClient
        self.idProvider = idProvider
    }

    // MARK: - Events
    func createConversation(type: ConversationType = .normal, assistantId: String? = nil) {
        let conversation = Conversation(id: idProvider(), messages: [], type: type, assistantId: assistantId)
        conversations.append(conversation)
    }

    func selectConversation(_ conversationId: Conversation.ID?) {
        selectedConversationID = conversationId
    }

    func deleteConversation(_ conversationId: Conversation.ID) {
        conversations.removeAll(where: { $0.id == conversationId })
    }

    @MainActor
    func sendMessage(
        _ message: MessageModel,
        conversationId: Conversation.ID,
        model: Model
    ) async {
        guard let conversationIndex = conversations.firstIndex(where: { $0.id == conversationId }) else {
            return
        }

        switch conversations[conversationIndex].type  {
        case .normal:
            conversations[conversationIndex].messages.append(message)

            await completeChat(
                conversationId: conversationId,
                model: model
            )
        // For assistant case we send chats to thread and then poll, polling will receive sent chat + new assistant messages.
        case .assistant:
            userMassage = message
            // First message in an assistant thread.
            if conversations[conversationIndex].messages.count == 0 {

                var localMessage = message
                localMessage.isLocal = true
                conversations[conversationIndex].messages.append(localMessage)

                do {
                    let threadsQuery = ThreadsQuery(messages: [])
                    let threadsResult = try await openAIClient.threads(query: threadsQuery)

                    guard let currentAssistantId = conversations[conversationIndex].assistantId else { return print("No assistant selected.")}

                    let runsQuery = RunsQuery(assistantId:  currentAssistantId)
                    let runsResult = try await openAIClient.runs(threadId: threadsResult.id, query: runsQuery)

                    // check in on the run every time the poller gets hit.
                    startPolling(conversationId: conversationId, runId: runsResult.id, threadId: threadsResult.id)
                }
                catch {
                    print("error: \(error) creating thread w/ message")
                }
            }
            // Subsequent messages on the assistant thread.
            else {

                var localMessage = message
                localMessage.isLocal = true
                conversations[conversationIndex].messages.append(localMessage)

                do {
                    guard let currentThreadId else { return print("No thread to add message to.")}

                    let _ = try await openAIClient.threadsAddMessage(threadId: currentThreadId,
                                                                     query: ThreadAddMessageQuery(role: message.role.rawValue, content: message.content))

                    guard let currentAssistantId = conversations[conversationIndex].assistantId else { return print("No assistant selected.")}

                    let runsQuery = RunsQuery(assistantId: currentAssistantId)
                    let runsResult = try await openAIClient.runs(threadId: currentThreadId, query: runsQuery)

                    // check in on the run every time the poller gets hit.
                    startPolling(conversationId: conversationId, runId: runsResult.id, threadId: currentThreadId)
                }
                catch {
                    print("error: \(error) adding to thread w/ message")
                }
            }
        }
    }

    @MainActor
    func completeChat(
        conversationId: Conversation.ID,
        model: Model
    ) async {
        guard let conversation = conversations.first(where: { $0.id == conversationId }) else {
            return
        }

        conversationErrors[conversationId] = nil

        do {
            guard let conversationIndex = conversations.firstIndex(where: { $0.id == conversationId }) else {
                return
            }

            let weatherFunction = ChatFunctionDeclaration(
                name: "getWeatherData",
                description: "Get the current weather in a given location",
                parameters: .init(
                    type: .object,
                    properties: [
                        "location": .init(type: .string, description: "The city and state, e.g. San Francisco, CA")
                    ],
                    required: ["location"]
                )
            )

            let functions = [weatherFunction]

            let chatsStream: AsyncThrowingStream<ChatStreamResult, Error> = openAIClient.chatsStream(
                query: ChatQuery(
                    model: model,
                    messages: conversation.messages.map { message in
                        Message(role: message.role, content: .string(message.content))
                    },
                    functions: functions
                )
            )

            var functionCallName = ""
            var functionCallArguments = ""
            for try await partialChatResult in chatsStream {
                for choice in partialChatResult.choices {
                    let existingMessages = conversations[conversationIndex].messages
                    // Function calls are also streamed, so we need to accumulate.
                    if let functionCallDelta = choice.delta.functionCall {
                        if let nameDelta = functionCallDelta.name {
                            functionCallName += nameDelta
                        }
                        if let argumentsDelta = functionCallDelta.arguments {
                            functionCallArguments += argumentsDelta
                        }
                    }
                    var messageText = choice.delta.content ?? ""
                    if let finishReason = choice.finishReason,
                       finishReason == "function_call" {
                        messageText += "Function call: name=\(functionCallName) arguments=\(functionCallArguments)"
                    }
                    let message = MessageModel(
                        id: partialChatResult.id,
                        role: choice.delta.role ?? .assistant,
                        content: messageText,
                        createdAt: Date(timeIntervalSince1970: TimeInterval(partialChatResult.created))
                    )
                    if let existingMessageIndex = existingMessages.firstIndex(where: { $0.id == partialChatResult.id }) {
                        // Meld into previous message
                        let previousMessage = existingMessages[existingMessageIndex]
                        let combinedMessage = MessageModel(
                            id: message.id, // id stays the same for different deltas
                            role: message.role,
                            content: previousMessage.content + message.content,
                            createdAt: message.createdAt
                        )
                        conversations[conversationIndex].messages[existingMessageIndex] = combinedMessage
                    } else {
                        conversations[conversationIndex].messages.append(message)
                    }
                }
            }
        } catch {
            conversationErrors[conversationId] = error
        }
    }

    // Start Polling section
    func startPolling(conversationId: Conversation.ID, runId: String, threadId: String) {
        currentRunId = runId
        currentThreadId = threadId
        currentConversationId = conversationId
        isSendingMessage = true
        timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.timerFired()
            }
        }
    }

    func stopPolling() {
        isSendingMessage = false
        timer?.invalidate()
        timer = nil
    }

    private func timerFired() {
        guard let conversationIndex = conversations.firstIndex(where: { $0.id == currentConversationId }) else {
            return
        }

        Task {
            let result = try await openAIClient.runRetrieve(threadId: currentThreadId ?? "", runId: currentRunId ?? "")

            switch result.status {
            // Get threadsMesages.
            case "requires_action":
                    guard let currentThreadId, let currentRunId else { return }
                    let stepsResult = try await openAIClient.stepsRetrieve(threadId: currentThreadId, runId: currentRunId)
                    
                    let toolID = stepsResult.data?.first?.stepDetails?.toolCalls?.first

                    let sumbitQuery = SubmitToolQuery(toolOutputs: [ToolOutputs(toolCallId: toolID?.id, output: "Say to user: Wazzap Man?")])
                    let _ = try await openAIClient.runSubmitTool(threadId: currentThreadId, runId: currentRunId, query: sumbitQuery)
            case "completed":
                DispatchQueue.main.async {
                    self.stopPolling()
                }
                var before: String?
                if let lastNonLocalMessage = self.conversations[conversationIndex].messages.last(where: { $0.isLocal == false }) {
                    before = lastNonLocalMessage.id
                }

                let result = try await openAIClient.threadsMessages(threadId: currentThreadId ?? "", before: "")

                DispatchQueue.main.async {
                    for item in result.data.reversed() {
                        let role = item.role
                        for innerItem in item.content {
                            let message = MessageModel(
                                id: item.id,
                                role: Message.Role(rawValue: role) ?? .user,
                                content: innerItem.text.value,
                                createdAt: Date(),
                                isLocal: false // Messages from the server are not local
                            )
                            // Check if this message from the API matches a local message
                            if let localMessageIndex = self.conversations[conversationIndex].messages.firstIndex(where: { $0.isLocal == true }) {
                                
                                // Replace the local message with the API message
                                self.conversations[conversationIndex].messages[localMessageIndex] = message
                            } else {
                                // This is a new message from the server, append it

                                self.conversations[conversationIndex].messages.append(message)
                            }
                        }
                    }
                }
                break
            case "failed":
                DispatchQueue.main.async {

                    self.stopPolling()
                }
                break
            default:
                break
            }
        }
    }
    // END Polling section
}
