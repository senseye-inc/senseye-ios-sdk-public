//
//  HeaderView.swift
//
//  Created by Frank Oftring on 4/12/22.
//

import SwiftUI

struct HeaderView: View {
    var body: some View {
        VStack(alignment: .trailing) {
            Image("whiteLogo", bundle: .module)
                .foregroundColor(.senseyeSecondary)
                .padding(.leading)
                .font(.subheadline)
        }
    }
}
