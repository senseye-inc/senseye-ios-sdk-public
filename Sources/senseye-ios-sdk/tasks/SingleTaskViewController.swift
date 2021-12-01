//
//  File.swift
//  
//
//  Created by Deepak Kumar on 11/9/21.
//

import Foundation

#if !os(macOS)

import UIKit

class SingleTaskViewController: UIViewController, CAAnimationDelegate {
    
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
    }
    
    @objc func beginDotMovementForPathType() {
        startSessionButton.isHidden = true
        //recursively animate all points
        if !isPathOngoing, let path = currentTask {
            let shouldHideXMark = (path.type != .smoothPursuit)
            xMarkView.isHidden = shouldHideXMark
            self.isPathOngoing = true
            self.animateForPathCurrentPoint(type: path)
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
            circleAnimation.speed = taskConfig.smoothPuruitAnimationSpeed
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
                isPathOngoing = false
                startSessionButton.isHidden = false
                self.currentTasksIndex+=1
                self.completedPathsForCurrentTask = 0
                currentTask = pathTypes[currentTasksIndex]
                currentPathTitle.text = currentTask?.title
            }
        }
    }
    
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

#endif
