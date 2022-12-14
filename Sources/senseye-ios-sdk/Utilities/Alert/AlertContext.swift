//
//  AlertContext.swift
//  
//
//  Created by Frank Oftring on 7/20/22.
//

import SwiftUI

struct AlertContext {

    // MARK: - LoginView
    static let invalidLogin = AlertItem(title: "Error, invalid login", message: "Please check username and password. Try Again", alertButtonText: "Ok")
    static let authFlowError = AlertItem(title: "Error signing in", message: "Please contact your healthcare provider for help", alertButtonText: "Ok")
    static let imageDownloadError = AlertItem(title: "Error downloading images", message: "Please close the app and try again.", alertButtonText: "Ok")
    static let defaultAlert = AlertItem(title: "Unknown Error", message: "Please Try Again", alertButtonText: "Ok")
}
