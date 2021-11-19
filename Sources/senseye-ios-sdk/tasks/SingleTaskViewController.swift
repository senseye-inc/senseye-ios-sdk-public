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
    
    private var calibrationPath = PathType(path: [(75, 710), (200, 500), (75, 200), (300, 710), (75, 710), (150, 200), (200, 500), (250, 200), (250, 710)])
    private var smoothPursuitPath = PathType(path: [(50, 50), (20, 20), (10, 10), (15, 15)])
    private var completedPaths = 0
    private var canProceedToNextAnimation = true
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dotView.backgroundColor = .red
        beginDotMovementForPathType(type: calibrationPath)
    }
    
    func beginDotMovementForPathType(type: PathType) {
        //recursively animate all points
        self.animateForPathCurrentPoint(type: type)
        
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
        }
    }
    
}

#endif
