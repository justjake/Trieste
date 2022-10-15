//
//  ContentView.swift
//  Trieste Watch App
//
//  Created by Jake Teton-Landis on 10/14/22.
//

import SwiftUI
import CoreMotion

struct ContentView: View {
    var body: some View {
        if (!CMWaterSubmersionManager.waterSubmersionAvailable) {
            CannotDiveView(text: "Depth not available on this device")
        } else {
            switch(CMWaterSubmersionManager.authorizationStatus) {
            case .notDetermined: DiveView()
            case .authorized: DiveView()
            case .denied: CannotDiveView(text: "You don't allow access to depth")
            case .restricted: CannotDiveView(text: "Access to depth restricted by system")
            @unknown default: DiveView()
                
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewDevice("Apple Watch Ultra (49mm)")
    }
}
