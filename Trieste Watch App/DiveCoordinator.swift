//
//  DiveCoordinator.swift
//  Trieste Watch App
//
//  Created by Jake Teton-Landis on 10/14/22.
//

import Foundation
import CoreMotion
import HealthKit
import WatchKit

class DiveCoordinator: NSObject, CMWaterSubmersionManagerDelegate, HKLiveWorkoutBuilderDelegate {
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        // TODO
        collectedTypes.forEach { sample in
            print("HK sample data:", sample)
        }
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // TODO
    }
    
    var parent: DiveView?
    var manager: CMWaterSubmersionManager = CMWaterSubmersionManager()
    let healthStore: HKHealthStore = HKHealthStore()

    func setParent(to: DiveView) {
        self.parent = to
        self.manager.delegate = self
    }
    
    func manager(_ manager: CMWaterSubmersionManager, didUpdate event: CMWaterSubmersionEvent) {
        let event = SubmersionEvent.fromCoreMotion(event: event)
        self.parent?.submersionEvent = event
        print("Submersion:", event)
        
        switch (self.parent?.state, event.state) {
        case (.surface, .submerged), (.complete, .submerged):
            self.parent?.state = .submerged(dive: Dive(startedAt: event.date))
        case (.submerged(var dive), .notSubmerged):
            dive.endedAt = event.date
            self.parent?.state = .complete(dive: dive)
        default: break
        }
    }
    
    func manager(_ manager: CMWaterSubmersionManager, didUpdate measurement: CMWaterSubmersionMeasurement) {
        print("Submersion measurement", measurement)
        switch self.parent?.state {
        case .some(.submerged(var dive)):
            dive.depthLog.append(SubmersionMeasurement.fromCoreMotion(measure: measurement))
        default: break
        }
    }
    
    func manager(_ manager: CMWaterSubmersionManager, didUpdate measurement: CMWaterTemperature) {
        print("Water tempreture:", measurement)
        switch self.parent?.state {
        case .some(.submerged(var dive)):
            dive.tempretureLog.append(WaterTemperature.fromCoreMotion(measure: measurement))
        default: break
        }
    }
    
    func manager(_ manager: CMWaterSubmersionManager, errorOccurred error: Error) {
        print("Submersion error:", error)
        self.parent?.error = error
    }
    
    func startWorkout() {
        // The quantity type to write to the health store.
        let typesToShare: Set = [
            HKQuantityType.workoutType()
        ]

        // The quantity types to read from the health store.
        let typesToRead: Set = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .oxygenSaturation)!,
            HKQuantityType.quantityType(forIdentifier: .distanceSwimming)!,
        ]

        // Request authorization for those quantity types.
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { (success, error) in
            guard success else {
                self.parent?.error = error
                return
            }
        }
        
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .swimming
        workoutConfiguration.locationType = .outdoor
        workoutConfiguration.swimmingLocationType = .openWater
        
        do {
            let session = try HKWorkoutSession(healthStore: healthStore, configuration: workoutConfiguration)
            let builder = session.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: workoutConfiguration)
            builder.delegate = self
            
            session.startActivity(with: Date())
            builder.beginCollection(withStart: Date()) { (success, error) in
                
                guard success else {
                    self.parent?.error = error
                    return
                }
                
                // Indicate that the session has started.
            }
            
            WKInterfaceDevice.current().enableWaterLock()
            self.parent?.diveWorkout = DiveWorkout(session: session, builder: builder)
        } catch  {
            self.parent?.error = error
        }
    }
}
