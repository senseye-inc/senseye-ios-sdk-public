//
//  ImageViewModel.swift
//
//
//  Created by Frank Oftring on 5/23/22.
//

import Foundation
import Combine
import SwiftUI

@available(iOS 13.0, *)
class RotatingImageViewModel: ObservableObject {
    
    init(fileUploadService: FileUploadAndPredictionServiceProtocol) {
        self.fileUploadService = fileUploadService
    }
    
    let fileUploadService: FileUploadAndPredictionServiceProtocol
    
    let ptsdImageNames: [String] = ["fire_9", "stream", "leaves_3", "desert_3", "acorns_1", "desert_2", "fire_7", "water"]

    @Published var shouldShowConfirmationView: Bool = false
    @Published var currentImageIndex: Int = 0

    var numberOfImagesShown = 0
    var timerCount: Int = 0
    var numberOfImageSetsShown: Int = 1

    var finishedAllTasks: Bool {
        numberOfImagesShown >= ptsdImageNames.count
    }
    var currentImageName: String {
        let imageKey = ptsdImageNames[currentImageIndex]
        let downloadToFileName = self.fileManager.urls(for: .documentDirectory,
                                                          in: .userDomainMask)[0]
        downloadToFileName.appendingPathComponent("\(imageKey).png")
        return downloadToFileName.path
    }

    var taskCompleted: String {
        "PTSD \(numberOfImagesShown)/\(ptsdImageNames.count)"
    }
    
    private var fileManager: FileManager = FileManager.default
    
    func downloadPtsdImageSetsIfRequired(didFinishDownloadingAssets: @escaping () -> Void) {
        let dispatchGroup = DispatchGroup()
        for imageKey in ptsdImageNames {
            dispatchGroup.enter()
            fileUploadService.downloadIndividualImageAssets(imageKey: imageKey) {
                dispatchGroup.leave()
            }
        }
        dispatchGroup.notify(queue: DispatchQueue.global()) {
            Log.debug("All ptsd assets are downloaded")
            didFinishDownloadingAssets()
        }
    }

    func showImages(didFinishCompletion: @escaping () -> Void) {
        numberOfImageSetsShown += 1
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [self] timer in
            timerCount += 1
            numberOfImagesShown += 1
            if timerCount < ptsdImageNames.count {
                currentImageIndex += 1
            } else {
                timer.invalidate()
                Log.info("RotatingImageViewModel Timer Cancelled")
                reset()
                didFinishCompletion()
            }
        }
    }

    func removeLastImageSet() {
        self.numberOfImagesShown -= (self.ptsdImageNames.count)
    }

    private func reset() {
        currentImageIndex = 0
        timerCount = 0
    }
}


