//
//  StringExtensions.swift
//  
//
//  Created by Frank Oftring on 11/2/22.
//

import SwiftUI
extension String {
    var localizedString: String {
        Bundle.main.localizedString(forKey: self, value: "", table: "")
    }
    
    var localizedStringKey: LocalizedStringKey {
        LocalizedStringKey(self)
    }
}
