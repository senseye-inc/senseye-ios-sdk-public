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
        @AppStorage("username") var username: String = ""
        @Published var password: String = ""
        @Published var isUserSignedIn = false
        @Published var isShowingAlert = false
        var alertItem: AlertItem?
        @Published var isFetchingAuthorization: Bool = false

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

        /**
         On any view load, any current user is signed out
         # TODO: handle signout at a previous load state or make signout dependent on last account activity idle time
         */
        func onAppear() {
            authenticationService.delegate = self
            if (self.isUserSignedIn) {
                self.authenticationService.signOut(completeSignOut: nil)
            }
            Log.debug("isSignedIn is \(self.isUserSignedIn)")
        }
        
    }


}

extension LoginView.ViewModel: AuthenticationServiceDelegate {
    func didConfirmNewUser() {
        Log.info("Attempted sign in for new user")
    }
    
    func didSuccessfullySignIn() {
        Log.info("Successful sign in")
        DispatchQueue.main.async {
            self.isUserSignedIn = true
            self.isFetchingAuthorization = false
        }
    }
 
    func didSuccessfullySignOut() {
        Log.info("Successful signed out")
        DispatchQueue.main.async {
            self.isUserSignedIn = false
        }
    }
}
