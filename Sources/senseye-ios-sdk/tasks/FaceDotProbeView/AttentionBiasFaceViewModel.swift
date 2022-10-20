//
//  FaceDotProbeViewModel.swift
//  
//
//  Created by Frank Oftring on 9/22/22.
//

import Foundation

@available(iOS 14.0, *)
class AttentionBiasFaceViewModel: ObservableObject {
    @Published var isShowingImages = false
    @Published var isFinished: Bool = false
    @Published var shouldShowConfirmationView: Bool = false
    @Published var currentInterval = 0
    
    var isShowingXMark = true
    var dotLocation: DotLocation?
    var currentTopImage: String?
    var currentBottomImage: String?
    
    let fileUploadService: FileUploadAndPredictionServiceProtocol
    
    private let fixationDisplayTime = 0.5
    private let facesDisplayTime = 2.0
    private let dotDisplayTime = 0.5
    private var timer: Timer? = nil
    private var timestampsOfStimuli: [Int64] = []
    private var faceFixationSets: [SenseyeFaceItem] = [
        SenseyeFaceItem(pictures: AffectiveFaceType.neutralHappy, dotLocation: .top),
        SenseyeFaceItem(pictures: AffectiveFaceType.sadNeutral, dotLocation: .bottom),
        SenseyeFaceItem(pictures: AffectiveFaceType.anygryNeutral, dotLocation: .bottom),
        SenseyeFaceItem(pictures: AffectiveFaceType.neutralSad, dotLocation: .top),
        SenseyeFaceItem(pictures: AffectiveFaceType.neutralNeutral, dotLocation: .bottom),
        SenseyeFaceItem(pictures: AffectiveFaceType.happyNeutral, dotLocation: .top),
        SenseyeFaceItem(pictures: AffectiveFaceType.neutralAngry, dotLocation: .bottom),
        SenseyeFaceItem(pictures: AffectiveFaceType.sadNeutral, dotLocation: .bottom),
        SenseyeFaceItem(pictures: AffectiveFaceType.happyNeutral, dotLocation: .top),
        SenseyeFaceItem(pictures: AffectiveFaceType.neutralHappy, dotLocation: .top),
        SenseyeFaceItem(pictures: AffectiveFaceType.anygryNeutral, dotLocation: .bottom),
        SenseyeFaceItem(pictures: AffectiveFaceType.neutralSad, dotLocation: .top),
        SenseyeFaceItem(pictures: AffectiveFaceType.neutralAngry, dotLocation: .bottom)
    ]
    
    init(fileUploadService: FileUploadAndPredictionServiceProtocol) {
        self.fileUploadService = fileUploadService
    }
    
    func start() {
        showFixationPeriod()
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
        let currentPictureSet = faceFixationSets[currentInterval].pictures
        currentTopImage = currentPictureSet.0.rawValue
        currentBottomImage = currentPictureSet.1.rawValue
        isShowingImages = true
        DispatchQueue.main.asyncAfter(deadline: .now() + facesDisplayTime) {
            self.showDot()
        }
    }
    
    private func showDot() {
        isShowingImages = false
        dotLocation = faceFixationSets[currentInterval].dotLocation
        DispatchQueue.main.asyncAfter(deadline: .now() + dotDisplayTime) {
            self.currentInterval += 1
            if self.currentInterval < self.faceFixationSets.count {
                self.showFixationPeriod()
            } else {
                self.isFinished = true
                self.shouldShowConfirmationView = true
            }
        }
    }
    
    func addTaskInfoToJson() {
        let taskInfo = SenseyeTask(taskID: "attention_bias_face", frameTimestamps: fileUploadService.getLatestFrameTimestampArray(), timestamps: timestampsOfStimuli, videoPath: fileUploadService.getVideoPath())
        fileUploadService.addTaskRelatedInfo(for: taskInfo)
    }
    
    func reset() {
        Log.info("reset called")
        isShowingImages = false
        isFinished = false
        shouldShowConfirmationView = false
        isShowingXMark = true
        currentInterval = 0
        dotLocation = nil
        currentTopImage = nil
        currentBottomImage = nil
        timer = nil
        timestampsOfStimuli.removeAll()
    }
}

struct SenseyeFaceItem {
    let pictures: (AffectiveFaceType, AffectiveFaceType) // temporarily using strings for emojis, will have to update to an image
    let dotLocation: DotLocation
}

enum DotLocation {
    case top, bottom
}

enum AffectiveFaceType: String {
    case happy = "😃"
    case sad = "☹️"
    case neutral = "😐"
    case angry = "😡"
    
    static let neutralHappy: (AffectiveFaceType, AffectiveFaceType) = (.neutral, .happy)
    static let neutralAngry: (AffectiveFaceType, AffectiveFaceType) = (.neutral, .angry)
    static let neutralSad: (AffectiveFaceType, AffectiveFaceType) = (.neutral, .sad)
    static let neutralNeutral: (AffectiveFaceType, AffectiveFaceType) = (.neutral, .neutral)
    static let anygryNeutral: (AffectiveFaceType, AffectiveFaceType) = (.angry, .neutral)
    static let sadNeutral: (AffectiveFaceType, AffectiveFaceType) = (.sad, .neutral)
    static let happyNeutral: (AffectiveFaceType, AffectiveFaceType) = (.happy, .neutral)
}
@available(iOS 14.0, *)
extension AttentionBiasFaceViewModel: TaskViewModelProtocol { }
