//
//  MobileFrameAppDelegate.swift
//  MobileFrame
//
//  Created by Encompass on 2022/6/13.
//

import UIKit
import Intents
import UserNotifications

public class MobileFrameNotificationHandler: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate{
    
    public static var shared = MobileFrameNotificationHandler()
    
    public func registerNotifications(_ application: UIApplication) {
        
        if #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.current()
            center.delegate = MobileFrameNotificationHandler.shared
            center.getNotificationSettings { (setting) in
                if setting.authorizationStatus == .notDetermined {
                    center.requestAuthorization(options: [.badge,.sound,.alert]) { (result, error) in
                        if(result){
                            center.getNotificationCategories { (value:Set<UNNotificationCategory>) in
                                if(value.count == 0) {
                                    let UNResponseAction : UNTextInputNotificationAction = UNTextInputNotificationAction.init(identifier: "eChatResponseActionIdentifier", title: "Response", options: UNNotificationActionOptions.authenticationRequired, textInputButtonTitle: "Send", textInputPlaceholder: "Please input eChat message")
                                    let UNReadAction : UNNotificationAction = UNNotificationAction.init(identifier: "eChatReadActionIdentifier", title: "Open", options: UNNotificationActionOptions.foreground)
                                    let UNActionCategory : UNNotificationCategory = UNNotificationCategory.init(identifier: "eChat", actions: [UNResponseAction, UNReadAction], intentIdentifiers: [INSendMessageIntentIdentifier], options: UNNotificationCategoryOptions.customDismissAction)
                                    center.setNotificationCategories(Set.init(arrayLiteral: UNActionCategory))
                                }
                            }
                            if (error == nil){
                                // 注册成功
                                DispatchQueue.main.async {
                                    application.registerForRemoteNotifications()
                                }
                            }
                        } else{
                            //用户不允许推送
                            
                        }
                    }
                } else if (setting.authorizationStatus == .denied){
                    // 申请用户权限被拒
                    
                } else if (setting.authorizationStatus == .authorized){
                    // 用户已授权（再次获取dt）
                    DispatchQueue.main.async {
                        application.registerForRemoteNotifications()
                    }
                } else {
                    // 未知错误
                    
                }
            }
        }
    }
    
    public func didRegisterDeviceToken(deviceToken: Data) {
        let deviceTokenStr = deviceToken.map {String(format:"%02.2hhx", arguments: [$0]) }.joined()
        let userDef:UserDefaults = UserDefaults.standard
        userDef.set(deviceTokenStr, forKey: "DeviceToken")
        userDef.synchronize()
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        if notification.request.content.userInfo.keys.count > 0 && notification.request.content.userInfo.keys.contains("info") {
            let apsInfo:NSDictionary = notification.request.content.userInfo["info"] as! NSDictionary;
            let type:String = apsInfo["Type"] as! String
            if(type.elementsEqual("eChat")) {
                if let data = apsInfo["Data"] as? NSDictionary {
                    if(data.allKeys.count > 0) {
                        var groupID : String = ""
                        if let tempGroupID = data["GroupID"] as? String, let groupType = data["GroupType"] as? String {
                            groupID = tempGroupID
                            if(groupType == "4") {
                                if let encompassID = data["TaskSourceEncompassID"] as? String, let taskID = data["TaskID"] as? String {
                                    groupID = encompassID + "_" + taskID
                                }
                            }
                            completionHandler([.badge,.sound,.alert])  //角标，声音，弹窗
                        }
                        
                    }
                }
            }
        }
        
        //更新角标
        if notification.request.content.userInfo.keys.count > 0 && notification.request.content.userInfo.keys.contains("aps") {
            let apsInfo:NSDictionary = notification.request.content.userInfo["aps"] as! NSDictionary;
            if let badgeNumber : NSNumber = apsInfo["badge"] as? NSNumber  {
                let application = UIApplication.shared
                let center = UNUserNotificationCenter.current()
                center.delegate = self
                center.getNotificationSettings { (settings) in
                    if settings.authorizationStatus != .denied && settings.authorizationStatus != .notDetermined {
                        DispatchQueue.main.async {
                            application.applicationIconBadgeNumber = badgeNumber.intValue
                        }
                    }
                }
            }
        }
        
        LoginManager.shared.getUnreadMessageGroups { unreadCount in
                    
        }
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {

        let apsInfo:NSDictionary = response.notification.request.content.userInfo["info"] as! NSDictionary;
        self.handleNotification(apsInfo, didReceive: response, withCompletionHandler: completionHandler)
    }
    
    public func handleNotification(_ apsInfo:NSDictionary, didReceive response: UNNotificationResponse?, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        if MobileFrameEngine.shared.userLoggedOn() == false {
            completionHandler()
            return
        }
        
        let type:String = apsInfo["Type"] as! String
        let data:NSDictionary = apsInfo["Data"] as! NSDictionary
        if(type.elementsEqual("eChat")) {
            WebViewController.enterEchat()
        }
        
        completionHandler()
    }
    
    public func checkEchatVerifySession() {
        if MobileFrameEngine.shared.config.enableEChat {
            LoginManager.shared.verifySession { VerifySuccess, SocketSessionID, SocketServerURL in
              
            }
        }
    }
    
}
