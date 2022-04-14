//
//  ContentView.swift
//  Shared
//
//  Created by Frank Oftring on 4/12/22.
//

import SwiftUI

@available(iOS 13.0, *)
struct ProcessingScreen: View {
    var body: some View {
        ZStack {
            Color.senseyePrimary
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                HeaderView()
                Spacer()
                Image(systemName: "gearshape.fill")
                    .resizable()
                    .frame(width: 121, height: 116)
                    .foregroundColor(.senseyeSecondary)
                    .padding()
                Text("senseye orm check results are processing".uppercased())
                    .foregroundColor(.senseyeTextColor)
                    .lineLimit(1)
                    .font(.caption)
                
                Spacer()
            }
        }
    }
}


@available(iOS 13.0, *)
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ProcessingScreen()
    }
}
