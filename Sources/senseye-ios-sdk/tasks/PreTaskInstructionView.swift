//
//  PreTaskInstructionView.swift
//  
//
//  Created by Deepak Kumar on 7/6/22.
//

import SwiftUI

@available(iOS 14.0, *)
struct PreTaskInstructionView: View {
    
    @EnvironmentObject var cameraService: CameraService
    @Binding var isPresented: Bool
    
    private var title: String
    private var description: String
    
    init(isPresented: Binding<Bool>, title: String, description: String) {
        _isPresented = isPresented
        self.title = title
        self.description = description
        
    }
      
    var body: some View {
        VStack(spacing: 50) {
          Text(title)
            .font(.largeTitle)
            
          Text(description)
            .font(.body)
            
          Button(action: {
            isPresented = false
            cameraService.shouldDisplayPretaskTutorial = false
          }, label: {
            Label("Close", systemImage: "xmark.circle")
          })
        }
    }
}
