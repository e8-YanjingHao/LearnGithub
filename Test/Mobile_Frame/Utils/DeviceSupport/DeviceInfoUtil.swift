//
//  DeviceInfoUtil.swift
//  MobileFrame
//
//  Created by Encompass on 2021/12/3.
//

import UIKit

///Screen width
public var SCREEN_WIDTH: CGFloat {
    get {
        return UIScreen.main.bounds.size.width
    }
}

/// Screen height
public var SCREEN_HEIGHT: CGFloat {
    get {
        return UIScreen.main.bounds.size.height
    }
}
 
/// Status bar height
public var STATUSBAR_HIGH: CGFloat {
    get {
        return is_iPhoneXSeries() ? 44.0 : 20.0
    }
}
 
/// Navigation bar height
let NAV_HIGH = 44

/// The height of the navigation safe area
public var NAV_HEIGHT_SAFE: CGFloat {
    get {
        return is_iPhoneXSeries() ? 88.0 : 64.0
    }
}
 
/// Tabbar height
public var TABBAR_HEIGHT: CGFloat {
    get {
        return is_iPhoneXSeries() ? 83.0 : 49.0
    }
}
 
/// The height of the tabbar safe area
public var TABBAR_HEIGHT_SAFE: CGFloat {
    get {
        return is_iPhoneXSeries() ? 34.0 : 0.0
    }
}
 
/// AppDelegate
let APPDELEGATE = UIApplication.shared.delegate;
 
/// Window
let KWINDOW = UIApplication.shared.delegate?.window;
 
/// Default
let USER_DEFAULTS = UserDefaults.standard;

/// Fit the screen according to the size
func FIT_SIZE(w: CGFloat) -> (CGFloat) {
    if (!is_iPad()) {
        let new_width = round((w)*UIScreen.main.bounds.size.width/375.0);
        return new_width;
    }
    return w
}

/// Determine if the device is an iphoneX series
func is_iPhoneXSeries() -> (Bool) {
    let boundsSize = UIScreen.main.bounds.size;
    return (boundsSize.width >= 375 && boundsSize.height >= 812) ? true : false;
}
 
/// iPhoneX
func is_iPhoneX() -> (Bool) {
    return CompareIPhoneSize(size: CGSize(width: 1125, height: 2436));
}
 
/// iPhoneXS
func is_iPhoneXS() -> (Bool) {
    return CompareIPhoneSize(size: CGSize(width: 1125, height: 2436));
}
 
/// iPHoneXR
func is_iPhoneXR() -> (Bool) {
    return CompareIPhoneSize(size: CGSize(width: 828, height: 1792));
}
 
/// iPhoneXS Max
func is_iPhoneXSMax() -> (Bool) {
    return CompareIPhoneSize(size: CGSize(width: 1242, height: 2688));
}
 
/// iPhone8 Plus
func is_iPhone8Plus() -> (Bool) {
    return CompareIPhoneSize(size: CGSize(width: 1080, height: 1920));
}
 
/// iPhone8
func is_iPhone8() -> (Bool) {
    return CompareIPhoneSize(size: CGSize(width: 750, height: 1334));
}
 
/// iPhone7 Plus
func is_iPhone7Plus() -> (Bool) {
    return CompareIPhoneSize(size: CGSize(width: 1080, height: 1920));
}
 
/// iPhone7
func is_iPhone7() -> (Bool) {
    return CompareIPhoneSize(size: CGSize(width: 750, height: 1334));
}
 
/// iPhone6S Plus
func is_iPhone6SPlus() -> (Bool) {
    return CompareIPhoneSize(size: CGSize(width: 1080, height: 1920));
}
 
/// iPhone6S
func is_iPhone6S() -> (Bool) {
    return CompareIPhoneSize(size: CGSize(width: 750, height: 1334));
}
 
/// Whether the device is an iPad
func is_iPad() -> (Bool) {
    if (UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad) {
        return true;
    }
    return false;
}
 
func CompareIPhoneSize(size: CGSize) -> (Bool) {
    if (!is_iPad()) {
        guard let currentSize = UIScreen.main.currentMode?.size else {
            return false;
        }
        if (__CGSizeEqualToSize(size, currentSize)) {
            return true;
        }
    }
    return false;
}

extension UIColor {

    /// Color
    ///
    /// - Parameters:
    ///   - red: 红色值(0 -- 255)
    ///   - blue: 蓝色值(0 -- 255)
    ///   - green: 绿色值(0 -- 255)
    ///   - alpha: 透明度(0 -- 1)
    static func rgba(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat = 1.0) -> UIColor {
        return UIColor.init(red: red / 255.0, green: green / 255.0, blue: blue / 255.0, alpha: alpha)
    }
    
    /// Random
    static func randomColor() -> UIColor {
        let red = CGFloat(arc4random_uniform(256))
        let green = CGFloat(arc4random_uniform(256))
        let blue = CGFloat(arc4random_uniform(256))
        return UIColor.rgba(red: red, green: green, blue: blue)
    }
    
    /// Hexadecimal color
    ///
    /// - Parameter hex: 16进制颜色
    /// - Parameter alpha: 透明度
    static func hexColor(hex: String, alpha: CGFloat = 1.0) -> UIColor {
        var red:   CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue:  CGFloat = 0.0
        var alpha: CGFloat = alpha
        var hex = hex
        
        if hex.hasPrefix("#") {
            let index = hex.index(hex.startIndex, offsetBy: 1)
            hex = String(hex[index...])
            
        }
        
        let scanner = Scanner(string: hex)
        var hexValue: CUnsignedLongLong = 0
        if scanner.scanHexInt64(&hexValue) {
            switch (hex.count) {
            case 3:
                red   = CGFloat((hexValue & 0xF00) >> 8)       / 15.0
                green = CGFloat((hexValue & 0x0F0) >> 4)       / 15.0
                blue  = CGFloat(hexValue & 0x00F)              / 15.0
            case 4:
                red   = CGFloat((hexValue & 0xF000) >> 12)     / 15.0
                green = CGFloat((hexValue & 0x0F00) >> 8)      / 15.0
                blue  = CGFloat((hexValue & 0x00F0) >> 4)      / 15.0
                alpha = CGFloat(hexValue & 0x000F)             / 15.0
            case 6:
                red   = CGFloat((hexValue & 0xFF0000) >> 16)   / 255.0
                green = CGFloat((hexValue & 0x00FF00) >> 8)    / 255.0
                blue  = CGFloat(hexValue & 0x0000FF)           / 255.0
            case 8:
                red   = CGFloat((hexValue & 0xFF000000) >> 24) / 255.0
                green = CGFloat((hexValue & 0x00FF0000) >> 16) / 255.0
                blue  = CGFloat((hexValue & 0x0000FF00) >> 8)  / 255.0
                alpha = CGFloat(hexValue & 0x000000FF)         / 255.0
            default:
                print("Invalid RGB string, number of characters after '#' should be either 3, 4, 6 or 8", terminator: "")
            }
        } else {
            print("Scan hex error")
        }
       return UIColor.init(red:red, green:green, blue:blue, alpha:alpha)
    }
}

///App version
public var app_version: String {
    get {
        let infoDictionary = Bundle.main.infoDictionary ?? [:]
        let version = (infoDictionary["CFBundleShortVersionString"] as? String) ?? ""
        return version
    }
}
///Device Name
public var device_name: String {
    get {
        return UIDevice.current.name
    }
}
///Device Model ( iPhone / ipad )
public var device_model: String {
    get {
        return UIDevice.current.model
    }
}
///Device system name
public var device_system_name: String {
    get {
        return UIDevice.current.systemName
    }
}
///Device system version
public var device_system_version: String {
    get {
        return UIDevice.current.systemVersion
    }
}

public var device_serial_number: String {
    get {
        if let num = UIDevice.current.identifierForVendor?.uuidString {
            return num
        }
        return ""
    }
}

public var device_user_agent: String? {
    get {
        return MobileFrameEngine.shared.config.userAgent
    }
}

///Device model name
public var device_model_name: String {
    get {
        var systemInfo = utsname()
        uname(&systemInfo)
        
        let platform = withUnsafePointer(to: &systemInfo.machine.0) { ptr in
            return String(cString: ptr)
        }
        switch platform {
        //MARK: iPod
        case "iPod1,1":
            return "iPod Touch 1"
        case "iPod2,1":
            return "iPod Touch 2"
        case "iPod3,1":
            return "iPod Touch 3"
        case "iPod4,1":
            return "iPod Touch 4"
        case "iPod5,1":
            return "iPod Touch (5 Gen)"
        case "iPod7,1":
            return "iPod Touch 6"
        //MARK: iPhone
        case "iPhone5,1":
            return "iPhone 5"
        case "iPhone5,2":
            return "iPhone 5 (GSM+CDMA)"
        case "iPhone5,3":
            return "iPhone 5c (GSM)"
        case "iPhone5,4":
            return "iPhone 5c (GSM+CDMA)"
        case "iPhone6,1":
            return "iPhone 5s (GSM)"
        case "iPhone6,2":
            return "iPhone 5s (GSM+CDMA)"
        case "iPhone7,2":
            return "iPhone 6"
        case "iPhone7,1":
            return "iPhone 6 Plus"
        case "iPhone8,1":
            return "iPhone 6s"
        case "iPhone8,2":
            return "iPhone 6s Plus"
        case "iPhone8,4":
            return "iPhone SE"
        case "iPhone9,1" , "iPhone9,3":
            return "iPhone 7"
        case "iPhone9,2" , "iPhone9,4":
            return "iPhone 7 Plus"
        case "iPhone10,1","iPhone10,4":
            return "iPhone 8"
        case "iPhone10,2","iPhone10,5":
            return "iPhone 8 Plus"
        case "iPhone10,3","iPhone10,6":
            return "iPhone X"
        case "iPhone11,8":
            return "iPhone XR"
        case "iPhone11,2":
            return "iPhone XS"
        case "iPhone11,6":
            return "iPhone XS Max"
        case "iPhone11,4":
            return "iPhone XS Max (China)"
        case "iPhone12,1":
            return "iPhone 11"
        case "iPhone12,3":
            return "iPhone 11 Pro"
        case "iPhone12,5":
            return "iPhone 11 Pro Max"
        case "iPhone13,1":
            return "iPhone 12 mini"
        case "iPhone13,2":
            return "iPhone 12"
        case "iPhone13,3":
            return "iPhone 12 Pro"
        case "iPhone13,4":
            return "iPhone 12 Pro Max"
        case "iPhone14,4":
            return "iPhone 13 mini"
        case "iPhone14,5":
            return "iPhone 13"
        case "iPhone14,2":
            return "iPhone 13 Pro"
        case "iPhone14,3":
            return "iPhone 13 Pro Max"
        //MARK: iPad
        case "iPad1,1":
            return "iPad"
        case "iPad1,2":
            return "iPad 3G"
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":
            return "iPad 2"
        case "iPad2,5", "iPad2,6", "iPad2,7":
            return "iPad Mini"
        case "iPad3,1", "iPad3,2", "iPad3,3":
            return "iPad 3"
        case "iPad3,4", "iPad3,5", "iPad3,6":
            return "iPad 4"
        case "iPad4,1", "iPad4,2", "iPad4,3":
            return "iPad Air"
        case "iPad4,4", "iPad4,5", "iPad4,6":
            return "iPad Mini 2"
        case "iPad4,7", "iPad4,8", "iPad4,9":
            return "iPad Mini 3"
        case "iPad5,1", "iPad5,2":
            return "iPad Mini 4"
        case "iPad5,3", "iPad5,4":
            return "iPad Air 2"
        case "iPad6,3", "iPad6,4":
            return "iPad Pro 9.7"
        case "iPad6,7", "iPad6,8":
            return "iPad Pro 12.9"
        default:
            return platform
        }
    }
}

public var device_font_scale: Double {
    get {
        let divisor = pow(10.0, Double(2))
        return round((UIFontDescriptor.preferredFontDescriptor(withTextStyle: .footnote).pointSize / UIFont.systemFontSize) * divisor) / divisor
    }
}

public var deviceInfo: [String : Any] {
    get {
        var deviceInfo : [String : Any] = [:]
        deviceInfo["DeviceName"] = device_name
        deviceInfo["DeviceModel"] = device_model
        deviceInfo["DeviceModelName"] = device_model_name
        deviceInfo["SystemVersion"] = device_system_version
        deviceInfo["SystemName"] = device_system_name
        deviceInfo["AppVersion"] = app_version
        deviceInfo["DeviceSerialNum"] = device_serial_number
        deviceInfo["UserAgent"] = device_user_agent
        deviceInfo["ScreenWidth"] = SCREEN_WIDTH
        deviceInfo["ScreenHeight"] = SCREEN_HEIGHT
        deviceInfo["StatusBarHeight"] = STATUSBAR_HIGH
        deviceInfo["NavHeight"] = NAV_HIGH
        deviceInfo["NavSafeHeight"] = NAV_HEIGHT_SAFE
        
        deviceInfo["EncompassID"] = MobileFrameEngine.shared.config.encompassID
        deviceInfo["ServerHost"] = MobileFrameEngine.shared.config.serverHost
        deviceInfo["MobileFrameAppID"] = MobileFrameEngine.shared.config.mobileFrameAppID
        deviceInfo["FontScale"] = device_font_scale
        return deviceInfo
    }
    
    
}
