// Create a new file called SettingsView.swift
import SwiftUI

struct SettingsView: View {
    @AppStorage("baseURL") private var baseURL = ""
    @AppStorage("modelName") private var modelName = "gpt-4"
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("OpenAI Configuration")) {
                    TextField("Base URL", text: $baseURL)
                    TextField("Model Name", text: $modelName)
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

#Preview {
    SettingsView()
}
