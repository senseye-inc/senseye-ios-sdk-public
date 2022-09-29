//
//  SwiftUIView.swift
//  
//
//  Created by Frank Oftring on 9/21/22.
//

import SwiftUI
import Combine
import CoreBluetooth

@available(iOS 15.0, *)
struct BluetoothDiscoveryView: View {
    @StateObject var viewModel: BluetoothDiscoveryViewModel
    @Environment(\.dismiss) var dismiss
    let bluetoothService: BluetoothService

    init(bluetoothService: BluetoothService) {
        _viewModel = StateObject(wrappedValue: BluetoothDiscoveryViewModel(bluetoothService: bluetoothService))
        self.bluetoothService = bluetoothService
    }

    var body: some View {
        ZStack {
            Color.senseyePrimary
                .edgesIgnoringSafeArea(.all)
            
            if bluetoothService.isDeviceConnected {
                ZStack {
                    HStack {
                        Text("Connected")
                        Image(systemName: "checkmark.circle.fill")
                    }
                    .font(.title)
                    .foregroundColor(.senseyeSecondary)
                }
            } else if viewModel.discoveredPeripheral == nil {
                ProgressView("Searching for devices…")
                    .progressViewStyle(.circular)
                    .foregroundColor(.senseyeSecondary)
                    .tint(.senseyeSecondary)
                    .padding(.top)
                
            } else {
                DeviceCardView()
                    .onTapGesture {
                        print("You tapped to connect to \(viewModel.discoveredPeripheral)")
                        viewModel.connect()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            dismiss()
                        }
                    }
            }
        }
    }
}
