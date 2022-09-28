//
//  File.swift
//  
//
//  Created by Deepak Kumar on 9/22/22.
//

import Foundation
import Vision
import CoreML
import SwiftUI

struct FacialComplianceStatus {
    var statusMessage: String
    var statusIcon: String
    var statusBackgroundColor: Color
}

class CameraComplianceViewModel: ObservableObject {
    
    enum FaceDetectionResult {
        case detected
        case notDetected
    }
    
    @Published private(set) var faceDetectionResult: FaceDetectionResult
    @Published private(set) var isAcceptableRoll: Bool
    @Published private(set) var isAcceptablePitch: Bool
    @Published private(set) var isAcceptableYaw: Bool
    
    private var sequenceHandler = VNSequenceRequestHandler()
    
    init() {
        faceDetectionResult = .notDetected
        isAcceptableRoll = false
        isAcceptablePitch = false
        isAcceptableYaw = false
    }
    
    func runImageDetection(sampleBuffer: CMSampleBuffer) {
        Log.info("Running detection ---- ")
        let detectFaceLandmarksRequest = VNDetectFaceLandmarksRequest(completionHandler: detectedFaceLandmarks)
        detectFaceLandmarksRequest.revision = VNDetectFaceLandmarksRequestRevision3
        do {
          try sequenceHandler.perform(
            [detectFaceLandmarksRequest],
            on: sampleBuffer,
            orientation: .leftMirrored)
        } catch {
          print("Image Detection fail --  \(error.localizedDescription)")
        }
    }
    
    private func detectedFaceLandmarks(request: VNRequest, error: Error?) {
        
        guard let results = request.results as? [VNFaceObservation], let firstFaceResult = results.first else {
            Log.info("No faces found - error")
            faceDetectionResult = .notDetected
            return
        }
        let leftEye = firstFaceResult.landmarks?.leftEye
        let leftPupil = firstFaceResult.landmarks?.leftPupil
        let rightEye =  firstFaceResult.landmarks?.rightEye
        let rightPupil = firstFaceResult.landmarks?.rightPupil
        
        let foundPupilsAndEyes = (leftEye != nil && leftPupil != nil && rightEye != nil && rightPupil != nil)
        if (foundPupilsAndEyes) {
            faceDetectionResult = .detected
            Log.info("Found a face")
        } else {
            faceDetectionResult = .notDetected
            Log.info("No faces found - no error")
        }
    }
    
}
