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
import AVKit
import SwiftUI

@available(iOS 13.0, *)
class TaskViewController: UIViewController {
    
    @IBOutlet weak var cameraPreview: UIView!
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
    private var finishedAllTasks: Bool = false
    private var isPathOngoing: Bool = false
    
   
    private var fileUploadService: FileUploadAndPredictionService = FileUploadAndPredictionService()
    
    var cameraService = CameraService()
    
    var taskIdsToComplete: [String] = []
    var surveyInput: [String: String] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fileUploadService.delegate = self
        dotView.backgroundColor = .red
        dotView.isHidden = true
        xMarkView.isHidden = true
        cameraPreview.isHidden = true
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
        startSessionButton.titleLabel?.text = "Begin"
        startSessionButton.addTarget(self, action: #selector(beginDotMovementForPathType), for: .touchUpInside)
        currentPathTitle.text = "Proceed when you are ready."

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
        self.view.addGestureRecognizer(tapGesture)
        
        cameraService.delegate = self
        cameraService.start()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        cameraService.setupVideoPreviewLayer(for: cameraPreview)
    }
    
    @objc func beginDotMovementForPathType() {
        dotView.isHidden = false
        startSessionButton.titleLabel?.text = "Start"

        startSessionButton.isHidden = true
        currentPathTitle.text = "Starting \(currentTask?.title)..."
        let currentTimeStamp = Date().currentTimeMillis()
        if !isPathOngoing, let path = currentTask,
           let taskNameId = currentTask?.taskId {
            xMarkView.isHidden = path.shouldShowX
            self.isPathOngoing = true
            self.animateForPathCurrentPoint(type: path)
            DispatchQueue.global(qos: .userInitiated).async {
                self.cameraService.startRecordingForTask(taskId: taskNameId)
                self.toggleCameraPreviewVisibility(isHidden: true)
                print("started capture session")
            }
        }
    }
    
    @objc func dismissKeyboard (_ sender: UITapGestureRecognizer) {
    }
    
    private func animateForPathCurrentPoint(type: TaskOption) {
        let currentPathIndex = completedPathsForCurrentTask
        print(type.type.rawValue + " index " + String(currentPathIndex))
        if (type.type == .smoothPursuit) {
            let circularPath = UIBezierPath(arcCenter: xMarkView.center, radius: taskConfig.smoothPursuitCircleRadius, startAngle: .pi*2, endAngle: 0, clockwise: false)
            
            let animationGroup = CAAnimationGroup()
            animationGroup.duration = 5
            animationGroup.repeatCount = taskConfig.smoothPursuitRepeatCount
            animationGroup.delegate = self
            
            let circleAnimation = CAKeyframeAnimation(keyPath: #keyPath(CALayer.position))
            circleAnimation.duration = taskConfig.smoothPursuitDuration
            circleAnimation.speed = taskConfig.smoothPursuitAnimationSpeed
            circleAnimation.path = circularPath.cgPath
            
            animationGroup.animations = [circleAnimation]
            
            dotView.layer.add(animationGroup, forKey: nil)
        } else if (type.type == .plr) {
            var currentInterval = 0
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                if (currentInterval == 20) {
                    timer.invalidate()
                    DispatchQueue.global(qos: .userInitiated).async {
                        self.cameraService.stopRecording()
                    }
                    self.isPathOngoing = false
                    self.currentTasksIndex+=1
                    self.completedPathsForCurrentTask = 0
                    self.currentTask = self.pathTypes[self.currentTasksIndex]
                    self.currentPathTitle.text = self.currentTask?.title
                    self.view.backgroundColor = UIColor.white
                    self.xMarkView.tintColor = UIColor.black
                }
                self.xMarkView.isHidden = false
                self.dotView.isHidden = true
                let colorForCurrentTimeInterval: UIColor? = self.taskConfig.plrBackgroundColorAndTiming[currentInterval]
                if let colorUpdate = colorForCurrentTimeInterval {
                    let xMarkBackgroundColor = self.taskConfig.xMarkColorForBackground(backgroundColor: colorUpdate)
                    DispatchQueue.main.async {
                        self.view.backgroundColor = colorUpdate
                        self.xMarkView.tintColor = xMarkBackgroundColor
                    }
                }
                currentInterval+=1
            }
        } else {
            if (currentPathIndex < type.path.count) {
                let xCoordinate = CGFloat(type.path[currentPathIndex].0)
                let yCoordinate = CGFloat(type.path[currentPathIndex].1)
                UIView.animate(withDuration: 0, delay: 3.0, options: .curveLinear, animations: {
                    let originalFrame = self.dotView.frame
                    let newFrame = CGRect(x: xCoordinate, y: yCoordinate, width: originalFrame.width, height: originalFrame.height)
                    self.dotView.frame = newFrame
                }, completion: { finished in
                    self.completedPathsForCurrentTask+=1
                    self.animateForPathCurrentPoint(type: type)
                })
            } else {
                DispatchQueue.global(qos: .userInitiated).async {
                    self.cameraService.stopRecording()
                }
                isPathOngoing = false
                self.currentTasksIndex+=1
                self.completedPathsForCurrentTask = 0
                currentTask = pathTypes[currentTasksIndex]
                currentPathTitle.text = currentTask?.title
            }
        }
    }
    
    //TODO! Remove once testing is complete, will leave it in for now for convenient local testing
    private func playVideo(videoURL: URL) {
        let player = AVPlayer(url: videoURL)
        let playerController = AVPlayerViewController()
        playerController.player = player
        present(playerController, animated: true) {
            player.play()
        }
    }
    
    private func toggleCameraPreviewVisibility(isHidden: Bool) {
        DispatchQueue.main.async {
            self.cameraPreview.isHidden = isHidden
        }
    }
    
}

@available(iOS 13.0, *)
extension TaskViewController: CAAnimationDelegate {
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        isPathOngoing = false
        startSessionButton.isHidden = false
        currentTasksIndex+=1
        self.completedPathsForCurrentTask = 0
        if (currentTasksIndex != -1 && currentTasksIndex < pathTypes.count) {
            currentTask = pathTypes[currentTasksIndex]
            self.finishedAllTasks = false
        } else {
            if (currentTasksIndex == pathTypes.count) {
                self.finishedAllTasks = true
                DispatchQueue.global(qos: .userInitiated).async { [self] in
                    self.cameraService.stopRecording()
                    toggleCameraPreviewVisibility(isHidden: true)
                }
            } else {
                self.finishedAllTasks = false
            }
            currentTask = nil
            currentTasksIndex = -1
        }
        
        if (finishedAllTasks == true) {
            currentPathTitle.text = "Task Complete! Uploading..."
            toggleCameraPreviewVisibility(isHidden: true)
            self.cameraService.stopCaptureSession()
            fileUploadService.createSessionInputJsonFile(surveyInput: surveyInput, tasks: taskIdsToComplete)
        } else {
            currentPathTitle.text = currentTask?.title
        }
    }
    
}

@available(iOS 13.0, *)
extension TaskViewController: CameraServiceDelegate {
    
    func didFinishFileOutput(fileURL: URL) {
        print("video output finish")
        print(fileURL.absoluteString)
        fileUploadService.uploadData(fileUrl: fileURL)
        self.startSessionButton.isHidden = false
        self.toggleCameraPreviewVisibility(isHidden: false)
    }

    
}

@available(iOS 14.0, *)
extension TaskViewController: FileUploadAndPredictionServiceDelegate {
    
    func didFinishUpload() {
        if (fileUploadService.isUploadOngoing != true && self.finishedAllTasks) {
            DispatchQueue.main.async {
                self.fileUploadService.startPredictionForCurrentSessionUploads { result in
                    print("Result from TaskVC \(#function): \(result)")
                }
                let resultsView = ResultsView(fileUploadService: self.fileUploadService)
                self.present(UIHostingController(rootView: resultsView), animated: true)
                self.currentPathTitle.text = "Starting predictions..."
            }
        }
    }
    
    func didFinishPredictionRequest() {
        fileUploadService.startPeriodicUpdatesOnPredictionId { result in
            DispatchQueue.main.async {
                print("Result From TaskVC \(#function): \(result)")
                self.currentPathTitle.text = "Prediction API request sent..."
            }
        }
    }
    
    func didReturnResultForPrediction(status: String) {
        DispatchQueue.main.async {
            self.currentPathTitle.text = "Returned a result for prediction... \(status)"
        }
    }
}

#endif
