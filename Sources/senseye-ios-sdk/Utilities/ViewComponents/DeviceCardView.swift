//
//  DeviceRow.swift
//  
//
//  Created by Frank Oftring on 9/26/22.
//

import SwiftUI

@available(iOS 14.0, *)
struct DeviceCardView: View {

    var body: some View {
        ZStack {
            Color.senseyePrimary
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.senseyePrimary)
                        .padding()
                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 20)
                        .shadow(color: Color.black.opacity(0.7), radius: 10, x: 0, y: 5)
                    VStack(spacing: 50) {
                        Image(systemName: "checkmark.circle.fill")
                            .resizable()
                            .foregroundColor(.senseyeTextColor)
                            .frame(width: 91, height: 91)

                        Text("Found BerryMed Device")
                            .foregroundColor(.senseyeTextColor)
                            .multilineTextAlignment(.center)
                        
                        SenseyeButton(text: "Tap to Connect", foregroundColor: .senseyePrimary, fillColor: .senseyeSecondary)
                    }
                }
            }
            .frame(width: 350, height: 450)
        }
    }
}
