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
            .sink(receiveValue: { [weak self] newUploadProgress in
                guard let self = self else { return }
                let updatedUploadProgress = newUploadProgress / self.fileUploadService.numberOfUploads
                self.uploadProgress = updatedUploadProgress.rounded(toPlaces: 2)
                Log.info("UploadProgress: \(self.uploadProgress)", shouldLogContext: true)
            })
            .store(in: &cancellables)
    }
    
    func uploadJsonSessionFile() {
        self.fileUploadService.uploadSessionJsonFile()
    }
}
