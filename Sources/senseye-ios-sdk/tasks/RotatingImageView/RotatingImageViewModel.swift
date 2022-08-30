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
    
    init(fileUploadService: FileUploadAndPredictionServiceProtocol, imageService: ImageService) {
        self.fileUploadService = fileUploadService
        self.imageService = imageService
        addSubscribers()
    }
    
    let fileUploadService: FileUploadAndPredictionServiceProtocol
    let imageService: ImageService
    var taskBlockNumber: Int = 0
    private var taskTiming: Double {
        get {
            if (fileUploadService.enableDebugMode) {
                return fileUploadService.debugModeTaskTiming
            } else {
                return 5.0
            }
        }
    }
    
    @Published var shouldShowConfirmationView: Bool = false
    @Published var isLoading: Bool = true
    @Published var images: [Image?] = []
    @Published var isFinished: Bool = false
    @Published var currentImageIndex: Int = 0 {
        willSet {
            let currentImage = (imageService.imageSetForBlockNumber(blockNumber: taskBlockNumber))[currentImageIndex]
            eventImageID.append(currentImage.imageName)
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    private var fileManager: FileManager = FileManager.default
    private var timestampsOfImageSwap: [Int64] = []
    private var eventImageID: [String] = []
    private let fileDestUrl: URL? = FileManager.default.urls(for: .documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first
    
    var numberOfImagesShown = 0
    var totalNumberOfImagesToBeShown = 24
    var currentImage: Image?

    var finishedAllTasks: Bool {
        numberOfImagesShown >= affectiveImagesCount
    }
    
    var taskCompleted: String {
        "PTSD \(numberOfImagesShown)/\(affectiveImagesCount)"
    }
    
    var affectiveImagesCount: Int {
        imageService.imageSetForBlockNumber(blockNumber: taskBlockNumber).count
    }
    
    func showImages() {
        Log.info("in show images ---")
        isLoading = false
        updateCurrentImage()
        Timer.scheduledTimer(withTimeInterval: taskTiming, repeats: true) { [self] timer in
            numberOfImagesShown += 1
            if currentImageIndex < affectiveImagesCount - 1 {
                currentImageIndex += 1
                addTimestampOfImageDisplay()
                updateCurrentImage()
            } else {
                timer.invalidate()
                shouldShowConfirmationView.toggle()
                isFinished = true
                Log.info("RotatingImageViewModel Timer Cancelled")
            }
        }
        addTimestampOfImageDisplay()
    }
    
    private func addTimestampOfImageDisplay() {
        let timestamp = Date().currentTimeMillis()
        timestampsOfImageSwap.append(timestamp)
        Log.info("Adding image swap event timestamp \(currentImageIndex) --- \(timestamp)")
    }
    
    func removeLastImageSet() {
        numberOfImagesShown -= (affectiveImagesCount)
    }
    
    func checkForImages() {
        Log.info("in check for images ---")
        self.updateImageSetIfAvailable()
    }
    
    func reset() {
        isFinished = false
        currentImageIndex = 0
        timestampsOfImageSwap.removeAll()
    }
    
    func addTaskInfoToJson() {
        let taskInfo = SenseyeTask(taskID: "ptsd_image_set", frameTimestamps: fileUploadService.getLatestFrameTimestampArray(), timestamps: timestampsOfImageSwap, eventImageID: eventImageID)
        fileUploadService.addTaskRelatedInfo(for: taskInfo)
    }
    
    func updateCurrentImage() {
        currentImage = images[currentImageIndex]
    }
    
    func addSubscribers() {
        Log.info("in add subscribers ---")
        imageService.$senseyeImages
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in
                Log.info("in receive completion ---")
                self.updateImageSetIfAvailable()
            }, receiveValue: { _ in
                Log.info("in receive value ---")
                self.updateImageSetIfAvailable()
            })
    }
    
    private func updateImageSetIfAvailable() {
        Log.info("in update image set ---")
        let imageSetForBlock = imageService.imageSetForBlockNumber(blockNumber: taskBlockNumber).map { Image(uiImage: $0.image) }
        guard !imageSetForBlock.isEmpty else {
            return
        }
        self.images = imageSetForBlock
        self.showImages()
    }
}
