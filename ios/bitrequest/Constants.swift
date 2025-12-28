//
//  Constants.swift
//  bitrequest
//

import UIKit

// Basic App-/WebView-configuration
let appTitle = "Bitrequest"
let allowedOrigin = "github.io"
var webAppUrl = "https://bitrequest.github.io"

let useUserAgentPostfix = true
let userAgentPostfix = "iOSApp"
let useCustomUserAgent = false
let desktopUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 11_0_1 like Mac OS X) AppleWebKit/604.2.10 (KHTML, like Gecko) Version/13.0.3 Safari/605.1.15"

// UI Settings
let enableBounceWhenScrolling = true

// Colors & Styles
let useLightStatusBarStyle = false
let navigationColor = getColorFromHex(hex: 0x4D5359, alpha: 1.0)
let progressBarColor = getColorFromHex(hex: 0xFFFFFF, alpha: 1.0)
let offlineIconColor = getColorFromHex(hex: 0xFFFFFF, alpha: 1.0)
let buttonColor = navigationColor
let activityIndicatorColor = navigationColor

// Color Helper function
func getColorFromHex(hex: UInt, alpha: CGFloat) -> UIColor {
    return UIColor(
        red: CGFloat((hex & 0xFF0000) >> 16) / 255.0,
        green: CGFloat((hex & 0x00FF00) >> 8) / 255.0,
        blue: CGFloat(hex & 0x0000FF) / 255.0,
        alpha: CGFloat(alpha)
    )
}
