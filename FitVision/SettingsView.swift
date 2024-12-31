// Create a new file called SettingsView.swift
import SwiftUI

struct SettingsView: View {
  //  @AppStorage("baseURL") private var baseURL = ""
    @AppStorage("useDirectAPI") private var useDirectAPI = false
    @AppStorage("modelName") private var modelName = "gpt-4"
    @State private var apiKey = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var openAIManager: OpenAIManager

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("OpenAI Configuration")) {
                    Toggle("Use Direct API", isOn: $useDirectAPI)

                    if useDirectAPI {
                        SecureField("API Key", text: $apiKey)
                            .textContentType(.password)
                            .autocorrectionDisabled()
                            .onAppear {
                                loadAPIKey()
                            }
                    }

                    TextField("Model Name", text: $modelName)
                        .autocorrectionDisabled()
                }

                Button("Apply Changes") {
                    saveSettings()
                }
                .disabled(useDirectAPI && apiKey.isEmpty)
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
            .alert("Settings", isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func loadAPIKey() {
        do {
            apiKey = try KeychainManager.shared.getAPIKey()
        } catch {
            print("No API key found in keychain")
        }
    }

    private func saveSettings() {
        do {
            if useDirectAPI {
                try KeychainManager.shared.saveAPIKey(apiKey)
                openAIManager.configure(directAPIKey: apiKey)
            } else {
                try KeychainManager.shared.deleteAPIKey()
                openAIManager.configure(directAPIKey: nil)
            }
            alertMessage = "Settings saved successfully"
        } catch {
            alertMessage = "Failed to save settings: \(error.localizedDescription)"
        }
        showAlert = true
    }
}
