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
    @State private var showSettings = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Health Summary Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                            Text("Health Summary")
                                .font(.headline)
                            Spacer()
                        }

                        Text(healthData)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    .shadow(radius: 2, y: 1)

                    // Actions Section
                    VStack(spacing: 12) {
                        Button(action: {
                            requestHealthKitPermission()
                        }) {
                            HStack {
                                Image(systemName: "hand.raised.fill")
                                Text("Request Health Access")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }

                        Button(action: {
                            UIPasteboard.general.string = healthData
                            showAlert = true
                        }) {
                            HStack {
                                Image(systemName: "doc.on.doc.fill")
                                Text("Copy Health Data")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }

                    // Info Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text("How it works")
                                .font(.headline)
                            Spacer()
                        }

                        Text("FitVision helps you analyze your health data and get personalized recommendations for your fitness goals. Simply grant access to your health data and copy it to use with your favorite AI assistant.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(16)
                }
                .padding()
            }
            .navigationTitle("FitVision")
            .navigationBarItems(trailing: Button(action: {
                showSettings = true
            }) {
                Image(systemName: "gear")
            })
            .background(Color(uiColor: .systemGroupedBackground))
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Copied!"),
                message: Text("Health data copied to clipboard"),
                dismissButton: .default(Text("OK"))
            )
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
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.workoutType()
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
        guard let startDate = calendar.date(byAdding: .year, value: -1, to: endDate) else { return }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        var summaryText = "Health Data Summary (Last 365 Days):\n\n"
        let group = DispatchGroup()

        // Get all months between start and end date
        var months: [(start: Date, end: Date)] = []
        var currentDate = startDate

        while currentDate <= endDate {
            guard let monthEnd = calendar.date(byAdding: .month, value: 1, to: currentDate) else { break }
            let adjustedEnd = min(monthEnd, endDate)
            months.append((currentDate, adjustedEnd))
            currentDate = monthEnd
        }

        // Fetch data for each month
        for (monthStart, monthEnd) in months {
            group.enter()

            // Monthly metrics
            fetchMonthlyMetrics(healthStore: healthStore,
                              startDate: monthStart,
                              endDate: monthEnd,
                              formatter: formatter) { monthlyData in
                DispatchQueue.main.async {
                    summaryText += monthlyData
                }
                group.leave()
            }

            // Monthly workouts
            group.enter()
            fetchMonthlyWorkouts(healthStore: healthStore,
                               startDate: monthStart,
                               endDate: monthEnd,
                               formatter: formatter) { workoutData in
                DispatchQueue.main.async {
                    summaryText += workoutData
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            summaryText += "\nThis data can be used by AI to analyze your fitness patterns and suggest improvements for your New Year's resolutions."
            healthData = summaryText
        }
    }

    private func fetchMonthlyMetrics(healthStore: HKHealthStore,
                                    startDate: Date,
                                    endDate: Date,
                                    formatter: DateFormatter,
                                    completion: @escaping (String) -> Void) {
        let healthMetrics = [
            (type: HKQuantityType(.stepCount), unit: HKUnit.count(), name: "Steps"),
            (type: HKQuantityType(.activeEnergyBurned), unit: HKUnit.kilocalorie(), name: "Active Energy"),
            (type: HKQuantityType(.distanceWalkingRunning), unit: HKUnit.mile(), name: "Distance"),
            (type: HKQuantityType(.heartRate), unit: HKUnit.count().unitDivided(by: .minute()), name: "Avg Heart Rate")
        ]

        var monthText = "\n📅 \(formatter.string(from: startDate))\n"
        let metricsGroup = DispatchGroup()

        for metric in healthMetrics {
            metricsGroup.enter()
            let predicate = HKQuery.predicateForSamples(withStart: startDate,
                                                      end: endDate,
                                                      options: .strictStartDate)

            let options: HKStatisticsOptions = metric.type.identifier == HKQuantityTypeIdentifier.heartRate.rawValue
                ? .discreteAverage
                : .cumulativeSum

            let query = HKStatisticsQuery(
                quantityType: metric.type,
                quantitySamplePredicate: predicate,
                options: options
            ) { _, result, _ in
                defer { metricsGroup.leave() }

                if metric.type.identifier == HKQuantityTypeIdentifier.heartRate.rawValue {
                    if let average = result?.averageQuantity() {
                        let value = average.doubleValue(for: metric.unit)
                        DispatchQueue.main.async {
                            monthText += "\(metric.name): \(String(format: "%.2f", value)) \(metric.unit)\n"
                        }
                    }
                } else if let sum = result?.sumQuantity() {
                    let value = sum.doubleValue(for: metric.unit)
                    DispatchQueue.main.async {
                        monthText += "\(metric.name): \(String(format: "%.2f", value)) \(metric.unit)\n"
                    }
                }
            }

            healthStore.execute(query)
        }

        metricsGroup.notify(queue: .main) {
            completion(monthText)
        }
    }

    private func fetchMonthlyWorkouts(healthStore: HKHealthStore,
                                     startDate: Date,
                                     endDate: Date,
                                     formatter: DateFormatter,
                                     completion: @escaping (String) -> Void) {
        let workoutPredicate = HKQuery.predicateForSamples(withStart: startDate,
                                                          end: endDate,
                                                          options: .strictStartDate)
        let workoutSort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        let workoutQuery = HKSampleQuery(
            sampleType: .workoutType(),
            predicate: workoutPredicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [workoutSort]
        ) { _, samples, _ in
            guard let workouts = samples as? [HKWorkout] else {
                completion("")
                return
            }

            var workoutText = "\n🏃‍♂️ Workouts:\n"
            var workoutSummary: [String: (count: Int, duration: TimeInterval, calories: Double)] = [:]

            for workout in workouts {
                let type = workoutTypeToString(workout.workoutActivityType)
                let duration = workout.duration
                let calories = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0

                let current = workoutSummary[type] ?? (0, 0, 0)
                workoutSummary[type] = (current.count + 1,
                                       current.duration + duration,
                                       current.calories + calories)
            }

            for (type, stats) in workoutSummary {
                workoutText += "\n\(type):"
                workoutText += "\n  Sessions: \(stats.count)"
                workoutText += "\n  Total Duration: \(Int(stats.duration / 60)) minutes"
                workoutText += "\n  Total Calories Burned: \(String(format: "%.2f", stats.calories)) kcal"
            }

            completion(workoutText)
        }

        healthStore.execute(workoutQuery)
    }

    private func workoutTypeToString(_ workoutType: HKWorkoutActivityType) -> String {
        switch workoutType {
        case .running:
            return "Running"
        case .walking:
            return "Walking"
        case .cycling:
            return "Cycling"
        case .swimming:
            return "Swimming"
        case .yoga:
            return "Yoga"
        case .functionalStrengthTraining:
            return "Strength Training"
        case .hiking:
            return "Hiking"
        default:
            return "Other"
        }
    }
}
