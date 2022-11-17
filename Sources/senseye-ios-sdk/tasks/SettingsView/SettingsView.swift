//
//  SettingsView.swift
//  
//
//  Created by Frank Oftring on 9/19/22.
//

import SwiftUI

@available(iOS 15.0, *)
struct SettingsView: View {
    
    @StateObject var viewModel = SettingsViewModel()
    @EnvironmentObject var tabController: TabController
    @EnvironmentObject var bluetoothService: BluetoothService
    @EnvironmentObject var fileUploadService: FileUploadAndPredictionService
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.senseyePrimary
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.senseyeTextColor)
                            .padding(.bottom, 100)
                    }
                    Spacer()
                }
                BluetoothSettingsRow(title: Strings.bluetoothTitle, description: "", isDeviceConnected: $bluetoothService.isDeviceConnected, isShowingBluetooth: $viewModel.isShowingBluetooth)
                LanguageRowView(title: "Language", selectedLanguage: viewModel.selectedLanguage)
                Spacer()
            }
            .padding()
        }
        .sheet(isPresented: $viewModel.isShowingBluetooth) {
            BluetoothDiscoveryView(bluetoothService: bluetoothService, fileUploadService: fileUploadService)
        }
    }
}

@available(iOS 14.0, *)
struct SettingsRow: View {
    
    @Binding var isOn: Bool
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.title2)
                        .lineLimit(1)
                    Text(description)
                        .font(.caption)
                }
                
                Toggle("", isOn: $isOn)
            }
            .foregroundColor(.senseyeTextColor)
        }
    }
}

struct LanguageRowView: View {
    
    let title: String
    let selectedLanguage: String
    
    var body: some View {
            Button {
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            } label: {
                HStack {
                    Text(title)
                    Spacer()
                    Text(selectedLanguage)
                }
                .font(.title2)
            }
            .foregroundColor(.senseyeTextColor)
    }
}

@available(iOS 14.0, *)
struct BluetoothSettingsRow: View {
    
    let title: String
    let description: String
    @Binding var isDeviceConnected: Bool
    @Binding var isShowingBluetooth: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.title2)
                        .lineLimit(1)
                    HStack {
                        Text(isDeviceConnected ? Strings.connectedTitle : Strings.notConnectedTitle)
                            .font(.callout)
                        Image(systemName: isDeviceConnected ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(isDeviceConnected ? .senseyeSecondary : .senseyeRed)
                    }
                }
                
                Spacer()
                
                Button {
                    isShowingBluetooth = true
                } label: {
                    Image(systemName: "chevron.forward.circle.fill")
                        .font(.title)
                }

            }
            .foregroundColor(.senseyeTextColor)
        }
    }
}
