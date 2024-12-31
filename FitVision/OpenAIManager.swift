import Foundation
import AIProxy

class OpenAIManager: ObservableObject {
    @Published var isLoading = false
    @Published var response: String = ""

    private var openAIService: OpenAIService?

    func configureClient(baseURL: String) {
        guard let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] else {
            print("OpenAI API key not found")
            return
        }

        configure(directAPIKey: apiKey, partialKey: nil, serviceURL: baseURL)
    }

    func configure(directAPIKey: String? = nil, partialKey: String? = nil, serviceURL: String? = nil) {
        if let apiKey = directAPIKey {
            openAIService = AIProxy.openAIDirectService(unprotectedAPIKey: apiKey)
        } else if let partialKey = partialKey, let serviceURL = serviceURL {
            openAIService = AIProxy.openAIService(partialKey: partialKey, serviceURL: serviceURL)
        }
    }

    func analyzeHealthData(_ healthData: String, modelName: String) async throws -> String {
        guard let service = openAIService else {
            throw NSError(domain: "OpenAIManager", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "OpenAI service not configured"])
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let requestBody = OpenAIChatCompletionRequestBody(
                model: modelName,
                messages: [
                    .system(content: .text("You are a health and fitness expert.")),
                    .user(content: .text("Please analyze this health data and provide insights: \n\n\(healthData)"))
                ],
                temperature: 0.7
            )

            let response = try await service.chatCompletionRequest(body: requestBody)

            return response.choices.first?.message.content ?? "No analysis available"
        } catch AIProxyError.unsuccessfulRequest(let statusCode, let responseBody) {
            throw NSError(domain: "OpenAIManager", code: Int(statusCode),
                         userInfo: [NSLocalizedDescriptionKey: "API Error: \(responseBody)"])
        } catch {
            throw NSError(domain: "OpenAIManager", code: -2,
                         userInfo: [NSLocalizedDescriptionKey: "Could not create chat completion: \(error.localizedDescription)"])
        }
    }
}
