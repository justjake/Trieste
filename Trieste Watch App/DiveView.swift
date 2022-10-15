//
//  DiveView.swift
//  Trieste Watch App
//
//  Created by Jake Teton-Landis on 10/14/22.
//

import SwiftUI
import CoreMotion
import HealthKit

// States:
// Surface/Idle
// Surface/Idle.hasPreviousDive (-> go to Submerged/Complete)
// Submerged/Diving    (depth > 0, depth < 140ft)
// Sumberged/PastLimit (depth > 140ft)
// Surface/Complete
struct DiveView: View {
    enum DiveState {
        case surface, submerged(dive: Dive), complete(dive: Dive, viewing: Bool = false)
    }
    
    @State var state: DiveState = .surface
    @State var submersionEvent: SubmersionEvent? = nil
    @State var depth: SubmersionMeasurement? = nil
    @State var temperature: WaterTemperature? = nil
    @State var error: Error? = nil
    @State var maxDepth: Measurement<UnitLength> = Measurement(value: 0, unit: .feet)
    
    @State var viewingPreviousDive: Bool = false
    @State var diveWorkout: DiveWorkout? = nil
    
    init(submersionEvent: SubmersionEvent? = nil, depth: SubmersionMeasurement? = nil, temperature: WaterTemperature? = nil, error: Error? = nil, maxDepth: Measurement<UnitLength>? = Measurement(value: 0, unit: .feet)) {
        self.submersionEvent = submersionEvent
        self.depth = depth
        self.temperature = temperature
        self.error = error
        if let initialMaxDepth = maxDepth {
            self.maxDepth = initialMaxDepth
        }
        
        self.diveCoordinator.setParent(to: self)
    }
    
    var body: some View {
        switch state {
        case .surface, .complete:
            VStack {
                Image(systemName: "water.waves.and.arrow.down").foregroundColor(.accentColor).imageScale(.large)
                Text("To start a dive, submerge Apple Watch").multilineTextAlignment(.center).padding(15)
                if (diveWorkout == nil) {
                    Button("Dive") {
                        self.diveCoordinator.startWorkout()
                    }

                } else {
                    endWorkoutButton
                }
                if case .complete(let dive, _) = state {
                    Button("View previous dive", action: { () -> Void in
                        self.state = .complete(dive: dive, viewing: true)
                    }).actionSheet(isPresented: $viewingPreviousDive) {
                        ActionSheet(
                            title: Text("Previous Dive"),
                            message: Text("Pretend we show a bunch of dive metrics here."),
                            buttons: [
                                .cancel(Text("Close"))
                            ]
                        )
                    }
                }
            }
        case .submerged(let dive):
            VStack {
                Text("Submerged at: " + formatter().string(from: dive.startedAt))
                self.endWorkoutButton
            }
            
            
        }
    }
    
    var endWorkoutButton: some View {
        Button("End", role: .destructive) {
            guard let dive2 = diveWorkout else {
                print("Can't end, no dive workout")
                return
            }
            
            let session = dive2.session
            let builder = dive2.builder
            session.end()
            builder.endCollection(withEnd: Date()) { (success, error) in
                
                guard success else {
                    print("End collection error:", error as Any)
                    self.error = error
                    return
                }
                
                builder.finishWorkout { (workout, error) in
                    
                    guard workout != nil else {
                        // Handle errors.
                        print("Finish workout error:", error as Any)
                        self.error = error
                        return
                    }
                    
                    DispatchQueue.main.async() {
                        // Update the user interface.
                    }
                }
            }
            
            
            self.diveWorkout = nil
        }
    }
    
    var diveCoordinator: DiveCoordinator = DiveCoordinator()
    
    func isSubmerged() -> Bool {
        return self.submersionEvent?.state == .submerged
    }
    
    func formatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .full
        return formatter
    }
}

struct DiveView_Previews: PreviewProvider {
    static var previews: some View {
        DiveView()
    }
}

struct DiveLog {
    var dives: [Dive]
}

struct Dive {
    let startedAt: Date
    var endedAt: Date?
    var depthLog: [SubmersionMeasurement] = []
    var tempretureLog: [WaterTemperature] = []
}

struct DiveWorkout {
    var session: HKWorkoutSession
    var builder: HKLiveWorkoutBuilder
}

// Re-implement CoreMotion events so we can create mock ones easily.
struct SubmersionEvent {
    enum State {
        case unknown, notSubmerged, submerged
        
        static func fromCoreMotion(state: CMWaterSubmersionEvent.State) -> State {
            switch state {
            case .notSubmerged:
                return .notSubmerged
            case .submerged:
                return .submerged
            case .unknown:
                return .unknown
            @unknown default:
                return .unknown
            }
        }
    }
    
    let date: Date
    let state: State
    
    static func fromCoreMotion(event: CMWaterSubmersionEvent) -> SubmersionEvent {
        return SubmersionEvent(
            date: event.date, state: State.fromCoreMotion(state: event.state)
        )
        
    }
}

struct SubmersionMeasurement {
    var date: Date
    var depth: Measurement<UnitLength>?
    var pressure: Measurement<UnitPressure>?
    var surfacePressure: Measurement<UnitPressure>
    var submersionState: CMWaterSubmersionMeasurement.DepthState
    
    static func fromCoreMotion(measure: CMWaterSubmersionMeasurement) ->  SubmersionMeasurement {
        return SubmersionMeasurement(
            date: measure.date,
            depth: measure.depth,
            pressure: measure.pressure,
            surfacePressure: measure.surfacePressure,
            submersionState: measure.submersionState
        )
    }
}

struct WaterTemperature {
    let date: Date
    let temperature: Measurement<UnitTemperature>
    let temperatureUncertainty: Measurement<UnitTemperature>
    
    static func fromCoreMotion(measure: CMWaterTemperature) -> WaterTemperature {
        return WaterTemperature(date: measure.date, temperature: measure.temperature, temperatureUncertainty: measure.temperatureUncertainty)
    }
}


