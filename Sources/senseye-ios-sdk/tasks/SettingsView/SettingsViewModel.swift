//
//  SettingsViewModel.swift
//  
//
//  Created by Frank Oftring on 9/21/22.
//

import SwiftUI
@available(iOS 14.0, *)
class SettingsViewModel: ObservableObject {
    @AppStorage("screenTimeOut") var screenTimeOut = false
    @AppStorage("brightness") var brightness = false
    @Published var isShowingBluetooth = false
}
