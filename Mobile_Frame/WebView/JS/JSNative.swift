//
//  JSChannel.swift
//  ScanCode
//
//  Created by Encompass on 2021/11/11.
//

import UIKit
import WebKit
import AVFoundation
import SwiftyJSON
import SQLite
import Alamofire
import QuickLook

//The method name that needs to be injected into JS (the channel name is the same as the method name)
enum MessageName: String, CaseIterable {
    case Open                       = "Open"
    case NavigateTo                 = "NavigateTo"
    case RedirectTo                 = "RedirectTo"
    case NavigateBack               = "NavigateBack"
    case ScanQRCode                 = "ScanQRCode"
    case GetLocation                = "GetLocation"
    case GetAppInfo                 = "GetAppInfo"
    case StorageSetItem             = "StorageSetItem"
    case StorageGetItem             = "StorageGetItem"
    case StorageRemoveItem          = "StorageRemoveItem"
    case StorageKeys                = "StorageKeys"
    case Login                      = "Login"
    case Logout                     = "Logout"
    case Log                        = "Log"
    case UploadLogs                 = "UploadLogs"
    case ExecuteSQL                 = "ExecuteSQL"
    case SetAppConfig               = "SetAppConfig"
    case GetAppConfig               = "GetAppConfig"
    case OpenAppSettings            = "OpenAppSettings"
    case SubmitAPIRequest           = "SubmitAPIRequest"
    case DownloadFile               = "DownloadFile"
    case OpenFile                   = "OpenFile"
    case Reload                     = "Reload"
    case CheckUserPermissions       = "CheckUserPermissions"
    case CallCustomNativeFunction   = "CallCustomNativeFunction"
    case SwitchTo                   = "SwitchTo"
}

internal class JSNative: NSObject {
    
    weak var currentWVC : WebViewController?
    
    init(webVC : WebViewController?) {
        self.currentWVC = webVC
    }
    
    //MARK : Full UrlStr
    func open(urlStr: String?) {
        if let navigateVC = getNavigateVC() {
            let newWebVC = WebViewController.init()
            newWebVC.urlStr = urlStr
            navigateVC.pushViewController(newWebVC, animated: true)
            self.currentWVC?.devTools.devToolsView.isHidden = true
        }
    }
    
    func navigateTo(dashboardId: Int, queryString: String?) {
        if let navigateVC = getNavigateVC() {
            let newWebVC = WebViewController.init()
            newWebVC.dashboardId = dashboardId
            newWebVC.dashboardQueryString = queryString
            newWebVC.callBack = { [weak self] params in
                guard let self = self else { return }
                
                guard let eventId = params["EventId"] else {
                    return
                }
                
                if let data = params["Data"] {
                    guard JSONSerialization.isValidJSONObject(data) else {
                        return
                    }
                    
                    let jsonData = try? JSONSerialization.data(withJSONObject: data, options: [])
                    var result = ""
                    if let jsonData = jsonData {
                        result = String(data: jsonData, encoding: String.Encoding.utf8) ?? ""
                    }
                    self.resolveEvent(eventId: String(describing: eventId), result: result)
                }
                else {
                    self.resolveEvent(eventId: String(describing: eventId), result: nil)
                }
            }
            
            navigateVC.pushViewController(newWebVC, animated: true)
            
            self.currentWVC?.devTools.devToolsView.isHidden = true
        }
    }
    
    //MARK : back
    func navigateBack(params: [String : Any]?) {
        var delta : Int = 1
        if let navigateVC = getNavigateVC() {
            if let aParams = params, let aCurrentWVC = currentWVC, let callBack = aCurrentWVC.callBack {
                callBack(aParams)
                if let aDelta = aParams["Delta"] as? Int {
                    delta = aDelta
                }
            }
            
            if(delta >=  navigateVC.viewControllers.count - 1){
                navigateVC.popToRootViewController(animated: currentWVC?.interactivePop == true ? true : false)
            }else{
                
                navigateVC.popToViewController(navigateVC.viewControllers[navigateVC.viewControllers.count - delta], animated: currentWVC?.interactivePop == true ? true : false)
            }
        }
    }
    
    //MARK : redirect
    func redirectTo(dashboardId: Int?, queryString: String) {
        if let navigateVC = getNavigateVC(), currentWVC != nil, let realId = dashboardId {
            let isOfflineDashboard = OfflineResourcesManager.shared.offLineByDashboardID(dashboardID: realId)
            if isOfflineDashboard {
                
                if let vc = currentWVC {
                    navigateVC.viewControllers.removeAll()
                    navigateVC.viewControllers.append(vc)
                }
                currentWVC?.devTools.devToolsView.switchView.setOn(MobileFrameEngine.shared.config.isGlobalDraft, animated: true)
                currentWVC?.dashboardId = realId
                currentWVC?.dashboardQueryString = queryString
                currentWVC?.startLoadWebview()
            }
            else {
                navigateTo(dashboardId: realId, queryString: queryString)
            }
        }
    }
    
    func switchTo(dashboardId: Int?, queryString: String) {
        if let navigateVC = getNavigateVC(), currentWVC != nil, let realId = dashboardId {
            let isOfflineDashboard = OfflineResourcesManager.shared.offLineByDashboardID(dashboardID: realId)
            if isOfflineDashboard {
                
                if let vc = currentWVC {
                    navigateVC.viewControllers.removeLast()
                    navigateVC.viewControllers.append(vc)
                }
                currentWVC?.devTools.devToolsView.switchView.setOn(MobileFrameEngine.shared.config.isGlobalDraft, animated: true)
                currentWVC?.dashboardId = realId
                currentWVC?.dashboardQueryString = queryString
                currentWVC?.startLoadWebview()
            }
            else {
                navigateTo(dashboardId: realId, queryString: queryString)
            }
        }
    }
    
    //MARK : Scan code
    func scanQRCode(eventId: String) {
        if let currentWVC = currentWVC {
            PermissionUtil.canAccessCamera(vc: currentWVC, callBack: {[weak self] granted in
                guard let self = self else { return }
                if granted == true {
                    let codeScannerVC = CodeScannerViewController()
                    codeScannerVC.scanResultCallBack = {[weak self] result in
                        guard let self = self else { return }
                        
                        if let result: String = [
                            "result": result,
                            "Status": true
                        ].toJsonString() {
                            self.resolveEvent(eventId: eventId, result: "\(result)")
                        }
                        else {
                            self.rejectEvent(eventId: eventId, reason: "Json format error")
                        }
                        
                    }
                    currentWVC.navigationController?.present(codeScannerVC, animated: true, completion: nil)
                }
                else {
                    if let result: String = [
                        "result": "null",
                        "Status": false
                    ].toJsonString() {
                        self.rejectEvent(eventId: eventId, reason: "\(result)")
                    }
                    else {
                        self.rejectEvent(eventId: eventId, reason: "Json format error")
                    }
                }
            })
        }
    }
    
    //MARK : Get Location
    func getLocation(eventId: String) {
        if let currentWVC = currentWVC {
            PermissionUtil.canLocation(vc: currentWVC) { [weak self] granted in
                if granted == true {
                    LocationManager.shared.startRequestLocation()
                    LocationManager.shared.locationComplateBlock = { lat, lng in
                        if let result: String = [
                            "Latitude": lat,
                            "Longitude": lng,
                            "Status": true
                        ].toJsonString() {
                            self?.resolveEvent(eventId: eventId, result: result)
                        }
                    }
                }
                else {
                    if let result: String = [
                        "Latitude": "null",
                        "Longitude": "null",
                        "Status": false
                    ].toJsonString() {
                        self?.rejectEvent(eventId: eventId, reason: result)
                    }
                }
            }
        }
    }
    
    func getAppInfo(eventId: String) {
        let deviceInfo : [String : Any] = deviceInfo
        if let result = deviceInfo.toJsonString() {
            self.resolveEvent(eventId: eventId, result: "\(result)")
        }
    }
    
    func login(userName: String, passWord: String, eventId: String) {
        LoginManager.shared.login(userName: userName, password: passWord) { [weak self] (isSuccess, result, msg) in
            let resp = [
                "status": isSuccess ? "success" : "fail",
                "message": msg,
                "LoginInfo": result
            ].toJsonString()
            self?.resolveEvent(eventId: eventId, result: resp)
        }
    }
    
    func logout() {
        MobileFrameEngine.shared.logOut()
    }
    
    func storageSetItem(key: String, content: String, eventId: String) {
        if key.isBlank {
            self.rejectEvent(eventId: eventId, reason: "key cannot be empty")
            return
        }
        do {
            try SQLiteManager.default.userDB().insert(NetCachesModel(key: key.sqlSafe(), content: content.sqlSafe()))
            self.resolveEvent(eventId: eventId, result: nil)
        }
        catch let err as NSError {
            self.rejectEvent(eventId: eventId, reason: err.description)
        }
    }
    
    func storageGetItem(key: String, eventId: String) {
        if key.isBlank {
            self.rejectEvent(eventId: eventId, reason: "key cannot be empty")
            return
        }
        do {
            let result: [NetCachesModel] = try SQLiteManager.default.userDB().select(["Key": key.sqlSafe()])
            self.resolveEvent(eventId: eventId, result: result.count >= 1 ? result.first!.Content.sqlToN() : nil)
        }
        catch let err as NSError {
            self.rejectEvent(eventId: eventId, reason: err.description)
        }
    }
    
    func storageRemoveItem(key: String, eventId: String) {
        if key.isBlank {
            self.rejectEvent(eventId: eventId, reason: "key cannot be empty")
            return
        }
        
        do {
            try SQLiteManager.default.userDB().delete(NetCachesModel.tableName, filter: ["Key": key.sqlSafe()])
            self.resolveEvent(eventId: eventId, result: nil)
        }
        catch let err as NSError {
            self.rejectEvent(eventId: eventId, reason: err.description)
        }
    }
    
    func storageGetKeys(_prefix: String, eventId: String) {
        if(SQLiteManager.default.userDB().exists(tableName: NetCachesModel.tableName) == false) {
            do {
                let _ = try SQLiteManager.default.userDB().create(NetCachesModel(key: _prefix.sqlSafe(), content: ""))
                self.resolveEvent(eventId: eventId, result: "[]")
            }
            catch let err as NSError {
                self.rejectEvent(eventId: eventId, reason: err.description)
            }
            return
        }
        let sql = "SELECT (Key) FROM \(NetCachesModel.tableName) WHERE Key LIKE '\(_prefix.sqlSafe())%'"
        do {
            let results = try SQLiteManager.default.userDB().prepare(sql)
            var keys: [String] = []
            results.forEach { item in
                keys.append(item["Key"] as! String)
            }
            self.resolveEvent(eventId: eventId, result: "[" + keys.map{"'\($0)'"}.joined(separator: ",") + "]")
        }
        catch let err as NSError {
            self.rejectEvent(eventId: eventId, reason: err.description)
        }
    }
    
    func log(content: String) {
        SLogDebug("From js:" + content)
    }
    
    func makeCall(phoneNumber: String?) {
        if phoneNumber != nil {
            if phoneNumber!.contains("tel"), UIApplication.shared.canOpenURL(URL.init(string: phoneNumber!)!) {
                UIApplication.shared.open(URL.init(string: phoneNumber!)!, options: [:], completionHandler: nil)
            } else if !phoneNumber!.contains("tel://") {
                let url = "telprompt://\(phoneNumber!)"
                if UIApplication.shared.canOpenURL(URL.init(string: url)!) {
                    UIApplication.shared.open(URL.init(string: url)!, options: [:], completionHandler: nil)
                }
            }
        }
    }
    
    func prepareSql(sql: String, eventId: String) {
        if sql.isBlank {
            self.rejectEvent(eventId: eventId, reason: "sql cannot be empty")
            return
        }
        do {
            let result = try SQLiteManager.default.userDB().prepare(sql)
            self.resolveEvent(eventId: eventId, result: result.toJsonString())
        }
        catch let err as NSError {
            self.rejectEvent(eventId: eventId, reason: err.description)
        }
    }
    
    func uploadLogs(eventId: String, memo: String) {
        let zipFileName = "\(Int(Date().timeIntervalSince1970))_carshLogs.zip"
        
        let zipPath = (MobileFrameEngine.shared.config.cachesPath as NSString).appendingPathComponent(zipFileName)
        let datebasesPath = (MobileFrameEngine.shared.config.logFilePath as NSString).appendingPathComponent("databases")
        let (copySuccess, _) = LocalFileManager.copyFile(type: .directory, fromeFilePath: MobileFrameEngine.shared.config.globalStaticDatabasePath, toFilePath: datebasesPath)
        if copySuccess == false {
            self.rejectEvent(eventId: eventId, reason: "databases copy fail")
            return
        }
        let success = ZipArchiveManager.share.zip(filePath: zipPath, zipPath: MobileFrameEngine.shared.config.logFilePath)
        if success == true {
            NetWorkManager.shared.uploadFile(path: zipPath, memo: memo) { result in
                if result.isBlank == false {
                    LocalFileManager.removefile(filePath: zipPath)
                    
                    self.resolveEvent(eventId: eventId, result: "'\(result)'")
                }
                else {
                    self.rejectEvent(eventId: eventId, reason: "")
                }
            } failure: { error in
                self.rejectEvent(eventId: eventId, reason: (error as NSError).description)
            }
        }
        else {
            self.rejectEvent(eventId: eventId, reason: "Resource compression failed")
        }
    }
    
    func setAppConfig(config: JSON, eventId: String) {
        let encompassID = config["EncompassID"].stringValue
        let serverHost = config["ServerHost"].stringValue
        let userAgent = config["UserAgent"].stringValue
        let devTools = config["DevTools"].boolValue
        
        if encompassID.isBlank {
            self.rejectEvent(eventId: eventId, reason: "EncompassID cannot be empty")
            return
        }
        if serverHost.isBlank {
            self.rejectEvent(eventId: eventId, reason: "ServerHost cannot be empty")
            return
        }
        if userAgent.isBlank {
            self.rejectEvent(eventId: eventId, reason: "UserAgent cannot be empty")
            return
        }
        if serverHost.isURL == false {
            self.rejectEvent(eventId: eventId, reason: "ServerHost is not in the correct format")
            return
        }
        
        MobileFrameEngine.shared.config.updateGlobalConfig(encompassID: encompassID, serverHost: serverHost, userAgent: userAgent, devTools: devTools)
        
        if let block = MobileFrameEngine.shared.setAppConfigComplateBlock {
            LoginManager.shared.logOut()
            
            block()
            
            self.resolveEvent(eventId: eventId, result: "")
        }
        else {
            self.rejectEvent(eventId: eventId, reason: "Set App Config error")
        }
    }
    
    func getAppConfig(eventId: String) {
        if let result: String = [
            "EncompassID" : MobileFrameEngine.shared.config.encompassID,
            "ServerHost" : MobileFrameEngine.shared.config.serverHost,
            "UserAgent" : MobileFrameEngine.shared.config.userAgent,
            "DevTools" : MobileFrameEngine.shared.config.devTools,
        ].toJsonString() {
            self.resolveEvent(eventId: eventId, result: result)
        }
        else {
            self.rejectEvent(eventId: eventId, reason: "Json format error")
        }
    }
    
    func openAppSettings() {
        let settingUrl = NSURL(string: UIApplication.openSettingsURLString)!
        if UIApplication.shared.canOpenURL(settingUrl as URL) {
            UIApplication.shared.open(settingUrl as URL, options: [:], completionHandler: nil)
        }
    }
    
    func downloadFile(request: JSON, eventId: String) {
        let url = request["Url"].stringValue
        let bodyData = request["PostData"].dictionaryValue
        let filePath = request["FilePath"].stringValue
        var fileName = ""
        var path = ""
        if filePath.isBlank == false {
            var filePathPart = filePath.split(separator: "/")
            fileName = String(filePathPart.removeLast())
            path = filePathPart.joined(separator: "/")
        }
        
        var i = 0
        var httpBody = ""
        for (key, value) in bodyData {
            if i == 0 {
                httpBody += "\(key)=\(value)"
            }else {
                httpBody += "&\(key)=\(value)"
            }
            i += 1
        }
        
        NetWorkManager.shared.fetch(path: url, method: httpBody.isBlank ? "GET" : "POST", httpBody: httpBody.data(using: .utf8), httpFormData: nil, header: nil) { response, data in
            
            var fileLength = 0
            if let data = data {
                fileLength = data.count
            }
            
            if fileLength == 0 {
                self.rejectEvent(eventId: eventId, reason: "Data is Empty")
                return
            }
            
            if filePath.isBlank {
                if let respond = response as? HTTPURLResponse {
                    if let content = respond.allHeaderFields["Content-Disposition"] {
                        let disposition = String(describing: content)
                        
                        let regex = try! NSRegularExpression(pattern: "filename=\".*?\"", options:[])
                        if let match = regex.firstMatch(in: disposition, range: NSRange(disposition.startIndex...,in: disposition)) {
                            fileName = ((disposition as NSString).substring(with: match.range) as NSString).substring(from: 9).replacingOccurrences(of: "\"", with: "")
                        }
                    }
                }
                
                if fileName.isBlank {
                    self.rejectEvent(eventId: eventId, reason: "Failed to get FileName")
                    return
                }
                
                let writeFilePath = (MobileFrameEngine.shared.config.tmpPath as NSString).appendingPathComponent(fileName)
                
                let (isuccess, _) = LocalFileManager.createFile(filePath: writeFilePath)
                
                if isuccess == false {
                    self.rejectEvent(eventId: eventId, reason: "File Create Fail")
                    return
                }
                
                let (successi, _) = LocalFileManager.writeToFile(writeType: LocalFileManager.FileWriteType.BinaryType, content: data!, writePath: writeFilePath)
                
                if successi == false {
                    self.rejectEvent(eventId: eventId, reason: "File Data Write To file Fail")
                    return
                }
                
                self.resolveEvent(eventId: eventId, result: "'\(writeFilePath)'")
            }
            else {
                let writeFilePath = (MobileFrameEngine.shared.config.documentPath as NSString).appendingPathComponent(filePath)
                
                let (foldSuccess, _) = LocalFileManager.createFolder(folderPath: (MobileFrameEngine.shared.config.documentPath as NSString).appendingPathComponent(path))
                
                if foldSuccess == false {
                    self.rejectEvent(eventId: eventId, reason: "Folder Create Fail")
                    return
                }
                
                let (isuccess, _) = LocalFileManager.createFile(filePath: writeFilePath)
                
                if isuccess == false {
                    self.rejectEvent(eventId: eventId, reason: "File Create Fail")
                    return
                }
                
                let (successi, _) = LocalFileManager.writeToFile(writeType: LocalFileManager.FileWriteType.BinaryType, content: data!, writePath: writeFilePath)
                
                if successi == false {
                    self.rejectEvent(eventId: eventId, reason: "File Data Write To file Fail")
                    return
                }
                
                self.resolveEvent(eventId: eventId, result: "'\(writeFilePath)'")
            }
        } failure: { error in
            self.rejectEvent(eventId: eventId, reason: (error as NSError).description)
        }
    }
    
    func openFile(filePath: String, eventId: String) {
        if filePath.isBlank {
            self.rejectEvent(eventId: eventId, reason: "Failed to get FilePath")
            return
        }
        
        if LocalFileManager.judgeFileOrFolderExists(filePath: filePath) == false {
            self.rejectEvent(eventId: eventId, reason: "File is not exist")
            return
        }
        
        if let navigateVC = getNavigateVC() {
            let vc  = QuickLookViewController()
            vc.filePath = filePath
            navigateVC.pushViewController(vc, animated: true)
        }
    }
    
    func submitAPIRequest(request: JSON, eventId: String) {
        var url = request["Url"].stringValue 
        
        if url.isBlank == true {
            self.rejectEvent(eventId: eventId, reason: "Bad Request Url.")
            return
        }
        
        if url.starts(with: "https://") == false {
            url = MobileFrameEngine.shared.config.serverHost + "/" + request["Url"].stringValue
        }
        
        let method = request["Method"].stringValue
        let timeOutInSeconds = request["Timeout"].stringValue
        let contentType = request["ContentType"].stringValue
        let bodyString = request["BodyString"].stringValue
        let headers = request["Headers"].arrayValue
        let bodyData = request["BodyData"].arrayValue
        
        var formatHeader: [String: String] = [
            "Content-Type": contentType,
            "Timeout": timeOutInSeconds,
            "User-Agent": MobileFrameEngine.shared.config.userAgent
        ]
        for json in headers {
            let key = json["Header"].stringValue
            let value = json["Value"].stringValue
            if key.isBlank == false {
                formatHeader[key] = value
            }
        }
        
        if bodyString.isBlank == false {
            NetWorkManager.shared.fetch(path: url, method: method, httpBody: bodyString.data(using: .utf8), httpFormData: nil, header: formatHeader) { response, data in
                var dataStr = ""
                if let data = data {
                    dataStr = String(data: data, encoding: .utf8) ?? ""
                }
                self.resolveEvent(eventId: eventId, result: "`\(dataStr.jsSafe())`")
                
            } failure: { error in
                self.rejectEvent(eventId: eventId, reason: (error as NSError).description)
            }
        }
        else {
            var formData: [[String: Any]] = []
            for data in bodyData {
                let isBase64 = data["IsBase64"].boolValue
                let name = data["Name"].stringValue
                let value = data["Value"].stringValue
                
                if name.isBlank == true {
                    self.rejectEvent(eventId: eventId, reason: "Name is None")
                    return
                }
                
                if isBase64 == true {
                    let base64Split = value.split(separator: ",")
                    if base64Split.count == 2 {
                        let base64Value: String = String(base64Split[1])
                        
                        if let d = Data(base64Encoded: base64Value) {
                            formData.append([
                                "isFile": true,
                                "value": d,
                                "key": name
                            ])
                        }
                        else {
                            self.rejectEvent(eventId: eventId, reason: "File Base64 Change Fail")
                            return
                        }
                    }
                }
                else {
                    if let d = value.data(using: .utf8) {
                        formData.append([
                            "isFile": false,
                            "value": d,
                            "key": name
                        ])
                    }
                }
            }
            
            NetWorkManager.shared.fetch(path: url, method: method, httpBody: bodyString.data(using: .utf8), httpFormData: formData.count != 0 ? formData : nil, header: formatHeader) { response, data in
                var dataStr = ""
                if let data = data {
                    dataStr = String(data: data, encoding: .utf8) ?? ""
                }
                self.resolveEvent(eventId: eventId, result: "`\(dataStr.jsSafe())`")
                
            } failure: { error in
                self.rejectEvent(eventId: eventId, reason: (error as NSError).description)
            }
        }
    }
    
    func reload() {
        currentWVC?.startLoadWebview()
    }
    
    func checkUserPermissions(permission: String, eventId: String) {
        if permission.isBlank == true {
            self.resolveEvent(eventId: eventId, result: "0")
            return
        }
        
        self.resolveEvent(eventId: eventId, result: LoginManager.shared.checkUserPermission(permission: permission) ? "1" : "0")
    }
    
    private func evalJS(js: String) {
        currentWVC?.evalJS(js: js)
    }
    
    func isVCActive() -> Bool {
        if let _ = currentWVC {
            return true
        }
        return false
    }
    
    func getNavigateVC() -> NavigationViewController? {
        if isVCActive() {
            if let navigateVC : NavigationViewController = currentWVC!.navigationController as? NavigationViewController {
                return navigateVC
            }
        }
        return nil
    }
    
    public func registerCurrentWebView(webview: WebViewController?) {
        currentWVC = webview
    }
    
}

extension JSNative {
    func resolveEvent(eventId: String, result: String?) {
        var js : String?
        if let result = result {
            js = "EC_App.EventCenter.ResolveEvent('\(eventId)', \(result))"
        } else {
            js = "EC_App.EventCenter.ResolveEvent('\(eventId)', null)"
        }
        self.evalJS(js: js!)
    }
    
    func rejectEvent(eventId: String, reason: String) {
        let js = "EC_App.EventCenter.RejectEvent('\(eventId)', `\(reason.jsSafe())`)"
        self.evalJS(js: js)
    }
}

extension JSNative {
    func updateEchatUnReadCount(unReadCount: Int) {
        self.evalJS(js: "EC_App.UpdateUnreadCount(\(unReadCount));")
    }
    
    func emitEvent(eventId: String, data: String) {
        self.evalJS(js: "ECP.Tools.EventBus.Emit('\(eventId)', `\(data.jsSafe())`);")
    }
}
