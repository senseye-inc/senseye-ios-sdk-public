//
//  FaceDotProbeViewModel.swift
//  
//
//  Created by Frank Oftring on 9/22/22.
//

import SwiftUI
import Combine

@available(iOS 14.0, *)
class AttentionBiasFaceViewModel: ObservableObject {
    @Published var isShowingImages = false
    @Published var isFinished: Bool = false
    @Published var shouldShowConfirmationView: Bool = false
    
    var taskID: String = ""
    var isShowingXMark = true
    var dotLocation: DotLocation?
    var currentTopImage: UIImage?
    var currentBottomImage: UIImage?
    var blockNumber: Int?
    
    let fileUploadService: FileUploadAndPredictionServiceProtocol
    let imageService: ImageService
    
    private var images: [SenseyeImage] = []
    private let fixationDisplayTime = 0.5
    private let facesDisplayTime = 2.0
    private let dotDisplayTime = 0.5
    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer? = nil
    private var timestampsOfStimuli: [Int64] = []
    private var imageInterval = 0
    private var dotInterval = 0
    private var dotLocations: [DotLocation] = [.bottom,.top,.top,.bottom,.bottom,.top, .bottom,.top,.top,.bottom,.bottom,.top, .bottom, .bottom]
    
    init(fileUploadService: FileUploadAndPredictionServiceProtocol, imageService: ImageService) {
        self.fileUploadService = fileUploadService
        self.imageService = imageService
    }
    
    func checkForImages() {
        Log.info("in check for images ---")
        guard let blockNumer = self.blockNumber else { return }
        imageService.checkForImages(at: blockNumer)
        addSubscribers()
    }
    
    private func addSubscribers() {
        imageService.$imagesForBlock
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] faceSetForBlock in
                guard let self = self else { return }
                self.images = faceSetForBlock
                self.showFixationPeriod()
            })
            .store(in: &cancellables)
    }
    
    private func showFixationPeriod() {
        dotLocation = nil
        isShowingXMark = true
        addCurrentTimeToStimuliTimestamps()
        DispatchQueue.main.asyncAfter(deadline: .now() + fixationDisplayTime) {
            self.isShowingXMark = false
            self.showFaces()
        }
    }
    
    private func showFaces() {
        currentTopImage = UIImage(contentsOfFile: images[imageInterval].imageUrl)
        currentBottomImage = UIImage(contentsOfFile: images[imageInterval + 1].imageUrl)
        isShowingImages = true
        addCurrentTimeToStimuliTimestamps()
        DispatchQueue.main.asyncAfter(deadline: .now() + facesDisplayTime) {
            self.showDot()
            self.imageInterval += 2
        }
    }
    
    private func showDot() {
        isShowingImages = false
        dotLocation = dotLocations[dotInterval]
        addCurrentTimeToStimuliTimestamps()
        DispatchQueue.main.asyncAfter(deadline: .now() + dotDisplayTime) {
            if self.imageInterval < self.images.count {
                self.showFixationPeriod()
                self.dotInterval += 1
            } else {
                self.isFinished = true
                self.shouldShowConfirmationView = true
            }
        }
    }
    
    private func addCurrentTimeToStimuliTimestamps() {
        let timestamp = Date().currentTimeMillis()
        timestampsOfStimuli.append(timestamp)
    }
    
    func addTaskInfoToJson() {
        let taskInfo = SenseyeTask(taskID: taskID, frameTimestamps: fileUploadService.getLatestFrameTimestampArray(), timestamps: timestampsOfStimuli, videoPath: fileUploadService.getVideoPath())
        fileUploadService.addTaskRelatedInfo(for: taskInfo)
    }
    
    func reset() {
        Log.info("reset called")
        imageInterval = 0
        dotInterval = 0
        isShowingImages = false
        isFinished = false
        shouldShowConfirmationView = false
        isShowingXMark = true
        dotLocation = nil
        currentTopImage = nil
        currentBottomImage = nil
        timer = nil
        timestampsOfStimuli.removeAll()
    }
}

@available(iOS 14.0, *)
extension AttentionBiasFaceViewModel: TaskViewModelProtocol { }
