//
//  CannotDiveView.swift
//  Trieste Watch App
//
//  Created by Jake Teton-Landis on 10/14/22.
//

import SwiftUI

struct CannotDiveView: View {
    var text: String
    var body: some View {
        VStack {
            Image(systemName: "water.waves.slash").resizable(resizingMode: .stretch).aspectRatio(contentMode: .fit).imageScale(.large).foregroundColor(.red)
            
            Text("Depth not available on this device").foregroundStyle(.red).padding()
        }
    }
}

struct CannotDiveView_Previews: PreviewProvider {
    static var previews: some View {
        CannotDiveView(text: "Depth not available")
    }
}
