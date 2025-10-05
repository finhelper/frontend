//
//  FinHelperApp.swift
//  FinHelper
//
//  Created by Sühan Düşünceli on 13.04.2025.
//

import SwiftUI

@main
struct FinHelperApp: App {
    var body: some Scene {
        WindowGroup {
            SplashView()
        }
    }
}

// MARK: - Global Imports
import Foundation
import SwiftUI
#if os(iOS)
import UIKit
#endif

// MARK: - Global Extensions
extension View {
    func hideKeyboard() {
        #if os(iOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }
}

// MARK: - Global Constants
enum GlobalConstants {
    static let appName = "FinHelper"
    static let appVersion = "1.0.0"
    
    enum Colors {
        static let primary = Color.blue
        static let secondary = Color.gray
        static let background = Color(.systemBackground)
        static let groupBackground = Color(.systemGroupedBackground)
    }
    
    enum Images {
        static let appIcon = "wallet.pass"
        static let defaultAvatar = "person.circle.fill"
    }
}
