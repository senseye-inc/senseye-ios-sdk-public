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

@available(iOS 13.0, *)
protocol FileUploadAndPredictionServiceProtocol {
    func startPredictionForCurrentSessionUploads(completed: @escaping (Result<String, Error>) -> Void)
    func startPeriodicUpdatesOnPredictionId(completed: @escaping (Result<String, Error>) -> Void)
    var uploadProgress: Double { get }
    var uploadProgressPublished: Published<Double> { get}
    var uploadProgressPublisher: Published<Double>.Publisher { get }
    var numberOfUploads: Double { get }
    func downloadIndividualImageAssets(imageS3Key: String, successfullCompletion: @escaping () -> Void)
    func uploadData(fileUrl: URL)
    func createSessionInputJsonFile(surveyInput: [String: String], tasks: [String])
}

protocol FileUploadAndPredictionServiceDelegate: AnyObject {
    func didFinishUpload()
    func didFinishPredictionRequest()
    func didReturnResultForPrediction(status: String)
}

/**
 FileUploadAndPredictionService is responsible for communicating with backend service.
 */
@available(iOS 13.0, *)
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
    
    private var accountUsername: String? = ""
    private var accountPassword: String? = ""
    private var temporaryPassword: String? = ""
    private let hostApi =  "https://apeye.senseye.co"
    private var hostApiKey: String? = nil
    private var sessionTimeStamp: Int64
    private var username: String
    private var s3FolderName: String {
        return "\(username)_\(sessionTimeStamp)"
    }
    private let s3HostBucketUrl = "s3://senseyeiossdk98d50aa77c5143cc84a829482001110f111246-dev/public/"
    
    private var currentSessionUploadFileKeys: [String] = []
    private var currentSessionPredictionId: String = ""
    private var currentSessionJsonInputFile: Data? = nil

    var isUploadOngoing: Bool = false
    private var fileManager: FileManager
    private var fileDestUrl: URL?
    weak var delegate: FileUploadAndPredictionServiceDelegate?
    
    init(username: String) {
        self.fileManager = FileManager.default
        fileDestUrl = fileManager.urls(for: .documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first
        self.sessionTimeStamp = Date().currentTimeMillis()
        self.username = username
        self.setUserApiKey()
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
        
        guard let _ = self.hostApiKey else {
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
    
    private func setUserApiKey() {
        Amplify.Auth.fetchUserAttributes() { result in
            switch result {
            case .success(let attributes):
                if let attribute = attributes.first(where: { $0.key == AuthUserAttributeKey.custom("senseye_api_token") }) {
                    self.hostApiKey = attribute.value
                    Log.debug("Found and set senseye_api_token")
                } else {
                    Log.warn("unable to set api key")
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
    func createSessionInputJsonFile(surveyInput: [String: String], tasks: [String]) {
        var sessionInputJson = JSON()
        sessionInputJson["tasks"].string = tasks.joined(separator: ",")
        sessionInputJson["versionName"].string = "0.0.0"
        sessionInputJson["versionCode"].string = "0"
        for inputItem in surveyInput {
            sessionInputJson[inputItem.key].string = inputItem.value
        }
        
        do {
            try self.currentSessionJsonInputFile = sessionInputJson.rawData()
        } catch {
            Log.error("Error in json parsing for input file")
        }
        
    }
    
    /**
     Submits a prediction job to the server.
     - Parameters:
     - completed: Optional completion action for success or failure of a a network response.
     */
    func startPredictionForCurrentSessionUploads(completed: @escaping (Result<String, Error>) -> Void) {
        
        guard let sessionJsonFile = currentSessionJsonInputFile else {
            return
        }
        
        var uploadS3URLs: [String] = []
        for localFileNameKey in currentSessionUploadFileKeys {
            uploadS3URLs.append(s3HostBucketUrl+localFileNameKey)
            Log.debug("\(s3HostBucketUrl+localFileNameKey)")
        }
        
        let currentTimeStamp = Date().currentTimeMillis()
        let jsonFileName = "\(currentTimeStamp)_ios_input.json"
        let s3JsonFileName = "\(s3HostBucketUrl)\(jsonFileName)"
        Amplify.Storage.uploadData(
            key: jsonFileName,
            data: sessionJsonFile,
            progressListener: { progress in
                Log.info("Progress: \(progress)")
            }, resultListener: { event in
                switch event {
                case let .success(data):
                    Log.debug("Data: \(data)")
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
                            Log.info("Prediction request success \(predictionJobResponse)")
                            self.currentSessionPredictionId = predictionJobResponse.id
                            self.delegate?.didFinishPredictionRequest()
                            completed(.success(predictionJobResponse.id))
                        case let .failure(failure):
                            Log.warn("Prediction request failure \(failure)")
                            
                            // Network related error
                            completed(.failure(failure))
                        }
                    }
                case let .failure(storageError):
                    Log.warn("Failed: \(storageError.errorDescription). \(storageError.recoverySuggestion)")
                    completed(.failure(storageError))
                }
            }
        )
        
        
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

@available(iOS 13.0, *)
extension FileUploadAndPredictionService: FileUploadAndPredictionServiceProtocol { }
