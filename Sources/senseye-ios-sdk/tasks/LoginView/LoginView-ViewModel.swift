//
//  LoginView-ViewModel.swift
//  senseye-ios-sdk-app
//
//  Created by Bobby Srisan on 4/3/22.
//

import Foundation
import Amplify
import UIKit
import SwiftUI
import Combine

extension LoginView {
    class ViewModel: ObservableObject {
        @AppStorage(AppStorageKeys.username()) var username: String = ""
        @Published var password: String = ""
        @Published var isUserSignedIn = false
        @Published var isShowingAlert = false
        var alertItem: AlertItem?
        @Published var isFetchingAuthorization: Bool = false
        @Published var isShowingSafari: Bool = false
        
        let supportURL: URL = URL(string: "https://support.senseye.co/")!
        
        private var authenticationService: AuthenticationServiceProtocol
        private var cancellables = Set<AnyCancellable>()

        init(authenticationService: AuthenticationServiceProtocol) {
            self.authenticationService = authenticationService
            addSubscribers()
        }

        func addSubscribers() {
            authenticationService.authErrorPublisher
                .drop(while: { $0 == nil })
                .receive(on: DispatchQueue.main)
                .sink { alertItem in
                    Log.error("AuthError!")
                    self.isShowingAlert = true
                    self.isFetchingAuthorization = false
                    self.alertItem = alertItem
                }
                .store(in: &cancellables)
        }
        
        func login() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) // Dismiss keyboard
            isFetchingAuthorization = true
            self.authenticationService.signIn(
                accountUsername: self.username,
                accountPassword: self.password
            )
        }

        var versionAndBuildNumber: String {
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
            return "\(version ?? "Error getting version") (\(build ?? "Error getting build"))"
        }

        func onAppear() {
            authenticationService.delegate = self
            self.authenticationService.signOut(completeSignOut: nil)
            username = ""
            Log.info("isSignedIn is \(self.isUserSignedIn)", shouldLogContext: true)
        }
        
    }


}

extension LoginView.ViewModel: AuthenticationServiceDelegate {
    func didConfirmNewUser() {
        Log.info("Attempted sign in for new user")
    }
    
    func didSuccessfullySignIn() {
        Log.info("Successful sign in", shouldLogContext: true)
        DispatchQueue.main.async {
            self.isUserSignedIn = true
            self.isFetchingAuthorization = false
        }
    }
 
    func didSuccessfullySignOut() {
        Log.info("Successful signed out", shouldLogContext: true)
        DispatchQueue.main.async {
            self.isUserSignedIn = false
        }
    }
}
