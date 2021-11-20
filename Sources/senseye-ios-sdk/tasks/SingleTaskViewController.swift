//
//  File.swift
//  
//
//  Created by Deepak Kumar on 11/9/21.
//

import Foundation

#if !os(macOS)

import UIKit

class SingleTaskViewController: UIViewController {
    
    struct PathType {
        let path: [(Int,Int)]
        
        init(path: [(Int,Int)]) {
            self.path = path
        }
    }
    
    @IBOutlet weak var dotView: UIView!
    @IBOutlet weak var startSessionButton: UIButton!
    
    private var calibrationPath = PathType(path: [(300, 75), (75,600), (200, 500), (75, 200), (300, 600), (75, 600), (150, 200), (200, 500), (250, 200), (250, 600)])
    private var smoothPursuitPath = PathType(path: [(50, 50), (20, 20), (10, 10), (15, 15)])
    private var completedPaths = 0
    private var canProceedToNextAnimation = true
    var pathType: PathType?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dotView.backgroundColor = .red
        if let dotStartingPoint = calibrationPath.path.first {
            let originalFrame = self.dotView.frame
            let initialPositionFrame = CGRect(x: CGFloat(dotStartingPoint.0), y: CGFloat(dotStartingPoint.1), width: originalFrame.width, height: originalFrame.height)
            dotView.frame = initialPositionFrame
            completedPaths+=1
        }
        pathType = calibrationPath
        startSessionButton.addTarget(self, action: #selector(beginDotMovementForPathType), for: .touchUpInside)
    }
    
    @objc func beginDotMovementForPathType() {
        startSessionButton.isHidden = true
        //recursively animate all points
        if let path = pathType {
            self.animateForPathCurrentPoint(type: path)
        }
    }
    
    private func animateForPathCurrentPoint(type: PathType) {
        let currentPathIndex = completedPaths
        print(currentPathIndex)
        if (currentPathIndex < type.path.count) {
            let xCoordinate = CGFloat(type.path[currentPathIndex].0)
            let yCoordinate = CGFloat(type.path[currentPathIndex].1)
            UIView.animate(withDuration: 2, delay: 3.0, options: .curveLinear, animations: {
                let originalFrame = self.dotView.frame
                let newFrame = CGRect(x: xCoordinate, y: yCoordinate, width: originalFrame.width, height: originalFrame.height)
                self.dotView.frame = newFrame
            }, completion: { finished in
                self.completedPaths+=1
                self.animateForPathCurrentPoint(type: type)
            })
        } else {
            startSessionButton.isHidden = true
        }
    }
    
}

#endif
