//
//  SettingsViewModel.swift
//  
//
//  Created by Frank Oftring on 9/21/22.
//

import SwiftUI
@available(iOS 14.0, *)
class SettingsViewModel: ObservableObject {
    @Published var isShowingBluetooth = false
    
    private let preferredLocalization = Bundle.main.preferredLocalizations.first
    var selectedLanguage: String {
        preferredLocalization == "en" ? "English" : "Español"
    }
}
