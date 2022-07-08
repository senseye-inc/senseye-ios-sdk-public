//
//  PreTaskInstructionView.swift
//  
//
//  Created by Deepak Kumar on 7/6/22.
//

import SwiftUI

@available(iOS 14.0, *)
struct PreTaskInstructionView: View {
    
    @Environment(\.presentationMode) var presentationMode
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
                  .font(.body)
                  .foregroundColor(.white)
                
                Button(action: {
                  presentationMode.wrappedValue.dismiss()
                  isPresented = false
                }, label: {
                  Label("Continue", systemImage: "checkmark.seal")
                })
              }.foregroundColor(.white)
        }
        
    }
}
