//
//  ImageViewModel.swift
//
//
//  Created by Frank Oftring on 5/23/22.
//

import Foundation
import Combine
import SwiftUI

@available(iOS 14.0, *)
class RotatingImageViewModel: ObservableObject, TaskViewModelProtocol {
    
    init(fileUploadService: FileUploadAndPredictionServiceProtocol) {
        self.fileUploadService = fileUploadService
    }
    
    let fileUploadService: FileUploadAndPredictionServiceProtocol
    
    let affectiveImageNames: [String] = ["fire_9", "stream", "leaves_3", "desert_3", "acorns_1", "desert_2", "fire_7", "water"]

    @Published var shouldShowConfirmationView: Bool = false
    @Published var currentImageIndex: Int = 0 {
        willSet {
            eventImageID.append(affectiveImageNames[currentImageIndex])
        }
    }

    var numberOfImagesShown = 0
    var totalNumberOfImagesToBeShown = 24
    var numberOfImageSetsShown: Int = 1
    private var eventImageID: [String] = []
    private var timestampsOfImageSwap: [Int64] = []

    var finishedAllTasks: Bool {
        numberOfImagesShown >= affectiveImageNames.count
    }
    
    private let fileDestUrl: URL? = FileManager.default.urls(for: .documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first
    var currentImageName: URL? {
        let imageKey = affectiveImageNames[currentImageIndex]
        let fullFileName = fileDestUrl?.appendingPathComponent("\(imageKey).png")
        return fullFileName
    }

    var taskCompleted: String {
        "PTSD \(numberOfImagesShown)/\(affectiveImageNames.count)"
    }
    
    private var fileManager: FileManager = FileManager.default
    
    func downloadPtsdImageSetsIfRequired(didFinishDownloadingAssets: @escaping () -> Void) {
        let dispatchGroup = DispatchGroup()
        for imageKey in affectiveImageNames {
            dispatchGroup.enter()
            //public/ptsd_image_sets/acorns_1.png
            let s3imageKey = "ptsd_image_sets/\(imageKey).png"
            fileUploadService.downloadIndividualImageAssets(imageS3Key: s3imageKey) {
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
        Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { [self] timer in
            numberOfImagesShown += 1
            timestampsOfImageSwap.append(Date().currentTimeMillis())
            if currentImageIndex < affectiveImageNames.count - 1 {
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
        self.numberOfImagesShown -= (self.affectiveImageNames.count)
    }

    private func reset() {
        currentImageIndex = 0
    }
    
    func addTaskInfoToJson() {
        let taskInfo = SenseyeTask(taskID: "ptsd_image_set", frameTimestamps: fileUploadService.getLatestFrameTimestampArray(), timestamps: timestampsOfImageSwap, eventImageID: eventImageID)
        fileUploadService.addTaskRelatedInfo(for: taskInfo)
    }
}
