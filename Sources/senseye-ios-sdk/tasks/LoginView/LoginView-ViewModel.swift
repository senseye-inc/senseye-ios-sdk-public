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
        @Published var username: String = ""
        @Published var password: String = ""
        @Published var token: String = ""
        @Published var isUserSignedIn = false
        @Published var isShowingAlert = false
        @Published var isFetchingAuthorization: Bool = false
        @Published var isShowingSafari: Bool = false
        @Published var isUsingToken: Bool = false
        
        var alertItem: AlertItem?
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
            
            authenticationService.isSignedInPublisher
                .receive(on: RunLoop.main)
                .sink(receiveValue: { isSignedIn in
                    Log.info("Setting isSignedIn: \(isSignedIn)")
                    self.isUserSignedIn = isSignedIn
                    if isSignedIn {
                        self.isFetchingAuthorization = false
                    }
                })
                .store(in: &cancellables)
        }
        
        func login() {
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
            self.authenticationService.signOut()
            username = ""
            Log.info("isSignedIn is \(self.isUserSignedIn)", shouldLogContext: true)
        }
        
    }


}
