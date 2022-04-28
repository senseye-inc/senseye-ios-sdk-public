//
//  File.swift
//  
//
//  Created by Frank Oftring on 4/28/22.
//

import Foundation
@testable import senseye_ios_sdk

class MockAuthenticationService {
    
    weak var delegate: AuthenticationServiceDelegate?
    
    var accountUsername: String? = nil
    var accountPassword: String? = nil
    var temporaryPassword: String? = nil
    
    func setCredentials(accountUsername: String, accountPassword: String, temporaryPassword: String?) {
        self.accountUsername = "Example User"
        self.accountPassword = "password"
        self.temporaryPassword = "temp-password"
    }
}

extension MockAuthenticationService: AuthenticationServiceProtocol {
    
    func signOut(completeSignOut: (() -> ())?) {
        
    }
    
    public func authenticateSession(accountUsername: String, accountPassword: String, temporaryPassword: String?) {
        self.setCredentials(
            accountUsername: accountUsername,
            accountPassword: accountPassword,
            temporaryPassword: temporaryPassword
        )
    }
}
