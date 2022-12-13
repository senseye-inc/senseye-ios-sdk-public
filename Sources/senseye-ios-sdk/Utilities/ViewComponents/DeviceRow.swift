//
//  DeviceRow.swift
//  
//
//  Created by Frank Oftring on 9/26/22.
//

import Foundation
import SwiftUI
@available(iOS 14.0, *)
struct DeviceRow: View {
    var device: DiscoveredPeripheral

    var body: some View {
        VStack {
            Text("Device Found!")
                .foregroundColor(.senseyeTextColor)
                .font(.title)
            Text("Tap to connect")
                .foregroundColor(.senseyeTextColor)
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .frame(height: 50)
                    .foregroundColor(.senseyeSecondary)
                HStack {
                    Text("Connect to \(device.peripheral.name ?? "")")
                }
            }
        }
        .padding()
    }
}
