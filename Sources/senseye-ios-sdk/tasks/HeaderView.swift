//
//  HeaderView.swift
//  SenseyeUILayout
//
//  Created by Frank Oftring on 4/12/22.
//

import SwiftUI

@available(iOS 13.0.0, *)
struct HeaderView: View {
    var body: some View {
        VStack(alignment: .trailing) {
            Image("whiteLogo")
            Text("Fitness for duty".uppercased())
                .foregroundColor(.senseyeSecondary)
                .padding(.leading)
                .font(.subheadline)
        }
        
    }
}

@available(iOS 13.0.0, *)
struct HeaderView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.senseyePrimary
                .edgesIgnoringSafeArea(.all)
            HeaderView()
        }
    }
}
