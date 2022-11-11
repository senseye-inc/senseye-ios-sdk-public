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
    
    var isShowingXMark = true
    var dotLocation: DotLocation?
    var currentTopImage: UIImage?
    var currentBottomImage: UIImage?
    
    let fileUploadService: FileUploadAndPredictionServiceProtocol
    let imageService: ImageService
    
    private var images: [SenseyeImage] = []
    private var currentBlock = 1
    private let fixationDisplayTime = 0.5
    private let facesDisplayTime = 2.0
    private let dotDisplayTime = 0.5
    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer? = nil
    private var timestampsOfStimuli: [Int64] = []
    private var faceSets: [SenseyeFaceSet] = []
    private var imageInterval = 0
    private var dotInterval = 0
    private var dotLocations: [DotLocation] = [.bottom,.top,.top,.bottom,.bottom,.top, .bottom,.top,.top,.bottom,.bottom,.top, .bottom, .bottom]
    private var faceSetAndBlockDictionary: [Int: [SenseyeFaceSet]] {
        [
            1: Array(faceSets[0...6]),
            2: Array(faceSets[7...13])
        ]
    }
    
    init(fileUploadService: FileUploadAndPredictionServiceProtocol, imageService: ImageService) {
        self.fileUploadService = fileUploadService
        self.imageService = imageService
        matchFaceIdsAndDotLocation(for: imageService.senseyeFaceIds)
    }
    
    func checkForImages() {
        guard let currentFaceSet = faceSetAndBlockDictionary[currentBlock] else { return }
        let imageNames = currentFaceSet.flatMap({ [$0.faces.0, $0.faces.1] })
        imageService.updateImagesForBlock(imageSetIds: imageNames)
        addSubscribers()
    }
    
    /**
     Iterates through the provided `senseyeFaceIds` to create a `SenseyeFaceSet` for each pair and dot location.
     - Parameter senseyeFaceIds: The string array of image names used to set the `faces` value for each `SenseyeFaceSet`.
     */
    private func matchFaceIdsAndDotLocation(for senseyeFaceIds: [String]) {
        var imageNames: [(String, String)] = []
        for id in stride(from: 0, to: senseyeFaceIds.count - 1, by: 2) {
            let imageNameTuple = (senseyeFaceIds[id], senseyeFaceIds[id + 1])
            imageNames.append(imageNameTuple)
        }
        let newFaceSet = zip(imageNames, dotLocations).map { imageNames, dotLocation -> SenseyeFaceSet in
            SenseyeFaceSet(faces: imageNames, dotLocation: dotLocation)
        }
        faceSets.append(contentsOf: newFaceSet)
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
        DispatchQueue.main.asyncAfter(deadline: .now() + fixationDisplayTime) {
            self.isShowingXMark = false
            self.showFaces()
        }
    }
    
    private func showFaces() {
        currentTopImage = UIImage(contentsOfFile: images[imageInterval].imageUrl)
        currentBottomImage = UIImage(contentsOfFile: images[imageInterval + 1].imageUrl)
        isShowingImages = true
        DispatchQueue.main.asyncAfter(deadline: .now() + facesDisplayTime) {
            self.showDot()
            self.imageInterval += 2
        }
    }
    
    private func showDot() {
        isShowingImages = false
        dotLocation = faceSets[dotInterval].dotLocation
        DispatchQueue.main.asyncAfter(deadline: .now() + dotDisplayTime) {
            if self.imageInterval < self.images.count {
                self.showFixationPeriod()
                self.dotInterval += 1
            } else {
                self.currentBlock += 1
                self.isFinished = true
                self.shouldShowConfirmationView = true
            }
        }
    }
    
    func addTaskInfoToJson() {
        let taskInfo = SenseyeTask(taskID: "attention_bias_face", frameTimestamps: fileUploadService.getLatestFrameTimestampArray(), timestamps: timestampsOfStimuli)
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
