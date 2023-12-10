//
//  ChatView.swift
//  DemoChat
//
//  Created by Sihao Lu on 3/25/23.
//

import Combine
import SwiftUI

public struct AssistantsView: View {
    @ObservedObject var store: ChatStore
    @ObservedObject var assistantStore: AssistantStore
    
    @Environment(\.dateProviderValue) var dateProvider
    @Environment(\.idProviderValue) var idProvider
    
    // state to select file
    @State private var isPickerPresented: Bool = false
    @State private var fileURL: URL?
    
    // state to modify assistant
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var customInstructions: String = ""
    @State private var fileIds: [String] = []
    
    @State private var codeInterpreter: Bool = false
    @State private var retrieval: Bool = false
    @State var isLoadingMore = false
    @State private var isModalPresented = false
    @State private var isUploading = false
    
    //If a file is selected via the document picker, this is set.
    @State var selectedFileURL: URL?
    @State var uploadedFileId: String?
    
    @State var mode: AssistantModalContentView.Mode = .create
    
    public init(store: ChatStore, assistantStore: AssistantStore) {
        self.store = store
        self.assistantStore = assistantStore
    }
    
    public var body: some View {
        ZStack {
            NavigationSplitView {
                AssistantsListView(
                    assistants: $assistantStore.availableAssistants, selectedAssistantId: Binding<String?>(
                        get: {
                            assistantStore.selectedAssistantId
                            
                        }, set: { newId in
                            guard newId != nil else { return }
                            
                            assistantStore.selectAssistant(newId)
                            
                            let selectedAssistant = assistantStore.availableAssistants.filter { $0.id == assistantStore.selectedAssistantId }.first
                            
                            name = selectedAssistant?.name ?? ""
                            description = selectedAssistant?.description ?? ""
                            customInstructions = selectedAssistant?.instructions ?? ""
                            codeInterpreter = selectedAssistant?.codeInterpreter ?? false
                            retrieval = selectedAssistant?.retrieval ?? false
                            fileIds = selectedAssistant?.fileIds ?? []
                            
                            mode = .modify
                            isModalPresented = true
                            
                        }), onLoadMoreAssistants: {
                            loadMoreAssistants()
                        }, isLoadingMore: $isLoadingMore
                )
                .toolbar {
                    ToolbarItem(
                        placement: .primaryAction
                    ) {
                        Menu {
                            Button("Get Assistants") {
                                Task {
                                    let _ = await assistantStore.getAssistants()
                                }
                            }
                            Button("Create Assistant") {
                                mode = .create
                                isModalPresented = true
                            }
                            Button("Get Files") {
                                Task {
                                    let _ = await assistantStore.getAllFiles()
                                }
                            }
                        } label: {
                            Image(systemName: "plus")
                        }
                        
                        .buttonStyle(.borderedProminent)
                    }
                }
            } detail: {
                
            }
            .sheet(isPresented: $isModalPresented, onDismiss: {
                resetAssistantCreator()
            }, content: {
                AssistantModalContentView(name: $name, description: $description, customInstructions: $customInstructions,
                                          codeInterpreter: $codeInterpreter, retrieval: $retrieval, fileIds: $fileIds, isUploading: $isUploading, modify: mode == .modify, isPickerPresented: $isPickerPresented, selectedFileURL: $selectedFileURL) {
                    Task {
                        await handleOKTap()
                    }
                } onFileUpload: {
                    Task {
                        guard let selectedFileURL  else { return }
                        
                        isUploading = true
                        uploadedFileId = await assistantStore.uploadFile(url: selectedFileURL)
                        isUploading = false
                        
                        if uploadedFileId == nil {
                            print("Failed to upload")
                            self.selectedFileURL = nil
                        }
                        else {
                            // if successful upload , we can show it.
                            if let uploadedFileId = uploadedFileId {
                                self.selectedFileURL = nil
                                
                                fileIds += [uploadedFileId]
                                
                                print("Successful upload!")
                            }
                        }
                    }
                }
            })
        }
    }
    
    func handleOKTap() async {
        // When OK is tapped that means we should save the modified assistant and start a new thread with it.
        var mergedFileIds = [String]()
        
        mergedFileIds += fileIds
        
        let asstId: String?
        
        if mode == .create {
            asstId = await assistantStore.createAssistant(name: name, description: description, instructions: customInstructions, codeInterpreter: codeInterpreter, retrievel: retrieval, fileIds: mergedFileIds.isEmpty ? nil : mergedFileIds)
        }
        // Modify
        else {
            guard let selectedAssistantId = assistantStore.selectedAssistantId else { return print("Cannot modify assistant, not selected.") }
            
            asstId = await assistantStore.modifyAssistant(asstId: selectedAssistantId, name: name, description: description, instructions: customInstructions, codeInterpreter: codeInterpreter, retrievel: retrieval, fileIds: mergedFileIds.isEmpty ? nil : mergedFileIds)
        }
        
        guard let asstId else {
            print("failed to create Assistant.")
            return
        }
        
        resetAssistantCreator()
        
        store.createConversation(type: .assistant, assistantId: asstId)
    }
    
    func loadMoreAssistants() {
        guard !isLoadingMore else { return }
        
        isLoadingMore = true
        let lastAssistantId = assistantStore.availableAssistants.last?.id ?? ""
        
        Task {
            // Fetch more assistants and append to the list
            let _ = await assistantStore.getAssistants(after: lastAssistantId)
            isLoadingMore = false
        }
    }
    
    func resetAssistantCreator() {
        // Reset state for Assistant creator.
        name = ""
        description = ""
        customInstructions = ""
        
        codeInterpreter = false
        retrieval = false
        selectedFileURL = nil
        uploadedFileId = nil
        fileIds = []
    }
}
