//
//  WebViewUserContentController.swift
//  ScanCode
//
//  Created by Encompass on 2021/11/11.
//

import UIKit
import WebKit
import SwiftyJSON
import UniformTypeIdentifiers

open class WebViewUserContentController: NSObject, WKScriptMessageHandler {
    
    var jsNative : JSNative?
    
    init(jsNative : JSNative) {
        self.jsNative = jsNative
    }

    //MARK - WKScriptMessageHandler
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name != MessageName.Login.rawValue {
            SLogDebug("JSBridge method: \(message.name), data: \(message.body)")
        }
        
        switch message.name {
        case MessageName.Open.rawValue:
            if let body = message.body as? [String : Any] {
                if let url = body["Url"] as? String {
                    self.jsNative!.open(urlStr: url)
                }
            }
            break
        case MessageName.NavigateTo.rawValue:
            if let body = message.body as? [String : Any] {
                let bodyData = JSON(body)
                let dashboardId : Int = bodyData["DashboardID"].intValue
                let queryString : String = body.map{ kv -> String in
                    return "\(kv.key.urlEncoded())=\(kv.value)"
                }.joined(separator: "&")
                self.jsNative!.navigateTo(dashboardId: dashboardId, queryString: queryString)
            }
            break
        case MessageName.RedirectTo.rawValue:
            if let body = message.body as? [String : Any] {
                let bodyData = JSON(body)
                let dashboardId : Int = bodyData["DashboardID"].intValue
                let queryString : String = body.map { kv -> String in
                    return "\(kv.key.urlEncoded())=\(kv.value)"
                }.joined(separator: "&")
                self.jsNative!.redirectTo(dashboardId: dashboardId, queryString: queryString)
            }
            break
        case MessageName.SwitchTo.rawValue:
            if let body = message.body as? [String : Any] {
                let bodyData = JSON(body)
                let dashboardId : Int = bodyData["DashboardID"].intValue
                let queryString : String = body.map{ kv -> String in
                    return "\(kv.key.urlEncoded())=\(kv.value)"
                }.joined(separator: "&")
                self.jsNative!.switchTo(dashboardId: dashboardId, queryString: queryString)
            }
            break
        case MessageName.NavigateBack.rawValue:
            if let body = message.body as? [String : Any] {
                self.jsNative?.navigateBack(params: body)
            }
            break
        case MessageName.ScanQRCode.rawValue:
            if let body = message.body as? [String : Any] {
                let bodyJson = JSON(body)
                self.jsNative!.scanQRCode(eventId: bodyJson["EventId"].stringValue)
            }
            break
        case MessageName.GetAppInfo.rawValue:
            if let body = message.body as? [String : Any] {
                let bodyJson = JSON(body)
                self.jsNative!.getAppInfo(eventId: bodyJson["EventId"].stringValue)
            }
            break
        case MessageName.StorageSetItem.rawValue:
            if let body = message.body as? [String : Any] {
                let messageJson = JSON(body)
                self.jsNative!.storageSetItem(key: messageJson["Key"].stringValue, content: messageJson["Content"].stringValue, eventId: messageJson["EventId"].stringValue)
            }
            break
        case MessageName.StorageGetItem.rawValue:
            if let body = message.body as? [String : Any] {
                let bodyJson = JSON(body)
                self.jsNative!.storageGetItem(key: bodyJson["Key"].stringValue, eventId: bodyJson["EventId"].stringValue)
            }
            break
        case MessageName.StorageRemoveItem.rawValue:
            if let body = message.body as? [String : Any] {
                let bodyJson = JSON(body)
                self.jsNative!.storageRemoveItem(key: bodyJson["Key"].stringValue, eventId: bodyJson["EventId"].stringValue)
            }
            break
        case MessageName.StorageKeys.rawValue:
            if let body = message.body as? [String : Any] {
                let bodyJson = JSON(body)
                self.jsNative!.storageGetKeys(_prefix: bodyJson["Prefix"].stringValue, eventId: bodyJson["EventId"].stringValue)
            }
            break
        case MessageName.Login.rawValue:
            if let body = message.body as? [String : Any] {
                let bodyJson = JSON(body)
                self.jsNative!.login(userName: bodyJson["Username"].stringValue, passWord: bodyJson["Password"].stringValue, eventId: bodyJson["EventId"].stringValue)
            }
            break
        case MessageName.Logout.rawValue:
            self.jsNative?.logout()
            break
        case MessageName.Log.rawValue:
            if let body = message.body as? [String : Any] {
                let bodyJson = JSON(body)
                self.jsNative!.log(content: bodyJson["Content"].stringValue)
            }
            break
        case MessageName.GetLocation.rawValue:
            if let body = message.body as? [String : Any] {
                let bodyJson = JSON(body)
                self.jsNative!.getLocation(eventId: bodyJson["EventId"].stringValue)
            }
            break
        case MessageName.UploadLogs.rawValue:
            if let body = message.body as? [String : Any] {
                let bodyJson = JSON(body)
                self.jsNative!.uploadLogs(eventId: bodyJson["EventId"].stringValue, memo: bodyJson["Memo"].stringValue)
            }
            break
        case MessageName.ExecuteSQL.rawValue:
            if let body = message.body as? [String : Any] {
                let bodyJson = JSON(body)
                self.jsNative!.prepareSql(sql: bodyJson["Sql"].stringValue, eventId: bodyJson["EventId"].stringValue)
            }
            break
        case MessageName.SetAppConfig.rawValue:
            if let body = message.body as? [String : Any] {
                let bodyJson = JSON(body)
                self.jsNative!.setAppConfig(config: bodyJson, eventId: bodyJson["EventId"].stringValue)
            }
            break
        case MessageName.GetAppConfig.rawValue:
            if let body = message.body as? [String : Any] {
                let bodyJson = JSON(body)
                self.jsNative!.getAppConfig(eventId: bodyJson["EventId"].stringValue)
            }
            break
        case MessageName.OpenAppSettings.rawValue:
            self.jsNative!.openAppSettings()
            break
        case MessageName.SubmitAPIRequest.rawValue:
            if let body = message.body as? [String : Any] {
                let bodyJson = JSON(body)
                self.jsNative!.submitAPIRequest(request: bodyJson, eventId: bodyJson["EventId"].stringValue)
            }
            break
        case MessageName.DownloadFile.rawValue:
            if let body = message.body as? [String : Any] {
                let bodyJson = JSON(body)
                self.jsNative!.downloadFile(request: bodyJson, eventId: bodyJson["EventId"].stringValue)
            }
            break
        case MessageName.OpenFile.rawValue:
            if let body = message.body as? [String : Any] {
                let bodyJson = JSON(body)
                self.jsNative!.openFile(filePath: bodyJson["FilePath"].stringValue, eventId: bodyJson["EventId"].stringValue)
            }
            break
        case MessageName.Reload.rawValue:
            self.jsNative!.reload()
            break
        case MessageName.CheckUserPermissions.rawValue:
            if let body = message.body as? [String : Any] {
                let bodyJson = JSON(body)
                self.jsNative!.checkUserPermissions(permission: bodyJson["PermissionCode"].stringValue, eventId: bodyJson["EventId"].stringValue)
            }
            break
        case MessageName.CallCustomNativeFunction.rawValue:
            if let body = message.body as? [String : Any] {
                let bodyJson = JSON(body)
                let eventId = bodyJson["EventId"].stringValue
                MobileFrameEngine.shared.delegate?.callCustomNativeFunction(functionName: bodyJson["FunctionName"].stringValue, data: bodyJson["Data"].dictionaryValue, resolve: { data in
                    self.jsNative?.resolveEvent(eventId: eventId, result: "`\(data.jsSafe())`")
                }, reject: { reason in
                    self.jsNative?.rejectEvent(eventId: eventId, reason: reason)
                })
            }
            break
        default: break
            
        }
    }
}
