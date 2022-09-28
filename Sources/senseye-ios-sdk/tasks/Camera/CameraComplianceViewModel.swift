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
    
    static func faceNotDetected()  -> FacialComplianceStatus {
        return FacialComplianceStatus(statusMessage: "Center your face into the frame!", statusIcon: "xmark.circle", statusBackgroundColor: .red)
    }
    
    static func faceDetected() -> FacialComplianceStatus {
        return FacialComplianceStatus(statusMessage: "Good work, you're positioned correctly!", statusIcon: "checkmark.circle", statusBackgroundColor: .green)
    }
}

class CameraComplianceViewModel: ObservableObject {
    
    @Published private(set) var faceDetectionResult: FacialComplianceStatus = FacialComplianceStatus.faceNotDetected()
    
    private var sequenceHandler = VNSequenceRequestHandler()
    
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
            faceDetectionResult = FacialComplianceStatus.faceNotDetected()
            return
        }
        let leftEye = firstFaceResult.landmarks?.leftEye
        let leftPupil = firstFaceResult.landmarks?.leftPupil
        let rightEye =  firstFaceResult.landmarks?.rightEye
        let rightPupil = firstFaceResult.landmarks?.rightPupil
        
        let foundPupilsAndEyes = (leftEye != nil && leftPupil != nil && rightEye != nil && rightPupil != nil)
        if (foundPupilsAndEyes) {
            faceDetectionResult = FacialComplianceStatus.faceDetected()
            Log.info("Found a face")
        } else {
            faceDetectionResult = FacialComplianceStatus.faceNotDetected()
        }
    }
    
}
