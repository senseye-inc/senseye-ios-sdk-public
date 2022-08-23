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
    
    @Published var shouldShowConfirmationView: Bool = false
    @Published var isLoading: Bool = true
    @Published var images: [Image?] = []
    @Published var isFinished: Bool = false
    @Published var currentImageIndex: Int = 0
    
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
        imageService.affectiveImageNames.count
    }
    
    func showImages() {
        isLoading = false
        updateCurrentImage()
        Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { [self] timer in
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
        let imageName = imageService.affectiveImageNames[currentImageIndex]
        timestampsOfImageSwap.append(timestamp)
        eventImageID.append(imageName)
        Log.info("Adding image swap event timestamp \(currentImageIndex) --- \(timestamp)")
    }
    
    func removeLastImageSet() {
        numberOfImagesShown -= (affectiveImagesCount)
    }
    
    func checkForImages() {
        guard !images.isEmpty else { return }
        showImages()
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
        imageService.$senseyeImages
            .receive(on: DispatchQueue.main)
            .map({ senseyeImages -> [Image] in
                senseyeImages.map { Image(uiImage: $0.image) }
            })
            .sink(receiveCompletion: { completion in
                Log.info("Completed from \(#function): \(completion)")
                self.showImages()
            }, receiveValue: { images in
                self.images = images
                guard self.images.count == self.affectiveImagesCount else {
                    return
                }
                Log.info("Showing images")
                self.showImages()
            })
            .store(in: &cancellables)
    }
    
}
