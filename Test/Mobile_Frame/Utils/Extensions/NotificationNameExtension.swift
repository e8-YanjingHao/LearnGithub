//
//  NotificationNameExtension.swift
//  MobileFrame
//
//  Created by Encompass on 2021/11/18.
//

import UIKit

public extension Notification.Name {
    static let NetworkStatusChanged = Notification.Name(rawValue:"Net.NetworkStatusChanged")
    static let TouchWebViewEvent = Notification.Name(rawValue:"TouchWebViewEvent")
}
