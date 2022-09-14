//
//  FileManagerExtensions.swift
//  
//
//  Created by Frank Oftring on 8/10/22.
//

import Foundation
import UIKit
extension FileManager {
    
    /**
     Saves a UIImage to the FileManager's document directory by first checking if a folder with the current imageName and folderName paremter already exists. If not, a new folder is created.
     
     - Parameter image: The UIImage to be saved as PNG data
     - Parameter imageName: The image name to be used as an appending path component within the folder name
     - Parameter folderName: The name of the folder where the image will be saved within the documents directory
     */
    func saveImage(image: UIImage, imageName: String, folderName: String) {
        createFolderIfNeeded(folderName: folderName)
        
        guard let data = image.pngData(),
              let url = getURLForImage(imageName: imageName, folderName: folderName)
        else { return }
        
        do {
            try data.write(to: url)
        } catch let error {
            Log.error("Error saving image: \(error). Imagename: \(imageName)")
        }
    }
    
    /**
     Returns an optional array of SenseyeImages
     - Parameter imageNames: A array of strings used to retrieve images by name
     - Parameter folderName: The folder name as a string where the images are stored
     */
    func getImages(imageNames: [String], folderName: String) -> [SenseyeImage] {
        var senseyeImages: [SenseyeImage] = []
        for imageName in imageNames {
            if let url = getURLForImage(imageName: imageName, folderName: folderName),
               FileManager.default.fileExists(atPath: url.path),
               let savedImage = UIImage(contentsOfFile: url.path) {
                let newSenseyeImage = SenseyeImage(image: savedImage, imageName: imageName)
                senseyeImages.append(newSenseyeImage)
            }
        }
        return senseyeImages
    }
    
    private func createFolderIfNeeded(folderName: String) {
        guard let url = getURLForFolder(folderName: folderName) else { return }
        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            } catch let error {
                Log.error("Error creating directory: \(error). Foldername: \(folderName)")
            }
        }
    }
    
    private func getURLForFolder(folderName: String) -> URL? {
        guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        return url.appendingPathComponent(folderName)
    }
    
    private func getURLForImage(imageName: String, folderName: String) -> URL? {
        guard let folderURL = getURLForFolder(folderName: folderName) else { return nil }
        return folderURL.appendingPathComponent(imageName + ".png")
    }
    
}
