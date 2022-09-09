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
    // MARK: - Published Properties
    var uploadProgress: Double { get }
    var uploadProgressPublished: Published<Double> { get}
    var uploadProgressPublisher: Published<Double>.Publisher { get }
    var isFinishedUploading: Bool { get }
    var uploadsAreCompletePublished: Published<Bool> { get }
    var uploadsAreCompletePublisher: Published<Bool>.Publisher { get }
    
    var numberOfUploadsInProgress: Double { get }
    var numberOfUploadsComplete: Int { get }
    var taskCount: Int { get }
    func uploadData(fileUrl: URL)
    func createSessionJsonFileAndStoreCognitoUserAttributes(surveyInput: [String: String])
    func addTaskRelatedInfo(for taskInfo: SenseyeTask)
    func setLatestFrameTimestampArray(frameTimestamps: [Int64]?)
    func getLatestFrameTimestampArray() -> [Int64]
    func reset()
    var isDebugModeEnabled: Bool { get set }
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
    @Published var isFinishedUploading: Bool = false
    @AppStorage("username") var username: String = ""
    
    var isUploadOngoing: Bool = false
    var numberOfUploadsInProgress: Double = 0.0
    var numberOfUploadsComplete: Int = 0 {
        didSet {
            if numberOfUploadsComplete == taskCount {
                Log.info("UploadsComplete")
                isFinishedUploading = true
            }
        }
    }
    
    weak var delegate: FileUploadAndPredictionServiceDelegate?

    private var cancellables = Set<AnyCancellable>()
    private var fileManager: FileManager
    private var fileDestUrl: URL?
    private var hostApiKey: String? = nil
    private var sessionTimeStamp: Int64? = nil
    private var shouldUpload: Bool = true
    private var currentSessionUploadFileKeys: [String] = []
    private var currentTaskFrameTimestamps: [Int64]? = []
    private var hasUploadedJsonFile: Bool = false
    private var sessionInfo: SessionInfo? = nil
    private var s3FolderName: String {
        if let sessionTimeStamp = sessionTimeStamp {
            return "\(username)_\(sessionTimeStamp)"
        } else {
            return "error--\(username)_\(Date())"
        }
    }
    private let hostApi =  "https://rem.api.senseye.co/"
    private let s3HostBucketUrl = "s3://senseyeiossdk98d50aa77c5143cc84a829482001110f111246-dev/public/"
    
    var isDebugModeEnabled: Bool = false
    let debugModeTaskTiming = 0.75
    var taskCount: Int = 0
    
    func setTaskCount(to taskCount: Int) {
        self.taskCount = taskCount
    }
    
    init() {
        self.fileManager = FileManager.default
        fileDestUrl = fileManager.urls(for: .documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first
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
        numberOfUploadsInProgress += 1
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

        storageOperation.resultPublisher
            .receive(on: DispatchQueue.main)
            .sink {
            if case let .failure(storageError) = $0 {
                Log.error("Failed: \(storageError.errorDescription). \(storageError.recoverySuggestion). File: \(#file), line: \(#line), video url: \(filename)")
                self.isUploadOngoing = false
            }
        } receiveValue: { data in
            print("Completed: \(data)")
            self.currentSessionUploadFileKeys.append(fileNameKey)
            self.isUploadOngoing = false
            self.numberOfUploadsInProgress -= 1
            self.numberOfUploadsComplete += 1
            self.submitPredictionRequest(for: self.taskCount)
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
        self.sessionTimeStamp = Date().currentTimeMillis()
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
        
        self.sessionInfo = SessionInfo(versionCode: versionCode, age: age, eyeColor: eyeColor, versionName: versionName, gender: gender, folderName: s3FolderName, username: username, timezone: currentTiemzone.identifier, isDebugModeEnabled: isDebugModeEnabled.description, phoneSettings: phoneSettings, phoneDetails: phoneDetails, tasks: [])
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
    private func uploadSessionJsonFile(jsonFileName: String) {

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
            }
            
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
    
    private func submitPredictionRequest(for taskCount: Int) {
        guard
            isFinishedUploading,
            numberOfUploadsInProgress == 0,
            let apiKey = self.hostApiKey else {
            Log.info("skipping prediction request")
            return
        }
        
        // JSON Upload
        let currentTimeStamp = Date().currentTimeMillis()
        let jsonFileName = "\(s3FolderName)/\(username)_\(currentTimeStamp)_ios_input.json"
        let jsonMetadataURL = s3HostBucketUrl + jsonFileName
        self.uploadSessionJsonFile(jsonFileName: jsonFileName)
        
        // PredictionRequest
        let numberOFUploadsInt = Int(numberOfUploadsComplete)
        let workers = min(numberOFUploadsInt, 10)
        let arn = "arn:aws:s3:::\(s3HostBucketUrl)\(s3FolderName)/*"
        var s3Paths: [String] = []
        for localFileNameKey in currentSessionUploadFileKeys {
            s3Paths.append(s3HostBucketUrl+localFileNameKey)
        }
        
        let filePathLister = FilePathLister(s3Paths: s3Paths, includes: ["**.mp4"], excludes: nil, batchSize: 1)
        let sqsDeadLetterQueue = SQSDeadLetterQueue(arn: arn, maxReceiveCount: 1)
        let params = PredictionRequest(workers: workers, timeout: 1, sqsDeadLetterQueue: sqsDeadLetterQueue, filePathLister: filePathLister, config: ["json_metadata_url": jsonMetadataURL])
        let headers: HTTPHeaders = [
            "x-api-key": apiKey,
            "Accept": "application/json"
        ]
        
        AF.request(hostApi+"ptsd", method: .post, parameters: params, encoder: .json, headers: headers).responseDecodable(of: PredictionResponse.self, completionHandler: { response in
            Log.info("response received! \(response)")
            let jobID = response.value?.jobID
            self.sessionInfo?.predictionJobID = jobID
        })
    }
    
    func reset() {
        print("Reset Called")
        sessionInfo = nil
        hostApiKey = nil
        sessionTimeStamp = nil
        hasUploadedJsonFile = false
        isFinishedUploading = false
        shouldUpload = true
        uploadProgress = 0
        numberOfUploadsInProgress = 0
        numberOfUploadsComplete = 0
        currentTaskFrameTimestamps?.removeAll()
        currentSessionUploadFileKeys.removeAll()
    }
}

@available(iOS 14.0, *)
extension FileUploadAndPredictionService: FileUploadAndPredictionServiceProtocol {
    var uploadsAreCompletePublished: Published<Bool> { _isFinishedUploading }
    var uploadsAreCompletePublisher: Published<Bool>.Publisher { $isFinishedUploading }
    var uploadProgressPublished: Published<Double> { _uploadProgress }
    var uploadProgressPublisher: Published<Double>.Publisher { $uploadProgress }
}
