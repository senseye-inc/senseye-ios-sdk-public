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

// MARK: - SessionInfo
struct SessionInfo: Codable {
    let versionCode, age, eyeColor, versionName: String
    let gender: String
    let tasks: [SenseyeTask]
}

// MARK: - Task
struct SenseyeTask: Codable {
    let taskID: String
    let timestamps: [Int64]?
    let eventXLOC, eventYLOC: [Int]?
    let eventImageID: [String]?
    let eventBackgroundColor: [String]?

    enum CodingKeys: String, CodingKey {
        case taskID = "taskId"
        case timestamps
        case eventXLOC = "event_x_loc"
        case eventYLOC = "event_y_loc"
        case eventImageID = "event_image_id"
        case eventBackgroundColor = "event_background_color"
    }

    init(taskID: String, timestamps: [Int64]? = nil, eventXLOC: [Int]? = nil, eventYLOC: [Int]? = nil, eventImageID: [String]? = nil, eventBackgroundColor: [String]? = nil) {
        self.taskID = taskID
        self.timestamps = timestamps
        self.eventXLOC = eventXLOC
        self.eventYLOC = eventYLOC
        self.eventImageID = eventImageID
        self.eventBackgroundColor = eventBackgroundColor
    }
}

@available(iOS 13.0, *)
protocol FileUploadAndPredictionServiceProtocol {
    func startPeriodicUpdatesOnPredictionId(completed: @escaping (Result<String, Error>) -> Void)
    var uploadProgress: Double { get }
    var uploadProgressPublished: Published<Double> { get}
    var uploadProgressPublisher: Published<Double>.Publisher { get }
    var numberOfUploads: Double { get }
    func downloadIndividualImageAssets(imageS3Key: String, successfullCompletion: @escaping () -> Void)
    func uploadData(fileUrl: URL)
    func createSessionJsonFileAndStoreCognitoUserAttributes(surveyInput: [String: String])
    func uploadSessionJsonFile()
    func addTaskRelatedInfoToSessionJson(taskId: String, taskTimestamps: [Int64])
    func addTaskRelatedInfoTo(taskInfo: SenseyeTask)
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

    @Published var uploadProgress: Double = 0.0
    var uploadProgressPublished: Published<Double> { _uploadProgress }
    var uploadProgressPublisher: Published<Double>.Publisher { $uploadProgress }
    var numberOfUploads: Double = 0.0
    private var cancellables = Set<AnyCancellable>()
    
    private let hostApi =  "https://apeye.senseye.co"
    private var hostApiKey: String? = nil
    private var sessionTimeStamp: Int64
    @AppStorage("username") var username: String = ""
    private var s3FolderName: String {
        return "\(username)_\(sessionTimeStamp)"
    }
    private let s3HostBucketUrl = "s3://senseyeiossdk98d50aa77c5143cc84a829482001110f111246-dev/public/"
    private var shouldSkipUpload: Bool = false
    
    private var currentSessionUploadFileKeys: [String] = []
    private var currentSessionPredictionId: String = ""
    private var currentSessionJsonInputFile: JSON? = nil
    private var hasUploadedJsonFile: Bool = false

    var isUploadOngoing: Bool = false
    private var fileManager: FileManager
    private var fileDestUrl: URL?
    weak var delegate: FileUploadAndPredictionServiceDelegate?
    
    init() {
        self.fileManager = FileManager.default
        fileDestUrl = fileManager.urls(for: .documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first
        self.sessionTimeStamp = Date().currentTimeMillis()
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
        
        guard let _ = self.hostApiKey, !shouldSkipUpload else {
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
                let difference = (newValueFromPublisher.fractionCompleted - previousValue)
                self.uploadProgress += difference
                return newValueFromPublisher.fractionCompleted
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
                    self.shouldSkipUpload = true
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
     - tasks: Array of experiment tasks that are performed during the session
     */
    func createSessionJsonFileAndStoreCognitoUserAttributes(surveyInput: [String: String]) {
        self.setUserAttributes()
        var sessionInputJson = JSON()
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        let deviceType = UIDevice().type
        let currentTiemzone = TimeZone.current
        
        sessionInputJson["versionName"].string = version
        sessionInputJson["versionCode"].string = build
        sessionInputJson["deviceType"].string = deviceType.rawValue
        sessionInputJson["timezone"].string = currentTiemzone.identifier
        
        for inputItem in surveyInput {
            sessionInputJson[inputItem.key].string = inputItem.value
        }
        self.currentSessionJsonInputFile = sessionInputJson
    }

    func addTaskRelatedInfoTo(taskInfo: SenseyeTask) {
        var newTaskJsonObject = JSON()


        // taskID
        newTaskJsonObject["taskId"].string = taskInfo.taskID

        // timeStamps
        let timestamps = jsonFor(taskInfo.timestamps)
        newTaskJsonObject["timestamps"] = timestamps

        // eventXLOC
        let eventXLOC = jsonFor(taskInfo.eventXLOC)
        newTaskJsonObject["eventXLOC"] = eventXLOC

        // eventYLOC
        let eventYLOC = jsonFor(taskInfo.eventYLOC)
        newTaskJsonObject["eventYLOC"] = eventYLOC

        // eventImageID
        let eventImageID = jsonFor(taskInfo.eventImageID)
        newTaskJsonObject["eventImageID"] = eventImageID

        // eventBackgroundColor
        let eventBackgroundColor = jsonFor(taskInfo.eventBackgroundColor)
        newTaskJsonObject["eventBackgroundColor"] = eventBackgroundColor


        let previousTaskObjects = self.currentSessionJsonInputFile?["tasks"].array
        if !(previousTaskObjects?.isEmpty ?? true) {
            var taskObjectList: [JSON] = []
            for previousTaskObject in previousTaskObjects! {
                taskObjectList.append(previousTaskObject)
            }
            taskObjectList.append(newTaskJsonObject)
            self.currentSessionJsonInputFile?["tasks"] = JSON(taskObjectList)
        } else {
            self.currentSessionJsonInputFile?["tasks"] = [newTaskJsonObject]
        }

        Log.info(self.currentSessionJsonInputFile?.stringValue ?? "")
        
    }

    func jsonFor<T>(_ taskInfo: T?) -> JSON {
        let list = taskInfo.map { JSON($0) }
        let object = JSON(list ?? [])
        return object
    }


    func addTaskRelatedInfoToSessionJson(taskId: String, taskTimestamps: [Int64]) {
        var newTaskJsonObject = JSON()
        newTaskJsonObject["taskId"].string = taskId
        let timestampList = taskTimestamps.map { JSON($0)}
        let taskTimestampJsonObject = JSON(timestampList)
        newTaskJsonObject["timestamps"] = taskTimestampJsonObject
        
        let previousTaskObjects = self.currentSessionJsonInputFile?["tasks"].array
        if !(previousTaskObjects?.isEmpty ?? true) {
            var taskObjectList: [JSON] = []
            for previousTaskObject in previousTaskObjects! {
                taskObjectList.append(previousTaskObject)
            }
            taskObjectList.append(newTaskJsonObject)
            self.currentSessionJsonInputFile?["tasks"] = JSON(taskObjectList)
        } else {
            self.currentSessionJsonInputFile?["tasks"] = [newTaskJsonObject]
        }
        
        Log.info(self.currentSessionJsonInputFile?.stringValue ?? "")
    }
    
    /**
     Upload JSON file for the current session
     */
    func uploadSessionJsonFile() {

        guard shouldSkipUpload else {
            Log.info("Skipping JSON Upload")
            return
        }
        
        if hasUploadedJsonFile {
            return
        }
        
        do {
            guard let sessionJsonFile = try currentSessionJsonInputFile?.rawData() else {
                Log.error("Error in json parsing for input file")
                return
            }
            
            var uploadS3URLs: [String] = []
            for localFileNameKey in currentSessionUploadFileKeys {
                uploadS3URLs.append(s3HostBucketUrl+localFileNameKey)
                Log.debug("\(s3HostBucketUrl+localFileNameKey)")
            }
            
            let currentTimeStamp = Date().currentTimeMillis()
            let jsonFileName = "\(s3FolderName)/\(username)_\(currentTimeStamp)_ios_input.json"
            Amplify.Storage.uploadData(
                key: jsonFileName,
                data: sessionJsonFile,
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
    
    /**
     Periodically checks the prediction job id's status from the server until a result is available. On success or failure of newtork response, a completion closure will run.
     Additionally, an optional delegate action may be run on a 'completed' or 'failed' job response.
     - Parameters:
     - completed: Optional completion action for success or failure of a a network response.
     */
    func startPeriodicUpdatesOnPredictionId(completed: @escaping (Result<String, Error>) -> Void) {
        
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
                        Log.info("Prediction periodic request success and result retrieved! \(jobStatusAndResultResponse)")
                        completed(.success(jobStatusAndResultResponse.status))
                        self.delegate?.didReturnResultForPrediction(status: jobStatusAndResultResponse.status)
                        timer.invalidate()
                    } else {
                        Log.info("Prediction periodic request not done yet, will try again. \(jobStatusAndResultResponse)")
                    }
                case let .failure(failure):
                    Log.warn("Prediction periodic request failure \(failure)")
                    
                    // Failure to return a prediction
                    completed(.failure(failure))
                    timer.invalidate()
                }
            }
        }
    }
    
    func downloadIndividualImageAssets(imageS3Key: String, successfullCompletion: @escaping () -> Void) {
        
        guard let imageName = imageS3Key.split(separator: "/").last, let filePath = fileDestUrl?.appendingPathComponent("\(imageName)") else {
            return
        }
        print(imageS3Key)
        
        if !self.fileManager.fileExists(atPath: filePath.path) {
            Amplify.Storage.downloadData(
                key: imageS3Key,
                progressListener: { progress in
                    Log.info("Progress: \(progress)")
                }, resultListener: { (event) in
                    switch event {
                    case let .success(data):
                        Log.info("Completed: \(data)")
                        do {
                            try data.write(to: filePath)
                            successfullCompletion()
                        } catch {
                            Log.error("Failed write")
                        }
                    case let .failure(storageError):
                        Log.error("Failed: \(storageError.errorDescription). \(storageError.recoverySuggestion)")
                    }
                })
        } else {
            successfullCompletion()
        }
    }
}

@available(iOS 14.0, *)
extension FileUploadAndPredictionService: FileUploadAndPredictionServiceProtocol { }
