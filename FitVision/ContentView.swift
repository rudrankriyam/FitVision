//
//  ContentView.swift
//  FitVision
//
//  Created by Rudrank Riyam on 12/31/24.
//

import SwiftUI
import HealthKit

struct ContentView: View {
    let healthStore: HKHealthStore?
    @State private var healthData: String = "No health data available"
    @State private var showAlert = false

    var body: some View {
        VStack(spacing: 20) {
            Text("FitVision")
                .font(.largeTitle)
                .bold()

            Text(healthData)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)

            Button(action: {
                requestHealthKitPermission()
            }) {
                Text("Request Health Access")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            Button(action: {
                UIPasteboard.general.string = healthData
                showAlert = true
            }) {
                Text("Copy Health Data")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Copied!"),
                  message: Text("Health data copied to clipboard"),
                  dismissButton: .default(Text("OK")))
        }
    }

    private func requestHealthKitPermission() {
        guard let healthStore = healthStore else {
            healthData = "HealthKit is not available on this device"
            return
        }

        // Define the types of data we want to read
        let healthTypes: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
        ]

        // Request authorization
        healthStore.requestAuthorization(toShare: nil, read: healthTypes) { success, error in
            if success {
                fetchHealthData(healthStore: healthStore)
            } else {
                DispatchQueue.main.async {
                    healthData = "Failed to get permission: \(error?.localizedDescription ?? "Unknown error")"
                }
            }
        }
    }

    private func fetchHealthData(healthStore: HKHealthStore) {
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -7, to: endDate) else { return }

        let healthMetrics = [
            (type: HKQuantityType(.stepCount), unit: HKUnit.count(), name: "Steps"),
            (type: HKQuantityType(.activeEnergyBurned), unit: HKUnit.kilocalorie(), name: "Active Energy"),
            (type: HKQuantityType(.distanceWalkingRunning), unit: HKUnit.mile(), name: "Distance")
        ]

        var summaryText = "Health Data Summary (Last 7 Days):\n\n"
        let group = DispatchGroup()

        for metric in healthMetrics {
            group.enter()

            let predicate = HKQuery.predicateForSamples(
                withStart: startDate,
                end: endDate,
                options: .strictStartDate
            )

            let query = HKStatisticsQuery(
                quantityType: metric.type,
                quantitySamplePredicate: predicate,
                options: [.cumulativeSum]
            ) { _, result, error in
                defer { group.leave() }

                if let sum = result?.sumQuantity() {
                    let value = sum.doubleValue(for: metric.unit)
                    DispatchQueue.main.async {
                        summaryText += "\(metric.name): \(String(format: "%.2f", value)) \(metric.unit)\n"
                    }
                }
            }

            healthStore.execute(query)
        }

        group.notify(queue: .main) {
            summaryText += "\nThis data can be used by AI to analyze your fitness patterns and suggest improvements for your New Year's resolutions."
            healthData = summaryText
        }
    }
}
