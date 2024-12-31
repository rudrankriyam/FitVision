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
    private var healthStore: HKHealthStore?

    init() {
        // Check if HealthKit is available on this device
        if HKHealthStore.isHealthDataAvailable() {
            healthStore = HKHealthStore()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(healthStore: healthStore)
        }
    }
}
