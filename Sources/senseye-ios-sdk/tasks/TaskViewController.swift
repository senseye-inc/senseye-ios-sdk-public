//
//  File.swift
//  
//
//  Created by Deepak Kumar on 11/9/21.
//

import Foundation

#if !os(macOS)

import UIKit
import AVFoundation

@available(iOS 10.0, *)
class TaskViewController: UIViewController  {
    
    @IBOutlet weak var dotView: UIView!
    @IBOutlet weak var startSessionButton: UIButton!
    @IBOutlet weak var xMarkView: UIImageView!
    @IBOutlet weak var dotViewInitialXConstraint: NSLayoutConstraint!
    @IBOutlet weak var dotViewInitialYConstraint: NSLayoutConstraint!
    @IBOutlet weak var currentPathTitle: UILabel!
    
    private var taskConfig = TaskConfig()
    private var completedPathsForCurrentTask = 0
    private var canProceedToNextAnimation = true
    private var pathTypes: [TaskOption] = []
    private var currentTask: TaskOption?
    private var currentTasksIndex = 0
    private var isPathOngoing: Bool = false
    
    private var captureSession = AVCaptureSession()
    private var captureOutput = AVCaptureVideoDataOutput()
    private var captureMovieFileOutput = AVCaptureMovieFileOutput()
    private var frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
    
    private let fileDestUrl: URL? = FileManager.default.urls(for: .documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first
    private let fileUploadService: FileUploadService = FileUploadService()
    
    var taskIdsToComplete: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dotView.backgroundColor = .red
        pathTypes = taskConfig.pathOptionsForTaskIds(ids: taskIdsToComplete)
        currentTask = pathTypes[currentTasksIndex]
        currentPathTitle.text = currentTask?.title
        if let dotStartingPoint = currentTask?.path.first {
            let xCoordinate = CGFloat(dotStartingPoint.0)
            let yCoordinate = CGFloat(dotStartingPoint.1)
            dotViewInitialXConstraint.constant = xCoordinate
            dotViewInitialYConstraint.constant = yCoordinate
            completedPathsForCurrentTask+=1
        }
        startSessionButton.addTarget(self, action: #selector(beginDotMovementForPathType), for: .touchUpInside)
        
        DispatchQueue.global(qos: .userInitiated).async {
            guard let videoDeviceInput = try? AVCaptureDeviceInput(device: self.frontCameraDevice!) else {
                print("videoDeviceInput error")
                return
            }
            self.captureSession.addInput(videoDeviceInput)
            self.captureSession.sessionPreset = AVCaptureSession.Preset.high
            self.captureSession.addOutput(self.captureOutput)
            self.captureSession.addOutput(self.captureMovieFileOutput)
            let videoQueue = DispatchQueue(label: "videoQueue", qos: .userInteractive)
            self.captureOutput.setSampleBufferDelegate(self, queue: videoQueue)
            self.captureSession.beginConfiguration()
            self.captureSession.commitConfiguration()
        }
    }
    
    @objc func beginDotMovementForPathType() {
        startSessionButton.isHidden = true
        //recursively animate all points
        //.appendingPathComponent("senseye_demo_video")
        if !isPathOngoing, let path = currentTask,
            let taskTitle = currentTask?.title,
            let fileUrl = fileDestUrl?.appendingPathComponent("task_ios_\(taskTitle)") {
            let shouldHideXMark = (path.type != .smoothPursuit)
            xMarkView.isHidden = shouldHideXMark
            self.isPathOngoing = true
            self.animateForPathCurrentPoint(type: path)
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
                self.captureMovieFileOutput.startRecording(to: fileUrl, recordingDelegate: self)
                print("started capture session")
            }
        }
    }
    
    private func animateForPathCurrentPoint(type: TaskOption) {
        let currentPathIndex = completedPathsForCurrentTask
        print(currentPathIndex)
        if (type.type == .smoothPursuit) {
            let circularPath = UIBezierPath(arcCenter: xMarkView.center, radius: taskConfig.smoothPursuitCircleRadius, startAngle: .pi*2, endAngle: 0, clockwise: false)
            
            let animationGroup = CAAnimationGroup()
            animationGroup.duration = 5
            animationGroup.repeatCount = 3
            animationGroup.delegate = self
            
            let circleAnimation = CAKeyframeAnimation(keyPath: #keyPath(CALayer.position))
            circleAnimation.duration = taskConfig.smoothPursuitDuration
            circleAnimation.repeatCount = taskConfig.smoothPursuitRepeatCount
            circleAnimation.speed = taskConfig.smoothPursuitAnimationSpeed
            circleAnimation.path = circularPath.cgPath
            
            animationGroup.animations = [circleAnimation]
            
            dotView.layer.add(animationGroup, forKey: nil)
        } else {
            if (currentPathIndex < type.path.count) {
                let xCoordinate = CGFloat(type.path[currentPathIndex].0)
                let yCoordinate = CGFloat(type.path[currentPathIndex].1)
                UIView.animate(withDuration: 2, delay: 3.0, options: .curveLinear, animations: {
                    let originalFrame = self.dotView.frame
                    let newFrame = CGRect(x: xCoordinate, y: yCoordinate, width: originalFrame.width, height: originalFrame.height)
                    self.dotView.frame = newFrame
                }, completion: { finished in
                    self.completedPathsForCurrentTask+=1
                    self.animateForPathCurrentPoint(type: type)
                })
            } else {
                DispatchQueue.global(qos: .userInitiated).async { [self] in
                    self.captureSession.stopRunning()
                    self.captureMovieFileOutput.stopRecording()
                }
                isPathOngoing = false
                startSessionButton.isHidden = false
                self.currentTasksIndex+=1
                self.completedPathsForCurrentTask = 0
                currentTask = pathTypes[currentTasksIndex]
                currentPathTitle.text = currentTask?.title
            }
        }
    }
    
    
    
}

@available(iOS 10.0, *)
extension TaskViewController: CAAnimationDelegate {
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        isPathOngoing = false
        startSessionButton.isHidden = false
        currentTasksIndex+=1
        self.completedPathsForCurrentTask = 0
        if (currentTasksIndex != -1 && currentTasksIndex < pathTypes.count) {
            currentTask = pathTypes[currentTasksIndex]
        } else {
            currentTask = nil
            currentTasksIndex = -1
        }
        currentPathTitle.text = currentTask?.title
    }
    
}

@available(iOS 10.0, *)
extension TaskViewController: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureFileOutputRecordingDelegate {
    
    //Frame-by-Frame output
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        print("video frame")
    }
    
    //Full recording output
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print("video output start")
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print("video output finish")
        print(error.debugDescription)
        fileUploadService.uploadData(fileUrl: outputFileURL)
    }
    
}

#endif
