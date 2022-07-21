//
//  AlertContext.swift
//  
//
//  Created by Frank Oftring on 7/20/22.
//

import SwiftUI
@available(iOS 13.0, *)
struct AlertContext {

    // MARK: - LoginView
    static let invalidLogin = AlertItem(title: "Error, invalid login", message: "Please check username and password. Try Again", alertButtonText: "Ok")
    static let defaultAlert = AlertItem(title: "Unknown Error", message: "Please Try Again", alertButtonText: "Ok")
}
