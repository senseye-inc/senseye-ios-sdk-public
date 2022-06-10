//
//  File.swift
//  
//
//  Created by Frank Oftring on 4/7/22.
//

import Foundation

@available(iOS 13.0, *)
class ResultsViewModel: ObservableObject {
    
    init(fileUploadService: FileUploadAndPredictionServiceProtocol = FileUploadAndPredictionService()) {
        self.fileUploadService = fileUploadService
    }
    
    let fileUploadService: FileUploadAndPredictionServiceProtocol
    
    @Published var predictionStatus: String = "(Default Status)"
    @Published var isLoading: Bool = false
    @Published var error: Error?
    
    func startPredictions() {
        isLoading = true
        DispatchQueue.main.async {
            self.getPredictionResponse()
            self.startPeriodicPredictions()
        }
    }
    
    func getPredictionResponse() {
        fileUploadService.startPredictionForCurrentSessionUploads { result in
            self.predictionStatus = "Starting predictions..."
            Log.info("Starting predictions")
            DispatchQueue.main.async {
                switch result {
                case .success(let predictionJobResponse):
                    Log.debug("entering success completion")
                    Log.info("Prediction Job Response: \(predictionJobResponse)")
                    self.predictionStatus = "Prediction API request sent..."
                    
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
                    self.predictionStatus = "Returned a result for prediction... \(jobStatusAndResultResponse)"
                case .failure(let error):
                    Log.error("Error from \(#function): \(error.localizedDescription)")
                    self.error = error
                }
                self.isLoading = false
            }
        }
    }
    
}
