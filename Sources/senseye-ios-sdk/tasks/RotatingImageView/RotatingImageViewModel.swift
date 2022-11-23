//
//  ImageViewModel.swift
//
//
//  Created by Frank Oftring on 5/23/22.
//

import Foundation
import Combine
import SwiftUI

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
                return 2.5
            }
        }
    }

    private var isCensorModeEnabled: Bool { fileUploadService.isCensorModeEnabled }
    
    @Published var shouldShowConfirmationView: Bool = false
    @Published var isLoading: Bool = true
    @Published var images: [SenseyeImage] = []
    @Published var isFinished: Bool = false
    @Published var currentImageIndex: Int = 0
    
    private var cancellables = Set<AnyCancellable>()
    private var fileManager: FileManager = FileManager.default
    private var timestampsOfImageSwap: [Int64] = []
    private var eventImageID: [String] = []
    private let fileDestUrl: URL? = FileManager.default.urls(for: .documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first
    
    var currentImage: UIImage?
    
    private var rotatingImageTimer: Timer? = nil
    
    func showImages() {
        Log.info("in show images ---")
        isLoading = false
        startImageTimer()
    }
    
    private func startImageTimer() {
        if (rotatingImageTimer == nil) {
            updateCurrentImage()
            Log.info("RotatingImageViewModel creating timer")
            addTimestampOfImageDisplay()
            rotatingImageTimer = Timer.scheduledTimer(withTimeInterval: taskTiming, repeats: true) { [self] timer in
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
        eventImageID.append(currentImage.imageName)
        Log.info("Adding Image: \(currentImage.imageName) swap event timestamp \(currentImageIndex) --- \(timestamp)")
    }
    
    func checkForImages() {
        Log.info("in check for images ---")
        guard let blockNumer = self.tabInfo?.taskBlockNumber else { return }
        imageService.checkForImages(at: blockNumer)
        addSubscribers()
    }
    
    func reset() {
        isFinished = false
        currentImageIndex = 0
        currentImage = nil
        eventImageID.removeAll()
        timestampsOfImageSwap.removeAll()
        cancellables.removeAll()
    }
    
    func addTaskInfoToJson() {
        let taskInfo = SenseyeTask(taskID: "ptsd_image_set", frameTimestamps: fileUploadService.getLatestFrameTimestampArray(), timestamps: timestampsOfImageSwap, eventImageID: eventImageID, blockNumber: tabInfo?.taskBlockNumber, category: tabInfo?.taskCategory, subcategory: tabInfo?.taskSubcategory, videoPath: fileUploadService.getVideoPath())
        fileUploadService.addTaskRelatedInfo(for: taskInfo)
    }
    
    func updateCurrentImage() {
        let category = imageService.getCategory(of: images[currentImageIndex].imageName)
        if isCensorModeEnabled, category == .negativeArousal {
            currentImage = ["🙈","🙉","🙊"].randomElement()!.textToImage()!
        } else {
            let retreivedImage = UIImage(contentsOfFile: images[currentImageIndex].imageUrl)
            currentImage = retreivedImage
        }
    }
    
    func addSubscribers() {
        Log.info("in add subscribers ---")
        imageService.$imagesForBlock
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] imageSetForBlock in
                Log.info("in callback of imagesForBlock ---")
                guard let self = self else {
                    return
                }
                Log.info("image set count \(imageSetForBlock.count)")
                if (!(imageSetForBlock.isEmpty || imageSetForBlock.count != 8) && self.currentImageIndex == 0) {
                    self.images = imageSetForBlock
                    self.showImages()
                }
            })
            .store(in: &cancellables)
    }
    
}

struct RotatingImageViewTaskInfo {
    let taskBlockNumber: Int?
    let taskCategory: TaskBlockCategory?
    let taskSubcategory: TaskBlockSubcategory?
}
