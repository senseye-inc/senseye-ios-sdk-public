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

protocol FileUploadAndPredictionServiceProtocol {
    func startPredictionForCurrentSessionUploads(completed: @escaping (Result<String, Error>) -> Void)
    func startPeriodicUpdatesOnPredictionId(completed: @escaping (Result<String, Error>) -> Void)
}

protocol FileUploadAndPredictionServiceDelegate: AnyObject {
    func didFinishUpload()
    func didFinishPredictionRequest()
    func didReturnResultForPrediction(status: String)
}

/**
 FileUploadAndPredictionService is responsible for communicating with backend service.
 */
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
    private let hostApi =  "https://apeye.senseye.co"
    private var hostApiKey: String? = nil
    private let s3HostBucketUrl = "s3://senseyeiossdk98d50aa77c5143cc84a829482001110f111246-dev/public/"
    
    private var currentSessionUploadFileKeys: [String] = []
    private var currentSessionPredictionId: String = ""
    private var currentSessionJsonInputFile: Data? = nil
    
    var isUploadOngoing: Bool = false
    weak var delegate: FileUploadAndPredictionServiceDelegate?
    
    init() {
        self.setUserApiKey()
    }
    
    
    /**
     Uploads a video file to the server after ensuring signed in session matches user entry at login,
     authenticating the session, and fetching host api key.
     
     - Parameters:
     - fileUrl: URL of the video file to upload
     */
    func uploadData(fileUrl: URL) {
        let fileNameKey = fileUrl.lastPathComponent
        let filename = fileUrl
        
        guard let _ = self.hostApiKey else {
            return
        }
        
        self.uploadFile(fileNameKey: fileNameKey, filename: filename)
    }
    
    private func uploadFile(fileNameKey: String, filename: URL) {
        isUploadOngoing = true
        print("About to upload - video url: \(filename)")
        
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
                    print("Failed: \(storageError.errorDescription). \(storageError.recoverySuggestion). File: \(#file), line: \(#line), video url: \(filename)")
                    self.isUploadOngoing = false
                }
            }
        )
    }
    
    private func setUserApiKey() {
        Amplify.Auth.fetchUserAttributes() { result in
            switch result {
            case .success(let attributes):
                if let attribute = attributes.first(where: { $0.key == AuthUserAttributeKey.custom("senseye_api_token") }) {
                    self.hostApiKey = attribute.value
                    print("Found and set senseye_api_token")
                } else {
                    print("unable to set api key")
                }
                print("Host api key: \(self.hostApiKey)")
            case .failure(let authError):
                print("Fetching user attribute senseye_api_token failed: \(authError)")
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
            print("Error in json parsing for input file")
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
                            completed(.success(predictionJobResponse.id))
                        case let .failure(failure):
                            print("Prediction request failure \(failure)")
                            
                            // Network related error
                            completed(.failure(failure))
                        }
                    }
                case let .failure(storageError):
                    print("Failed: \(storageError.errorDescription). \(storageError.recoverySuggestion)")
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
                        print("Prediction periodic request success and result retrieved! \(jobStatusAndResultResponse)")
                        completed(.success(jobStatusAndResultResponse.status))
                        self.delegate?.didReturnResultForPrediction(status: jobStatusAndResultResponse.status)
                        timer.invalidate()
                    } else {
                        print("Prediction periodic request not done yet, will try again. \(jobStatusAndResultResponse)")
                    }
                case let .failure(failure):
                    print("Prediction periodic request failure \(failure)")
                    
                    // Failure to return a prediction
                    completed(.failure(failure))
                    timer.invalidate()
                }
            }
        }
    }
}

extension FileUploadAndPredictionService: FileUploadAndPredictionServiceProtocol { }
