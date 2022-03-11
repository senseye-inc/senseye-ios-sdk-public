//
//  File.swift
//  
//
//  Created by Deepak Kumar on 3/2/22.
//

import Foundation
import UIKit

class SurveyViewController: UIViewController {
    
    @IBOutlet weak var ageLabel: UILabel!
    @IBOutlet weak var ageInput: UITextField!
    private var agePickerView: UIPickerView?
    @IBOutlet weak var genderLabel: UILabel!
    @IBOutlet weak var genderInput: UITextField!
    private var genderPickerView: UIPickerView?
    @IBOutlet weak var eyeColorLabel: UILabel!
    @IBOutlet weak var eyeColorInput: UITextField!
    private var eyeColorPickerView: UIPickerView?
    @IBOutlet weak var continueButton: UIButton!
    
    private var ageInputs = ["20","21","22"]
    private var genderInputs = ["Male", "Female", "Other"]
    private var eyeColorInputs = ["Blue", "Green", "Brown", "Black"]
    
    var taskIdsToComplete: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ageInput.text = "N/A"
        genderInput.text = "N/A"
        eyeColorInput.text = "N/A"
        
        self.agePickerView = UIPickerView(frame: CGRect(x: 5, y: 20, width: 250, height: 150))
        self.agePickerView?.delegate = self
        self.agePickerView?.dataSource = self
        let ageInputGesture = UITapGestureRecognizer(target: self, action: #selector(self.displayAgeInputDropdown(_:)))
        self.ageInput.addGestureRecognizer(ageInputGesture)
        
        
        self.genderPickerView = UIPickerView(frame: CGRect(x: 5, y: 20, width: 250, height: 150))
        self.genderPickerView?.delegate = self
        self.genderPickerView?.dataSource = self
        let genderInputGesture = UITapGestureRecognizer(target: self, action: #selector(self.displayGenderInputDropdown(_:)))
        self.genderInput.addGestureRecognizer(genderInputGesture)
        
        self.eyeColorPickerView = UIPickerView(frame: CGRect(x: 5, y: 20, width: 250, height: 150))
        self.eyeColorPickerView?.delegate = self
        self.eyeColorPickerView?.dataSource = self
        let eyeColorGesture = UITapGestureRecognizer(target: self, action: #selector(self.displayEyeColorInputDropdown(_sender:)))
        self.eyeColorInput.addGestureRecognizer(eyeColorGesture)
        
        ageInput.inputView = agePickerView
        genderInput.inputView = genderPickerView
        eyeColorInput.inputView = eyeColorPickerView
        
        let continueButtonGesture = UITapGestureRecognizer(target: self, action: #selector(self.continueToTaskViewController(_:)))
        continueButton.addGestureRecognizer(continueButtonGesture)
        
    }
    
    
    @objc func displayGenderInputDropdown (_ sender: UITapGestureRecognizer) {
        let genderAlertController = UIAlertController(title: "Gender", message: "Please enter your gender", preferredStyle: .alert)
        genderAlertController.view.addSubview(genderPickerView!)
        genderAlertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        genderAlertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            
        }))
        let alertHeightConstraint = NSLayoutConstraint(item: genderAlertController.view, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 200)
        genderAlertController.view.addConstraint(alertHeightConstraint)
        present(genderAlertController, animated: true, completion: nil)
    }
    
    @objc func displayAgeInputDropdown  (_ sender: UITapGestureRecognizer) {
        let ageAlertController = UIAlertController(title: "Age", message: "Please enter your age", preferredStyle: .alert)
        ageAlertController.view.addSubview(agePickerView!)
        ageAlertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        ageAlertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            
        }))
        let alertHeightConstraint = NSLayoutConstraint(item: ageAlertController.view, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 200)
        ageAlertController.view.addConstraint(alertHeightConstraint)
        present(ageAlertController, animated: true, completion: nil)
    }
    
    @objc func displayEyeColorInputDropdown (_sender: UITapGestureRecognizer) {
        let eyeColorController = UIAlertController(title: "Eye Color", message: "Please enter your eye color", preferredStyle: .alert)
        eyeColorController.view.addSubview(eyeColorPickerView!)
        eyeColorController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        eyeColorController.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
        
        }))
        let alertHeightConstraint = NSLayoutConstraint(item: eyeColorController.view, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 200)
        eyeColorController.view.addConstraint(alertHeightConstraint)
        present(eyeColorController, animated: true, completion: nil)
    }
    
    @objc func continueToTaskViewController(_ sender: UITapGestureRecognizer) {
        let singleTaskViewController = TaskViewController(nibName: "SingleTaskViewController", bundle: nil)
        singleTaskViewController.taskIdsToComplete = taskIdsToComplete
        var currentSurveyInput : [String: String] = [:]
        currentSurveyInput["age"] = ageInput.text
        currentSurveyInput["gender"] = genderInput.text
        currentSurveyInput["eyeColor"] = eyeColorInput.text
        singleTaskViewController.surveyInput = currentSurveyInput
        weak var currentViewController = self
        self.dismiss(animated: true) {
            currentViewController?.present(singleTaskViewController, animated: true, completion: nil)
        }
    }
    
}

extension SurveyViewController: UIPickerViewDelegate, UIPickerViewDataSource {

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
       return 1
    }
        
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        var numOfRows = 0
        switch pickerView {
            case agePickerView:
                numOfRows = 3
            case genderPickerView:
                numOfRows = 3
            case eyeColorPickerView:
                numOfRows =  4
        default:
            numOfRows = 0
        }
       return numOfRows
    }
        
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        var valueToDisplay = ""
        switch pickerView {
            case agePickerView:
                valueToDisplay = ageInputs[row]
            case genderPickerView:
                valueToDisplay = genderInputs[row]
            case eyeColorPickerView:
                valueToDisplay = eyeColorInputs[row]
        default:
            valueToDisplay = ""
        }
       return valueToDisplay
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView {
            case agePickerView:
                ageInput.text = ageInputs[row]
            case genderPickerView:
                genderInput.text = genderInputs[row]
            case eyeColorPickerView:
                eyeColorInput.text = eyeColorInputs[row]
        default:
            return
        }
    }
    
}
