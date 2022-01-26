//
//  FileUploadService.swift
//  
//
//  Created by Deepak Kumar on 12/15/21.
//

import Foundation
import Amplify

class FileUploadService {
    
    let testAccountUsername = "tfl"
    let testAccountPassword = "senseyeTesterIos"
    
    func uploadData(fileUrl: URL) {
        let fileNameKey = fileUrl.lastPathComponent
        let filename = fileUrl
        if (Amplify.Auth.getCurrentUser() == nil) {
            signIn(username: testAccountUsername, password: testAccountPassword, filenameKey: fileNameKey, filename: filename)
        } else {
            uploadFile(fileNameKey: fileNameKey, filename: filename)
        }
        
    }
    
    private func uploadFile(fileNameKey: String, filename: URL) {
        let storageOperation = Amplify.Storage.uploadFile(
            key: fileNameKey,
            local: filename,
            progressListener: { progress in
                print("Progress: \(progress)")
            }, resultListener: { event in
                switch event {
                case let .success(data):
                    print("Completed: \(data)")
                case let .failure(storageError):
                    print("Failed: \(storageError.errorDescription). \(storageError.recoverySuggestion)")
                }
            }
        )
    }
    
    private func signIn(username: String, password: String, filenameKey: String, filename: URL) {
        Amplify.Auth.signIn(username: username, password: password) { result in
            do {
                    let signinResult = try result.get()
                    switch signinResult.nextStep {
                    case .confirmSignInWithSMSMFACode(let deliveryDetails, let info):
                        print("SMS code send to \(deliveryDetails.destination)")
                        print("Additional info \(info)")
                        // Prompt the user to enter the SMSMFA code they received
                        // Then invoke `confirmSignIn` api with the code
                    case .confirmSignInWithCustomChallenge(let info):
                        print("Custom challenge, additional info \(info)")
                        // Prompt the user to enter custom challenge answer
                        // Then invoke `confirmSignIn` api with the answer
                    case .confirmSignInWithNewPassword(let info):
                        print("New password additional info \(info)")
                        Amplify.Auth.confirmSignIn(challengeResponse: self.testAccountPassword, options: nil) { confirmSignInResult in
                            switch confirmSignInResult {
                            case .success(let confirmedResult):
                                print("signed in after password change")
                                self.uploadFile(fileNameKey: filenameKey, filename: filename)
                            case .failure(let error):
                                print("Sign in failed \(error)")
                            }
                        }
                        // Prompt the user to enter a new password
                        // Then invoke `confirmSignIn` api with new password
                    case .resetPassword(let info):
                        print("Reset password additional info \(info)")
                        // User needs to reset their password.
                        // Invoke `resetPassword` api to start the reset password
                        // flow, and once reset password flow completes, invoke
                        // `signIn` api to trigger signin flow again.
                    case .confirmSignUp(let info):
                        print("Confirm signup additional info \(info)")
                        // User was not confirmed during the signup process.
                        // Invoke `confirmSignUp` api to confirm the user if
                        // they have the confirmation code. If they do not have the
                        // confirmation code, invoke `resendSignUpCode` to send the
                        // code again.
                        // After the user is confirmed, invoke the `signIn` api again.
                    case .done:
                        // Use has successfully signed in to the app
                        self.uploadFile(fileNameKey: filenameKey, filename: filename)
                        print("Signin complete")
                    }
                } catch {
                    print ("Sign in failed \(error)")
                }
        }
    }
    
}
