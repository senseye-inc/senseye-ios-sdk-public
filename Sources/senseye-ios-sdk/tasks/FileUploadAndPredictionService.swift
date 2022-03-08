//
//  FileUploadService.swift
//  
//
//  Created by Deepak Kumar on 12/15/21.
//

import Foundation
import Amplify
import Alamofire
import SwiftyJSON

protocol FileUploadAndPredictionServiceDelegate: AnyObject {
    func didFinishUpload()
    func didFinishPredictionRequest()
    func didReturnResultForPrediction(status: String)
    func didJustSignUpAndChangePassword()
}

class FileUploadAndPredictionService {
    
    private struct PredictRequestParameters: Encodable {
        var video_urls: [String]
        var threshold: Double
        var json_metadata_url: String
    }
    private struct SubmitPredictionJobResponseCodable: Decodable {
        var id: String
    }
    private struct PredictionJobStatusAndResultCodable: Decodable {
        var id: String
        var status: String
        var result: PredictionJobStatusResultCodable?
    }
    
    private struct PredictionJobStatusResultCodable: Decodable {
        var prediction: PreditionJobStatusPredictionCodable
    }
    
    private struct PreditionJobStatusPredictionCodable: Decodable {
        var fatigue: String?
        var intoxication: String?
        var state: Int
    }
    
    private var accountUsername: String? = ""
    private var accountPassword: String? = ""
    private var temporaryPassword: String? = ""
    private let hostApi =  "https://api.senseye.co"
    private var hostApiKey: String? = nil
    private let s3HostBucketUrl = "s3://senseyeiossdk98d50aa77c5143cc84a829482001110f111246-dev/public/"
    
    private var currentSessionUploadFileKeys: [String] = []
    private var currentSessionPredictionId: String = ""
    private var currentSessionJsonInputFile: Data? = nil
    
    var isUploadOngoing: Bool = false
    weak var delegate: FileUploadAndPredictionServiceDelegate?
    
    func setGroupIdAndUniqueId(groupId: String, uniqueId: String, temporaryPassword: String) {
        self.accountUsername = groupId
        self.accountPassword = uniqueId
        self.temporaryPassword = temporaryPassword
    }
    
    func uploadData(fileUrl: URL) {
        let fileNameKey = fileUrl.lastPathComponent
        let filename = fileUrl
        Amplify.Auth.fetchAuthSession { result in
            switch result {
            case .success(let session):
                print("Is user signed in - \(session.isSignedIn)")
                
                guard let userName = self.accountUsername, let password = self.accountPassword else {
                    return
                }
                let currentlyAuthenticatedAmplifyUser = Amplify.Auth.getCurrentUser()
                let doesUserMatchCurrentSignIn = currentlyAuthenticatedAmplifyUser?.username == userName
                if (!session.isSignedIn || !doesUserMatchCurrentSignIn) {
                    Amplify.Auth.signOut { result in
                        switch result {
                        case .success():
                            self.signIn(username: userName, password: password, filenameKey: fileNameKey, filename: filename, temporaryPassword: self.temporaryPassword)
                        case .failure(let error):
                            print("Amplify auth sign out failed \(error)")
                        }
                    }
                } else {
                    if (self.hostApiKey == nil) {
                        Amplify.Auth.fetchUserAttributes() { result in
                            switch result {
                            case .success(let attributes):
                                self.setUserApiKey(attributes: attributes)
                                self.uploadFile(fileNameKey: fileNameKey, filename: filename)
                            case .failure(let error):
                                print("Fetching user attributes failed with error \(error)")
                            }
                        }
                    } else {
                        self.uploadFile(fileNameKey: fileNameKey, filename: filename)
                    }
                }
            case .failure(let error):
                print("Fetch session failed with error \(error)")
            }
        }
    }
    
    private func uploadFile(fileNameKey: String, filename: URL) {
         isUploadOngoing = true
         Amplify.Storage.uploadFile(
            key: fileNameKey,
            local: filename,
            progressListener: { progress in
                print("Progress: \(progress)")
            }, resultListener: { event in
                switch event {
                case let .success(data):
                    print("Completed: \(data)")
                    self.currentSessionUploadFileKeys.append(fileNameKey)
                    self.isUploadOngoing = false
                    self.delegate?.didFinishUpload()
                case let .failure(storageError):
                    print("Failed: \(storageError.errorDescription). \(storageError.recoverySuggestion)")
                    self.isUploadOngoing = false
                }
            }
        )
    }
    
    private func setUserApiKey(attributes: Array<AuthUserAttribute>) {
        for attribute in attributes {
            if (attribute.key == AuthUserAttributeKey.custom("senseye_api_token")) {
                self.hostApiKey = attribute.value
                print("Set the api key " + attribute.value)
            }
        }
    }
    
    func createSessionInputJsonFile(surveyInput: [String: String]) {
        let inputJson = "{\"tasks\": \"\",\"versionName\": \"0.0.0\",\"versionCode]\": 0}"
        let inputJsonDataFile = inputJson.data(using: .utf8)!
        
        var sessionInputJson = JSON()
        sessionInputJson["tasks"].string = ""
        sessionInputJson["versionName"].string = "0.0.0"
        sessionInputJson["versionCode"].string = "0"
        
        do {
            try self.currentSessionJsonInputFile = sessionInputJson.rawData()
        } catch {
            print("Error in json parsing for input file")
        }
        
    }
    
    func startPredictionForCurrentSessionUploads() {
        
        guard let sessionJsonFile = currentSessionJsonInputFile else {
            return
        }
        
        var uploadS3URLs: [String] = []
        for localFileNameKey in currentSessionUploadFileKeys {
            uploadS3URLs.append(s3HostBucketUrl+localFileNameKey)
            print("\(s3HostBucketUrl+localFileNameKey)")
        }
        
        let currentTimeStamp = Date().currentTimeMillis()
        let jsonFileName = "\(currentTimeStamp)_ios_input.json"
        let s3JsonFileName = "\(s3HostBucketUrl)\(jsonFileName)"
        Amplify.Storage.uploadData(
            key: jsonFileName,
            data: sessionJsonFile,
            progressListener: { progress in
            print("Progress: \(progress)")
            }, resultListener: { event in
                switch event {
                case let .success(data):
                    let params = PredictRequestParameters(video_urls: uploadS3URLs, threshold: 0.5, json_metadata_url: s3JsonFileName)
                    guard let apiKey = self.hostApiKey else {
                        return
                    }
                    let headers: HTTPHeaders = [
                        "x-api-key": apiKey,
                        "Accept": "application/json"
                    ]
                    AF.request(self.hostApi+"/predict", method: .post, parameters: params, encoder: JSONParameterEncoder.default, headers: headers).responseDecodable(of: SubmitPredictionJobResponseCodable.self) { response in
                        switch response.result {
                        case let .success(predictionJobResponse):
                            print("Prediction request success \(predictionJobResponse)")
                            self.currentSessionPredictionId = predictionJobResponse.id
                            self.delegate?.didFinishPredictionRequest()
                        case let .failure(failure):
                            print("Prediction request failure \(failure)")
                        }
                    }
                case let .failure(storageError):
                    print("Failed: \(storageError.errorDescription). \(storageError.recoverySuggestion)")
                }
            }
        )
        
        
    }
    
    func startPeriodicUpdatesOnPredictionId() {
        
        guard let apiKey = hostApiKey else {
            return
        }
        
        let headers: HTTPHeaders = [
            "x-api-key": apiKey,
            "Accept": "application/json"
        ]
        let params: PredictRequestParameters? = nil
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [self] timer in
            AF.request(self.hostApi+"/predict/"+self.currentSessionPredictionId, method: .get, parameters: params, encoder: JSONParameterEncoder.default, headers: headers).responseDecodable(of: PredictionJobStatusAndResultCodable.self) { response in
                switch response.result {
                case let .success(jobStatusAndResultResponse):
                    if (jobStatusAndResultResponse.status == "completed" || jobStatusAndResultResponse.status == "failed") {
                        print("Prediction periodic request success and result retrieved! \(jobStatusAndResultResponse)")
                        self.delegate?.didReturnResultForPrediction(status: jobStatusAndResultResponse.status)
                        timer.invalidate()
                    } else {
                        print("Prediction periodic request not done yet, will try again. \(jobStatusAndResultResponse)")
                    }
                case let .failure(failure):
                    print("Prediction periodic request failure \(failure)")
                    timer.invalidate()
                }
            }
        }
    }
    
    private func signIn(username: String, password: String, filenameKey: String, filename: URL, temporaryPassword: String?) {
        var signInPassword = ""
        if (temporaryPassword != nil || temporaryPassword != "") {
            signInPassword = temporaryPassword!
        } else {
            signInPassword = password
        }
        Amplify.Auth.signIn(username: username, password: signInPassword) { result in
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
                        Amplify.Auth.confirmSignIn(challengeResponse: password, options: nil) { confirmSignInResult in
                            switch confirmSignInResult {
                            case .success(let confirmedResult):
                                print("signed in after password change")
                                self.delegate?.didJustSignUpAndChangePassword()
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
