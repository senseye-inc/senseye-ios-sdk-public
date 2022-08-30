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
import Combine
import SwiftUI

@available(iOS 13.0, *)
protocol FileUploadAndPredictionServiceProtocol {
    var uploadProgress: Double { get }
    var uploadProgressPublished: Published<Double> { get}
    var uploadProgressPublisher: Published<Double>.Publisher { get }
    var numberOfUploads: Double { get }
    func uploadData(fileUrl: URL)
    func createSessionJsonFileAndStoreCognitoUserAttributes(surveyInput: [String: String])
    func uploadSessionJsonFile()
    func addTaskRelatedInfo(for taskInfo: SenseyeTask)
    func setLatestFrameTimestampArray(frameTimestamps: [Int64]?)
    func getLatestFrameTimestampArray() -> [Int64]
    var enableDebugMode: Bool { get set }
    var debugModeTaskTiming: Double { get }
}

protocol FileUploadAndPredictionServiceDelegate: AnyObject {
    func didFinishUpload()
    func didFinishPredictionRequest()
    func didReturnResultForPrediction(status: String)
}

/**
 FileUploadAndPredictionService is responsible for communicating with backend service.
 */
@available(iOS 14.0, *)
class FileUploadAndPredictionService: ObservableObject {

    @Published var uploadProgress: Double = 0.0
    @AppStorage("username") var username: String = ""
    
    var isUploadOngoing: Bool = false
    var numberOfUploads: Double = 0.0
    weak var delegate: FileUploadAndPredictionServiceDelegate?

    private var cancellables = Set<AnyCancellable>()
    private var fileManager: FileManager
    private var fileDestUrl: URL?
    private var hostApiKey: String? = nil
    private var sessionTimeStamp: Int64
    private var shouldUpload: Bool = true
    private var currentSessionUploadFileKeys: [String] = []
    private var currentTaskFrameTimestamps: [Int64]? = []
    private var hasUploadedJsonFile: Bool = false
    private var sessionInfo: SessionInfo? = nil
    private var s3FolderName: String {
        return "\(username)_\(sessionTimeStamp)"
    }
    private let hostApi =  "https://apeye.senseye.co"
    private let s3HostBucketUrl = "s3://senseyeiossdk98d50aa77c5143cc84a829482001110f111246-dev/public/"
    
    var enableDebugMode: Bool = false
    let debugModeTaskTiming = 0.5
    
    init() {
        self.fileManager = FileManager.default
        fileDestUrl = fileManager.urls(for: .documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first
        self.sessionTimeStamp = Date().currentTimeMillis()
        Log.debug("ShouldUpload: \(shouldUpload)")
    }
    
    
    /**
     Uploads a video file to the server after ensuring signed in session matches user entry at login,
     authenticating the session, and fetching host api key.
     
     - Parameters:
     - fileUrl: URL of the video file to upload
     */
    func uploadData(fileUrl: URL) {
        let fileNameKey = "\(s3FolderName)/\(fileUrl.lastPathComponent)"
        let filename = fileUrl
        
        guard let _ = self.hostApiKey, shouldUpload else {
            Log.info("Skipping data upload")
            return
        }
        
        self.uploadFile(fileNameKey: fileNameKey, filename: filename)
    }
    
    private func uploadFile(fileNameKey: String, filename: URL) {
        isUploadOngoing = true
        numberOfUploads += 1
        Log.debug("About to upload - video url: \(filename)")

        let storageOperation = Amplify.Storage.uploadFile(key: fileNameKey, local: filename)

        storageOperation.progressPublisher
            .receive(on: DispatchQueue.main)
            .scan(0.0, { previousValue, newValueFromPublisher in
                let newValueRounded = newValueFromPublisher.fractionCompleted.rounded(toPlaces: 2)
                let previousValueRounded = previousValue.rounded(toPlaces: 2)
                let difference = (newValueRounded - previousValueRounded).rounded(toPlaces: 2)
                self.uploadProgress = self.uploadProgress.rounded(toPlaces: 2) + difference
                return newValueRounded
            })
            .sink(receiveValue: { Log.info("Progress: " + $0.description) })
            .store(in: &self.cancellables)

        storageOperation.resultPublisher.sink {
            if case let .failure(storageError) = $0 {
                Log.error("Failed: \(storageError.errorDescription). \(storageError.recoverySuggestion). File: \(#file), line: \(#line), video url: \(filename)")
                self.isUploadOngoing = false
            }
        } receiveValue: { data in
            print("Completed: \(data)")
            self.currentSessionUploadFileKeys.append(fileNameKey)
            self.isUploadOngoing = false
            self.delegate?.didFinishUpload()
        }
        .store(in: &self.cancellables)
    }
    
    private func setUserAttributes() {
        Amplify.Auth.fetchUserAttributes() { result in
            switch result {
            case .success(let attributes):
                if let apiKey = attributes.first(where: { $0.key == AuthUserAttributeKey.custom("senseye_api_token") }) {
                    self.hostApiKey = apiKey.value
                    Log.debug("Found and set senseye_api_token")
                } else {
                    Log.warn("unable to set api key")
                }
                if attributes.contains(where: { $0.key == AuthUserAttributeKey.custom("skip_uploads")}) {
                    Log.debug("Found and set skip_uploads. Skipping Upload.")
                    self.shouldUpload = false
                }
                Log.debug("Host api key: \(String(describing: self.hostApiKey))")
            case .failure(let authError):
                Log.warn("Fetching user attribute senseye_api_token failed: \(authError)")
            }
        }
    }
    
    /**
     Generate session json file from survey responses and experiment session tasks.
     
     - Parameters:
     - surveyInput: Array of responses from demographic survey
     */
    func createSessionJsonFileAndStoreCognitoUserAttributes(surveyInput: [String: String]) {
        self.setUserAttributes()
        let age = surveyInput["age"]
        let gender = surveyInput["gender"]
        let eyeColor = surveyInput["eyeColor"]
        let versionName = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let versionCode = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        let deviceType = UIDevice().type
        let currentTiemzone = TimeZone.current
        let currentBrightnessInt = Int(UIScreen.main.brightness)
        let osVersion = UIDevice.current.systemVersion
        let reachability = NetworkReachabilityManager.default?.status
        let idlenessTimerDisabled = UIApplication.shared.isIdleTimerDisabled
        var networkType: String?
        switch reachability {
        case .unknown, .notReachable, .none:
            print("unknown connection type or not reachable")
        case .reachable(let connectionType):
            networkType = "\(connectionType)"
        }
        
        let phoneDetails = PhoneDetails(os: "iOS", osVersion: osVersion, brand: "Apple", deviceType: deviceType.rawValue)
        let phoneSettings = PhoneSettings(idlenessTimerDisabled: idlenessTimerDisabled, brightness: currentBrightnessInt, freeSpace: nil, networkType: networkType, downloadSpeed: nil, uploadSpeed: nil)
        
        self.sessionInfo = SessionInfo(versionCode: versionCode, age: age, eyeColor: eyeColor, versionName: versionName, gender: gender, folderName: s3FolderName, username: username, timezone: currentTiemzone.identifier, phoneSettings: phoneSettings, phoneDetails: phoneDetails, tasks: [])
    }
    
    func setLatestFrameTimestampArray(frameTimestamps: [Int64]?) {
        self.currentTaskFrameTimestamps = frameTimestamps
    }
    
    func getLatestFrameTimestampArray() -> [Int64] {
        return currentTaskFrameTimestamps ?? []
    }

    func addTaskRelatedInfo(for taskInfo: SenseyeTask) {
        self.sessionInfo?.tasks.append(taskInfo)
    }
    
    /**
     Upload JSON file for the current session
     */
    func uploadSessionJsonFile() {

        guard shouldUpload else {
            Log.info("Skipping JSON Upload")
            return
        }
        
        if hasUploadedJsonFile {
            return
        }
        
        do {
            let encodedData = try JSONEncoder().encode(sessionInfo)
            var uploadS3URLs: [String] = []
            for localFileNameKey in currentSessionUploadFileKeys {
                uploadS3URLs.append(s3HostBucketUrl+localFileNameKey)
                Log.debug("\(s3HostBucketUrl+localFileNameKey)")
            }
            
            let currentTimeStamp = Date().currentTimeMillis()
            let jsonFileName = "\(s3FolderName)/\(username)_\(currentTimeStamp)_ios_input.json"
            Amplify.Storage.uploadData(
                key: jsonFileName,
                data: encodedData,
                progressListener: { progress in
                    Log.info("Progress: \(progress)")
                }, resultListener: { event in
                    switch event {
                    case let .success(data):
                        Log.debug("Uploaded json file - data: \(data)")
                        self.hasUploadedJsonFile = true
                    case let .failure(storageError):
                        Log.warn("Failed: \(storageError.errorDescription). \(storageError.recoverySuggestion)")
                    }
                }
            )
            
        } catch {
            Log.error("Error in json parsing for input file")
        }
    }
}

@available(iOS 14.0, *)
extension FileUploadAndPredictionService: FileUploadAndPredictionServiceProtocol {
    var uploadProgressPublished: Published<Double> { _uploadProgress }
    var uploadProgressPublisher: Published<Double>.Publisher { $uploadProgress }
}
