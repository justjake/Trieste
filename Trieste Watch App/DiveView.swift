//
//  DiveView.swift
//  Trieste Watch App
//
//  Created by Jake Teton-Landis on 10/14/22.
//

import SwiftUI
import CoreMotion

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
    
    
    init(submersionEvent: SubmersionEvent? = nil, depth: SubmersionMeasurement? = nil, temperature: WaterTemperature? = nil, error: Error? = nil, maxDepth: Measurement<UnitLength>? = Measurement(value: 0, unit: .feet)) {
        self.submersionEvent = submersionEvent
        self.depth = depth
        self.temperature = temperature
        self.error = error
        if let initialMaxDepth = maxDepth {
            self.maxDepth = initialMaxDepth
        }
        
        self.diveCoordinator.setParent(to: self)
        self.diveCoordinator.startWorkout()
    }
    
    var body: some View {
        switch state {
        case .surface, .complete:
            VStack {
                Image(systemName: "water.waves.and.arrow.down").foregroundColor(.accentColor).imageScale(.large)
                Text("To start a dive, submerge Apple Watch").multilineTextAlignment(.center).padding(15)
                Button("Dive") {
                    let interface = WKInterfaceDevice.current()
                    interface.enableWaterLock()
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
        case .submerged:
            VStack {
                
            }
            
            
        }
    }
    
    var diveCoordinator: DiveCoordinator = DiveCoordinator()
    
    func isSubmerged() -> Bool {
        return self.submersionEvent?.state == .submerged
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


