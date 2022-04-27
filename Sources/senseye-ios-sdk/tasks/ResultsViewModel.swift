//
//  File.swift
//  
//
//  Created by Frank Oftring on 4/7/22.
//

import Foundation

@available(iOS 13.0, *)
class ResultsViewModel: ObservableObject {
    
    init(fileUploadService: FileUploadAndPredictionServiceProtocol) {
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
            print("Starting predictions")
            DispatchQueue.main.async {
                switch result {
                case .success(let predictionJobResponse):
                    print("entering success completion")
                    print("Prediction Job Response: \(predictionJobResponse)")
                    
                    self.predictionStatus = "Prediction API request sent..."
                    
                case .failure(let predictionError):
                    print("entering failure completion")
                    
                    self.error = predictionError
                    
                    print("Error from \(#function): \(predictionError.localizedDescription)")
                }
            }
        }
    }
    
    func startPeriodicPredictions() {
        fileUploadService.startPeriodicUpdatesOnPredictionId { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let jobStatusAndResultResponse):
                    print("Success from view model: \(jobStatusAndResultResponse)")
                    self.predictionStatus = "Returned a result for prediction... \(jobStatusAndResultResponse)"
                case .failure(let error):
                    print("Error from \(#function): \(error.localizedDescription)")
                }
                self.isLoading = false
            }
        }
    }
    
}
