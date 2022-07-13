//
//  PreTaskInstructionView.swift
//  
//
//  Created by Deepak Kumar on 7/6/22.
//

import SwiftUI

@available(iOS 15.0, *)
struct PreTaskInstructionView: View {
    
    @EnvironmentObject var cameraService: CameraService
    @Environment(\.dismiss) private var dismiss
    
    private var title: String
    private var description: String
    
    init(title: String, description: String) {
        self.title = title
        self.description = description
        
    }
      
    var body: some View {
        ZStack {
            Color.senseyePrimary.edgesIgnoringSafeArea(.all)
            VStack() {
                Text(title)
                  .font(.largeTitle)
                  .foregroundColor(.white)
                
                Image("person_staring_image")
                  .resizable()
                  .frame(width: 150, height: 150)
                
                Text(description)
                  .padding()
                  .font(.body)
                  .foregroundColor(.white)
                  .multilineTextAlignment(.center)
                
                Button(action: {
                    DispatchQueue.main.async {
                        dismiss()
                    }
                }, label: {
                  Label("Continue", systemImage: "checkmark.seal").padding()
                })
              }
            .foregroundColor(.white)
            .interactiveDismissDisabled()
        }
        
    }
}
