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
    
    @Published var predictionStatus: PredictionStatus = .none
    @Published var isLoading: Bool = false
    @Published var error: Error?
    @Published var uploadProgress: Double = 0.0

    var isUploadFinished: Bool {
        uploadProgress >= 1.0
    }

    func getUploadProgress() {
        fileUploadService.uploadProgressPublisher
            .sink { uploadProgress in
                self.uploadProgress = uploadProgress / self.fileUploadService.numberOfUploads
            }
            .store(in: &cancellables)
    }
    
    func startPredictions() {
        isLoading = true
        DispatchQueue.main.async {
            self.getPredictionResponse()
            self.startPeriodicPredictions()
        }
    }
    
    func getPredictionResponse() {
        fileUploadService.startPredictionForCurrentSessionUploads { result in
            Log.info("Starting predictions")
            DispatchQueue.main.async {
                self.predictionStatus = .startingPredictions
                switch result {
                case .success(let predictionJobResponse):
                    Log.debug("entering success completion")
                    Log.info("Prediction Job Response: \(predictionJobResponse)")
                    self.predictionStatus = .apiRequestSent
                    
                case .failure(let predictionError):
                    Log.debug("entering failure completion")
                    Log.info("Error from \(#function): \(predictionError.localizedDescription)")
                    self.error = predictionError
                }
            }
        }
    }
    
    func startPeriodicPredictions() {
        fileUploadService.startPeriodicUpdatesOnPredictionId { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let jobStatusAndResultResponse):
                    Log.info("Success from view model: \(jobStatusAndResultResponse)")
                    self.predictionStatus = .returnedPrediction(jobStatusAndResultResponse)
                case .failure(let error):
                    Log.error("Error from \(#function): \(error.localizedDescription)")
                    self.error = error
                }
                self.isLoading = false
            }
        }
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
    
}
