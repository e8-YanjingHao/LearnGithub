//
//  NetworkStatusManager.swift
//  MobileFrame
//
//  Created by Encompass on 2021/11/17.
//

import UIKit
import Reachability

public enum ConnectionStatus: CustomStringConvertible {
    case unavailable, wifi, cellular
    public var description: String {
        switch self {
        case .cellular: return "Cellular"
        case .wifi: return "WiFi"
        case .unavailable: return "NoConnection"
        }
    }
}

@objc public class NetworkStatusManager: NSObject {
    @objc public static let shared = NetworkStatusManager()
    @objc public var isNetworkAvilable = true
    let reachability = try! Reachability()
    
    private override init() {
        super.init()
    }
    
    @objc public func getNetworkStatus() -> Bool {
        return self.isNetworkAvilable
    }
    
    @objc public func isNetworkAvailable(callBack : ((Bool)->())?){
        
        reachability.whenReachable = { reachability in
            if reachability.connection == .wifi {
                SLogDebug("Reachable via WiFi")
                self.postNotification(connection: .wifi)
            } else {
                SLogDebug("Reachable via Cellular")
                self.postNotification(connection: .cellular)
            }
            self.isNetworkAvilable = true
            if let callBack = callBack {
                callBack(true)
            }
        }
        reachability.whenUnreachable = { _ in
            SLogDebug("Not reachable")
            self.postNotification(connection: .unavailable)
            self.isNetworkAvilable = false
            if let callBack = callBack {
                callBack(false)
            }
        }

        do {
            try reachability.startNotifier()
        } catch {
            SLogDebug("Unable to start notifier")
        }
        
    }
    
    func postNotification(connection : ConnectionStatus) {
        NotificationCenter.default.post(name: Notification.Name.NetworkStatusChanged, object: connection)
    }
    
    
}
