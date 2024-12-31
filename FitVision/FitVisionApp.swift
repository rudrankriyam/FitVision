//
//  FitVisionApp.swift
//  FitVision
//
//  Created by Rudrank Riyam on 12/31/24.
//

import SwiftUI
import HealthKit

@main
struct FitVisionApp: App {
    // Initialize HealthKit store
    let healthStore = HKHealthStore()

    @StateObject private var openAIManager: OpenAIManager = {
        let manager = OpenAIManager()
        // Try to get API key from keychain
        do {
            let apiKey = try KeychainManager.shared.getAPIKey()
            manager.configure(directAPIKey: apiKey)
        } catch {
            print("No API key found in keychain, waiting for user input")
        }
        return manager
    }()

    var body: some Scene {
        WindowGroup {
            ContentView(healthStore: healthStore)
                .environmentObject(openAIManager)
        }
    }
}
