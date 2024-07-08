//
//  ContentView.swift
//  HealthKitReader
//
//  Created by Oscar W. on 7/7/24.
//

import SwiftUI
import HealthKit

class HealthManager: ObservableObject {
    private let healthStore = HKHealthStore()
    
    @Published var steps: Double = 0
    
    init() {
        requestAuthorization()
    }
    
    func requestAuthorization() {
        if HKHealthStore.isHealthDataAvailable() {
            let allTypes = Set([
                HKObjectType.quantityType(forIdentifier: .stepCount)!,
                // 添加其他你需要的类型
            ])
            
            healthStore.requestAuthorization(toShare: allTypes, read: allTypes) { (success, error) in
                if success {
                    self.fetchSteps()
                } else {
                    print("Authorization failed")
                }
            }
        }
    }
    
    func fetchSteps() {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            print("Step Count type is no longer available in HealthKit")
            return
        }
        
        let startDate = Calendar.current.startOfDay(for: Date())
        let endDate = Date()
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { (_, result, error) in
            var resultCount = 0.0
            
            guard let result = result else {
                print("Failed to fetch steps = \(error?.localizedDescription ?? "N/A")")
                return
            }
            
            if let sum = result.sumQuantity() {
                resultCount = sum.doubleValue(for: HKUnit.count())
            }
            
            DispatchQueue.main.async {
                self.steps = resultCount
            }
        }
        
        healthStore.execute(query)
    }
}

struct ContentView: View {
    @StateObject private var healthManager = HealthManager()
    
    var body: some View {
        VStack {
            Image(systemName: "figure.walk")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Steps today: \(healthManager.steps, specifier: "%.0f")")
                .font(.title)
        }
        .padding()
        .onAppear {
            healthManager.fetchSteps()
        }
    }
}

#Preview {
    ContentView()
}
