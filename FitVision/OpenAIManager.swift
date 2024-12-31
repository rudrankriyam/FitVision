// Create a new file called OpenAIManager.swift
import Foundation
import OpenAI

class OpenAIManager: ObservableObject {
    @Published var isLoading = false
    private var client: OpenAI?

    func configureClient(baseURL: String) {
        guard let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] else {
            print("OpenAI API key not found")
            return
        }

        var configuration = OpenAI.Configuration(apiKey: apiKey)
        if !baseURL.isEmpty {
            configuration.baseURL = baseURL
        }

        client = OpenAI(configuration: configuration)
    }

    func analyzeHealthData(_ healthData: String, modelName: String) async throws -> String {
        guard let client = client else {
            throw NSError(domain: "OpenAIManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "OpenAI client not configured"])
        }

        isLoading = true
        defer { isLoading = false }

        let query = ChatQuery(model: .init(modelName), messages: [
            .init(role: .system, content: "You are a health and fitness expert."),
            .init(role: .user, content: "Please analyze this health data and provide insights: \n\n\(healthData)")
        ])

        let response = try await client.chats(query: query)
        return response.choices.first?.message.content ?? "No analysis available"
    }
}
