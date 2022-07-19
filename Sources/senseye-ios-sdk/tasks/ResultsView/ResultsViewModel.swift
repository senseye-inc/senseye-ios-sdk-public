//
//  File.swift
//  
//
//  Created by Frank Oftring on 4/7/22.
//

import Foundation
import Combine

@available(iOS 14.0, *)
class ResultsViewModel: ObservableObject {
    
    init(fileUploadService: FileUploadAndPredictionServiceProtocol) {
        self.fileUploadService = fileUploadService
        getUploadProgress()
    }
    
    var fileUploadService: FileUploadAndPredictionServiceProtocol
    var cancellables = Set<AnyCancellable>()
    
    @Published var error: Error?
    @Published var uploadProgress: Double = 0.0

    func getUploadProgress() {
        fileUploadService.uploadProgressPublisher
            .sink { uploadProgress in
                self.uploadProgress = uploadProgress / self.fileUploadService.numberOfUploads
            }
            .store(in: &cancellables)
    }
    
    enum PredictionStatus: Equatable {
        case none
        case startingPredictions
        case apiRequestSent
        case returnedPrediction(String)

        var status: String {
            switch self {
            case .none:
                return "Default Status"
            case .startingPredictions:
                return "Starting predictions..."
            case .apiRequestSent:
                return "Prediction API request sent..."
            case .returnedPrediction(let jobStatusAndResultResponse):
                return "Returned a result for prediction... \(jobStatusAndResultResponse)"
            }
        }
    }
    
    func uploadJsonSessionFile() {
        self.fileUploadService.uploadSessionJsonFile()
    }
}
