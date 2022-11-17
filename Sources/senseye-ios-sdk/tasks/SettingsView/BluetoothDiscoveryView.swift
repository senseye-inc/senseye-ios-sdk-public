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

    init(bluetoothService: BluetoothService, fileUploadService: FileUploadAndPredictionService) {
        _viewModel = StateObject(wrappedValue: BluetoothDiscoveryViewModel(bluetoothService: bluetoothService, fileUploadService: fileUploadService))
        self.bluetoothService = bluetoothService
    }

    var body: some View {
        ZStack {
            Color.senseyePrimary
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                HeaderView()
                    .padding() // padding used here since this view is presented modally. All other HeaderView's are without padding
                Spacer()
                if bluetoothService.isDeviceConnected {
                    ZStack {
                        HStack {
                            Text(Strings.connectedTitle)
                            Image(systemName: "checkmark.circle.fill")
                        }
                        .font(.title)
                        .foregroundColor(.senseyeSecondary)
                    }
                } else if viewModel.discoveredPeripheral == nil {
                    ProgressView(Strings.searchingForDevices)
                        .progressViewStyle(.circular)
                        .foregroundColor(.senseyeSecondary)
                        .tint(.senseyeSecondary)
                        .padding(.top)
                    
                } else {
                    DeviceCardView()
                        .onTapGesture {
                            Log.info("Attempting to connect to \(String(describing: viewModel.discoveredPeripheral))")
                            viewModel.connect()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                dismiss()
                            }
                        }
                }
                Spacer()
            }
        }
        .onAppear {
            viewModel.reconnectToLastPeripheral()
        }
    }
}
