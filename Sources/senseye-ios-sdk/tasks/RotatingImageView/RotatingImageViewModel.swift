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
    }
    
    let fileUploadService: FileUploadAndPredictionServiceProtocol
    let imageService: ImageService
    var tabInfo: RotatingImageViewTaskInfo?
    private var taskTiming: Double {
        get {
            if (fileUploadService.isDebugModeEnabled) {
                return fileUploadService.debugModeTaskTiming
            } else {
                return 5.0
            }
        }
    }
    
    @Published var shouldShowConfirmationView: Bool = false
    @Published var isLoading: Bool = true
    @Published var images: [(String, Image)] = []
    @Published var isFinished: Bool = false
    @Published var currentImageIndex: Int = 0
    
    private var cancellables = Set<AnyCancellable>()
    private var fileManager: FileManager = FileManager.default
    private var timestampsOfImageSwap: [Int64] = []
    private var eventImageID: [String] = []
    private let fileDestUrl: URL? = FileManager.default.urls(for: .documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first
    
    var numberOfImagesShown = 0
    var currentImage: Image?

    var finishedAllTasks: Bool {
        numberOfImagesShown >= images.count
    }
    
    private var rotatingImageTimer: Timer? = nil
    
    func showImages() {
        Log.info("in show images ---")
        isLoading = false
        startImageTimer()
        addTimestampOfImageDisplay()
    }
    
    private func startImageTimer() {
        updateCurrentImage()
        Log.info("RotatingImageViewModel creating timer")
        if (rotatingImageTimer == nil) {
            rotatingImageTimer = Timer.scheduledTimer(withTimeInterval: taskTiming, repeats: true) { [self] timer in
                numberOfImagesShown += 1
                if currentImageIndex < images.count - 1 {
                    currentImageIndex += 1
                    addTimestampOfImageDisplay()
                    updateCurrentImage()
                } else {
                    shouldShowConfirmationView.toggle()
                    isFinished = true
                    Log.info("RotatingImageViewModel Timer Cancelled")
                    stopImageTimer()
                }
            }
        }
    }
    
    private func stopImageTimer() {
        if (rotatingImageTimer != nil) {
            rotatingImageTimer?.invalidate()
            rotatingImageTimer = nil
        }
    }
    
    private func addTimestampOfImageDisplay() {
        let timestamp = Date().currentTimeMillis()
        timestampsOfImageSwap.append(timestamp)
        let currentImage = images[currentImageIndex]
        eventImageID.append(currentImage.0)
        Log.info("Adding Image: \(currentImage.0) swap event timestamp \(currentImageIndex) --- \(timestamp)")
    }
    
    func removeLastImageSet() {
        numberOfImagesShown -= (images.count)
    }
    
    func checkForImages() {
        guard let currentBlockNumber = self.tabInfo?.taskBlockNumber else {
            return
        }
        Log.info("in check for images ---")
        imageService.updateImagesForBlock(blockNumber: currentBlockNumber)
        addSubscribers()
    }
    
    func reset() {
        isFinished = false
        currentImageIndex = 0
        eventImageID.removeAll()
        timestampsOfImageSwap.removeAll()
        cancellables.removeAll()
    }
    
    func addTaskInfoToJson() {
        let taskInfo = SenseyeTask(taskID: "ptsd_image_set", frameTimestamps: fileUploadService.getLatestFrameTimestampArray(), timestamps: timestampsOfImageSwap, eventImageID: eventImageID, blockNumber: tabInfo?.taskBlockNumber, category: tabInfo?.taskCategory, subcategory: tabInfo?.taskSubcategory)
        fileUploadService.addTaskRelatedInfo(for: taskInfo)
    }
    
    func updateCurrentImage() {
        currentImage = images[currentImageIndex].1
    }
    
    func addSubscribers() {
        Log.info("in add subscribers ---")
        imageService.$imagesForBlock
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] imageSetForBlock in
                guard let self = self else {
                    return
                }
                print(imageSetForBlock)
                self.images = imageSetForBlock
                self.showImages()
            })
            .store(in: &cancellables)
    }
    
}

struct RotatingImageViewTaskInfo {
    let taskBlockNumber: Int?
    let taskCategory: TaskBlockCategory?
    let taskSubcategory: TaskBlockSubcategory?
}
