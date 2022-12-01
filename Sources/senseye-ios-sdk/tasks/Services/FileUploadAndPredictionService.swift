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

protocol FileUploadAndPredictionServiceProtocol {
    // MARK: - Published Properties
    var uploadProgress: Double { get }
    var uploadProgressPublisher: Published<Double>.Publisher { get }
    var isFinished: Bool { get }
    var isFinishedPublisher: Published<Bool>.Publisher { get }
    
    var taskCount: Int { get }
    func uploadData(localFileUrl: URL)
    func createSessionJsonFileAndStoreCognitoUserAttributes(surveyInput: [String: String])
    func addTaskRelatedInfo(for taskInfo: SenseyeTask)
    func setLatestFrameTimestampArray(frameTimestamps: [Int64]?)
    func getLatestFrameTimestampArray() -> [Int64]
    func getVideoPath() -> String
    func reset()
    func setAverageExifBrightness(to averageExifBrightness: Double?)
    var isDebugModeEnabled: Bool { get set }
    var isCensorModeEnabled: Bool { get set }
    var debugModeTaskTiming: Double { get }

    var authenticationService: AuthenticationService? { get set }

    var isFinalUpload: Bool { get }
}

protocol FileUploadAndPredictionServiceDelegate: AnyObject {
    func didFinishUpload()
    func didFinishPredictionRequest()
    func didReturnResultForPrediction(status: String)
}

/**
 FileUploadAndPredictionService is responsible for communicating with backend service.
 */
class FileUploadAndPredictionService: ObservableObject {
    var authenticationService: AuthenticationService?

    @Published private(set) var uploadProgress: Double = 0.0
    @Published private(set) var numberOfTasksCompleted: Int = 0
    @Published private(set) var isFinished: Bool = false
    @AppStorage(AppStorageKeys.username()) var username: String?

    @Published private var numberOfUploadsComplete: Int = 0
    
    weak var delegate: FileUploadAndPredictionServiceDelegate?

    private var cancellables = Set<AnyCancellable>()
    private var fileManager: FileManager
    private var fileDestUrl: URL?
    private var hostApiKey: String? = nil
    private var currentSessionUploadFileKeys: [String] = []
    private var currentTaskFrameTimestamps: [Int64]? = []
    private var sessionInfo: SessionInfo? = nil
    private var currentS3VideoPath: String? = nil
    private var s3FolderName: String = ""
    private var jsonMetadataURL: String = ""
    private let hostApi =  "https://rem.api.senseye.co/"
    private let s3HostBucketUrl = "s3://senseye-ptsd/public/"
    
    var isDebugModeEnabled: Bool = false
    var isCensorModeEnabled: Bool = false
    let debugModeTaskTiming = 0.5
    var taskCount: Int = 0
    var isFinalUpload: Bool {
        numberOfTasksCompleted == (taskCount)
    }

    private let uploadOperationQueue = OperationQueue()

    // TODO: something more agnostic like cancelPeripheralSubscriptions
    @Published var shouldStopBluetooth: Bool = false

    func setTaskCount(to taskCount: Int) {
        self.taskCount = taskCount - 1 // subtracting one for HR CalibrationView. isTaskITem is set to true, but we don't upload anything
    }
    
    init(authenticationService: AuthenticationService) {
        self.fileManager = FileManager.default
        self.authenticationService = authenticationService
        fileDestUrl = fileManager.urls(for: .documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first
        addSubscribers()
    }
    
    
    /**
     Uploads a video file to the server after ensuring signed in session matches user entry at login,
     authenticating the session, and fetching host api key.
     
     - Parameters:
     - fileUrl: URL of the video file to upload
     */
    func uploadData(localFileUrl: URL) {
        let fileNameKey = "\(s3FolderName)/\(localFileUrl.lastPathComponent)"
        currentS3VideoPath = "\(s3HostBucketUrl)\(fileNameKey)"
        
        guard let _ = self.hostApiKey else {
            Log.info("Skipping data upload - hostApiKey is empty")
            return
        }
        numberOfTasksCompleted += 1
        self.enqueue(uploadItem: UploadItem(localFileUrl: localFileUrl, s3UriKey: fileNameKey))
    }

    /**
     Enqueues uploads into an operation queue. This is the abstraction function where we will swap private upload functions as needed.
     */
    private func enqueue(uploadItem: UploadItem) {
        Log.debug("Enqueueing - localurl: \(String(describing: uploadItem.localFileUrl)) s3 target: \(String(describing: uploadItem.s3UriKey))")
        if let s3UriKey = uploadItem.s3UriKey, let localFileUrl = uploadItem.localFileUrl{
            uploadOperationQueue.addOperation {
                self.uploadFile(s3UriKey: s3UriKey, localFileUrl: localFileUrl)
            }
        }
    }

    private func addSubscribers() {
        guard let authenticationService = self.authenticationService else { return }

        authenticationService.$isSignedIn
            .debounce(for: .milliseconds(10), scheduler: RunLoop.main)
            .receive(on: DispatchQueue.global(qos: .utility))
            .sink { [weak self] isSignedIn in
                guard let self = self else {return}
                if isSignedIn {
                    self.setUserAttributes()
                }
            }
            .store(in: &cancellables)
        
        $numberOfTasksCompleted
            .receive(on: DispatchQueue.main)
            .sink { [weak self] numberOfTasksCompleted in
                guard let self = self else {
                    Log.error("Unable to stop bluetooth")
                    return
                }
                if self.isFinalUpload {
                    self.shouldStopBluetooth = true
                }
            }
            .store(in: &cancellables)

        $numberOfUploadsComplete
            .receive(on: DispatchQueue.main)
            .sink { [weak self] numberOfUploadsComplete in
                guard let self = self else {
                    Log.error("Unable to capture self")
                    return
                }
                if (self.numberOfUploadsComplete == self.taskCount) {
                    self.uploadSessionJsonFile()
                }
            }
            .store(in: &cancellables)
    }

    private func uploadFile(s3UriKey: String, localFileUrl: URL) {
        Log.debug("About to upload - video url: \(localFileUrl)")

        let storageOperation = Amplify.Storage.uploadFile(key: s3UriKey, local: localFileUrl)
        storageOperation.progressPublisher
            .receive(on: DispatchQueue.main)
            .sink { newProgressValue in
                let latestProgressValue = Double(self.numberOfUploadsComplete) + newProgressValue.fractionCompleted
                let previousProgressValue = self.uploadProgress
                self.uploadProgress = max(previousProgressValue, latestProgressValue)
                Log.info("latestProgress for \(s3UriKey)-- \(newProgressValue.fractionCompleted) - \(self.numberOfUploadsComplete) -- \(self.uploadProgress)")
            }
            .store(in: &self.cancellables)

        storageOperation.resultPublisher
            .receive(on: DispatchQueue.main)
            .retry(2)
            .sink {
                if case let .failure(storageError) = $0 {
                    Log.error("Failed: \(storageError.errorDescription). \(storageError.recoverySuggestion). video url: \(localFileUrl)",
                              shouldLogContext: true,
                              userInfo: [
                                "error": storageError.errorDescription,
                                "localFileUrl": localFileUrl,
                                "s3UriKey": s3UriKey,
                                "sessionInfo": self.sessionInfo?.asDictionary
                              ]
                    )
                    self.enqueue(uploadItem: UploadItem(localFileUrl: localFileUrl, s3UriKey: s3UriKey))
                }
            } receiveValue: { [weak self] data in
                guard let self = self else {
                    Log.info("Unable to capture self.", shouldLogContext: true)
                    return
                }
                Log.info("Completed: \(data)")
                self.currentSessionUploadFileKeys.append(s3UriKey)
                self.numberOfUploadsComplete += 1
                self.uploadProgress = Double(self.numberOfUploadsComplete)
            }
            .store(in: &cancellables)

        storageOperation.start()
    }
    
    private func setUserAttributes() {
        Amplify.Auth.fetchUserAttributes() { result in
            switch result {
            case .success(let attributes):
                if let apiKey = attributes.first(where: { $0.key == AuthUserAttributeKey.custom("senseye_api_token") }) {
                    self.hostApiKey = apiKey.value
                    Log.info("Found and set senseye_api_token")
                } else {
                    Log.warn("unable to set api key")
                }
            case .failure(let authError):
                Log.warn("Fetching user attributes failed: \(authError)")
            }
        }
    }
    
    /**
     Generate session json file from survey responses and experiment session tasks.
     
     - Parameters:
     - surveyInput: Array of responses from demographic survey
     */
    func createSessionJsonFileAndStoreCognitoUserAttributes(surveyInput: [String: String]) {
        let sessionTimeStamp = Date().currentTimeMillis()
        let username = self.username ?? "unknown"
        self.s3FolderName = "\(username)_\(sessionTimeStamp)"
        let age = surveyInput["age"]
        let gender = surveyInput["gender"]
        let eyeColor = surveyInput["eyeColor"]
        let versionName = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let versionCode = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        let deviceType = UIDevice().type
        @AppStorage(AppStorageKeys.cameraType()) var cameraType: String?
        let currentTiemzone = TimeZone.current
        let currentScreenBrightnessInt = Int(UIScreen.main.brightness)
        let osVersion = UIDevice.current.systemVersion
        let reachability = NetworkReachabilityManager.default?.status
        let idlenessTimerDisabled = UIApplication.shared.isIdleTimerDisabled
        var networkType: String?
        switch reachability {
        case .unknown, .notReachable, .none:
            Log.info("unknown connection type or not reachable")
        case .reachable(let connectionType):
            networkType = "\(connectionType)"
        }
        
        let phoneDetails = PhoneDetails(
            os: "iOS",
            osVersion: osVersion,
            brand: "Apple",
            deviceType: deviceType.rawValue,
            cameraType: cameraType
        )

        let phoneSettings = PhoneSettings(
            idlenessTimerDisabled: idlenessTimerDisabled,
            screenBrightness: currentScreenBrightnessInt,
            freeSpace: nil,
            networkType: networkType,
            downloadSpeed: nil,
            uploadSpeed: nil
        )
        
        let cognitoUserGroupIds = authenticationService?.accountUserGroups.map { $0.groupId } ?? []

        sessionInfo = SessionInfo(
            versionCode: versionCode,
            age: age,
            eyeColor: eyeColor,
            versionName: versionName,
            gender: gender,
            folderName: s3FolderName,
            username: username,
            timezone: currentTiemzone.identifier,
            isDebugModeEnabled: isDebugModeEnabled,
            isCensorModeEnabled: isCensorModeEnabled,
            phoneSettings: phoneSettings,
            phoneDetails: phoneDetails,
            tasks: [],
            userGroups: cognitoUserGroupIds
        )
        Log.info("Session info initialized: \(String(describing: sessionInfo))")
    }

    func setLatestFrameTimestampArray(frameTimestamps: [Int64]?) {
        self.currentTaskFrameTimestamps = frameTimestamps
    }
    
    func getLatestFrameTimestampArray() -> [Int64] {
        return currentTaskFrameTimestamps ?? []
    }
    
    func getVideoPath() -> String {
        return currentS3VideoPath ?? ""
    }
    
    func setAverageExifBrightness(to averageExifBrightness: Double?) {
        self.sessionInfo?.averageExifBrightness = averageExifBrightness
    }

    func addTaskRelatedInfo(for taskInfo: SenseyeTask) {
        self.sessionInfo?.tasks.append(taskInfo)
    }
    
    /**
     Upload JSON file for the current session
     */
    private func uploadSessionJsonFile() {
        
        let currentTimeStamp = Date().currentTimeMillis()
        let username = self.username ?? "unknown"
        let jsonFileName = "\(s3FolderName)/\(username)_\(currentTimeStamp)_ios_input.json"
        self.jsonMetadataURL = s3HostBucketUrl + jsonFileName

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .withoutEscapingSlashes
            let encodedData = try encoder.encode(sessionInfo)

            // TODO: remove unused uploadS3URLs
            var uploadS3URLs: [String] = []
            for localFileNameKey in currentSessionUploadFileKeys {
                uploadS3URLs.append(s3HostBucketUrl+localFileNameKey)
            }
            
            let storageOperation = Amplify.Storage.uploadData(key: jsonFileName, data: encodedData)
            
            storageOperation.progressPublisher
                .sink { progress in
                    Log.info("Progress: \(progress)")
                }
                .store(in: &self.cancellables)
            
            storageOperation.resultPublisher
                .receive(on: DispatchQueue.main)
                .retry(2)
                .sink {
                    if case let .failure(storageError) = $0 {
                        Log.error("Failed: \(storageError.errorDescription). \(storageError.recoverySuggestion)",
                                  userInfo: ["username": sessionInfo?.username,
                                             "versionCode": sessionInfo?.versionCode,
                                             "predictionJobId": sessionInfo?.predictionJobID
                                             "s3FolderName": sessionInfo?.folderName
                                            ])
                    }
                } receiveValue: { data in
                    Log.debug("Uploaded json file - data: \(data)")
                    self.numberOfUploadsComplete += 1
                    self.submitPredictionRequest()
                }
                .store(in: &cancellables)
            
        } catch {
            Log.error("Error in json parsing for input file")
        }
    }
    
    private func submitPredictionRequest() {
        
        guard let apiKey = hostApiKey else {
            Log.error("Skipping the PTSD request but it's here", userInfo: ["username": sessionInfo?.username,
                                                                            "versionCode": sessionInfo?.versionCode,
                                                                            "predictionJobId": sessionInfo?.predictionJobID
                                                                            "s3FolderName": sessionInfo?.folderName
                                                                           ])
            return
        }
        
        // PredictionRequest
        let workers = min(self.taskCount, 10)
        let sqsDeadLetterQueueARN = "arn:aws:sqs:us-east-1:555897601062:iossdk_ptsd_batch_dead_letter.fifo"
        var s3Paths: [String] = []
        for localFileNameKey in currentSessionUploadFileKeys {
            s3Paths.append(s3HostBucketUrl+localFileNameKey)
        }
        
        let filePathLister = FilePathLister(s3Paths: s3Paths, includes: ["**.mp4"], excludes: nil, batchSize: 1)
        let sqsDeadLetterQueue = SQSDeadLetterQueue(arn: sqsDeadLetterQueueARN, maxReceiveCount: 2)
        let params = PredictionRequest(workers: workers, sqsDeadLetterQueue: sqsDeadLetterQueue, filePathLister: filePathLister, config: ["json_metadata_url": jsonMetadataURL])
        let headers: HTTPHeaders = [
            "x-api-key": apiKey,
            "Accept": "application/json"
        ]
        
        AF.request(hostApi+"ptsd", method: .post, parameters: params, encoder: .json, headers: headers).responseDecodable(of: PredictionResponse.self, completionHandler: { response in
            Log.info("response received! \(response)")
            let jobID = response.value?.jobID
            self.isFinished = true
            self.sessionInfo?.predictionJobID = jobID
        })
    }
    
    func reset() {
        sessionInfo = nil
        hostApiKey = nil
        isDebugModeEnabled = false
        isCensorModeEnabled = false
        isFinished = false
        shouldStopBluetooth = false
        jsonMetadataURL = ""
        currentS3VideoPath = ""
        uploadProgress = 0
        numberOfUploadsComplete = 0
        numberOfTasksCompleted = 0
        currentTaskFrameTimestamps?.removeAll()
        currentSessionUploadFileKeys.removeAll()
        UserDefaults.standard.resetUser()
        uploadOperationQueue.cancelAllOperations()
    }
    
}

extension FileUploadAndPredictionService: FileUploadAndPredictionServiceProtocol {
    var uploadProgressPublisher: Published<Double>.Publisher { $uploadProgress }
    var isFinishedPublisher: Published<Bool>.Publisher { $isFinished }
}


extension FileUploadAndPredictionService {
    struct UploadItem {
        let localFileUrl: URL?
        let s3UriKey: String?
    }
}
