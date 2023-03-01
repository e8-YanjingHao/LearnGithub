//
//  LoginManager.swift
//  MobileFrameExampleApp
//
//  Created by ERIC on 2021/11/16.
//

import Foundation
import SwiftyJSON
import SQLite

internal class LoginManager {
    
    static var shared = LoginManager()
    
    static let LoginAuthID_Key = "LoginAuthID_Key"
    static let LoginCookie_Key = "LoginCookie_Key"
    static let LoginUserName_Key = "loginUserName_Key"
    static let LoginPassword_Key = "loginPassword_Key"
    static let LoginHandleID_Key = "LoginHandleID_Key"
    static let LoginUserID_Key = "LoginUserID_Key"
    static let LoginSessionID_Key = "LoginSessionID_Key"
    static let EchatSessionID_Key = "EchatSessionID_Key"
    static let LoginPermissions_Key = "LoginPermissions_Key"
    static let LoginSessionExpireTime_Key = "SessionExpireTime"
    
    var lastAutoLoginTime = 0;
    let semaphore = DispatchSemaphore(value: 1)
    let loginQueue = DispatchQueue(label: "LoginQueue")
   
    func login(userName: String, password: String, complated: (@escaping (_ isSuccess: Bool, _ result: Any, _ msg: String)->())) {
        let timeInterval = Date().timeIntervalSince1970
        let time = llround(timeInterval*1000.0)
        let millisecond = Int(time)
        
        if millisecond - lastAutoLoginTime < 1000 {
            complated(true, "", "Success")
            return
        }
        
        var style = userName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        var support = false
        
        if style.hasSuffix("$") {
            style.remove(at: style.index(before: style.endIndex))
            support = true
        }
        
        style = style.md5
        
        if support {
            style += "$"
        }
        
        if userName.isEmail {
            style = "@" + style
        }

        let handheldID = UserDefaults.standard.value(forKey: LoginManager.LoginHandleID_Key) ?? ""
        let params: [String: Any] = [
            "Style": style,
            "Theme": password.md5,
            "HandheldID": handheldID,
            "DeviceSerialNum": device_serial_number,
            "Rev": app_version,
            "MobileFrameAppID": MobileFrameEngine.shared.config.mobileFrameAppID,
            "WebRequestID": UUID().uuidString,
            "Platform": "iOS"
        ]
                
        NetWorkManager.shared.postWithPath(path: API.login(), paras: params) { [unowned self] result1 in
            
            let resultJson = JSON(result1)
            let status = resultJson["Status"].intValue
            let handheldID = resultJson["HandheldID"].stringValue
            let uploadDatabase = resultJson["UploadDatabase"].intValue
            let encompassSessionID = resultJson["EncompassSessionID"].stringValue
            let permissions = resultJson["Permissions"].stringValue
            let sessionExpireTime = resultJson["SessionExpireTime"].stringValue
            
            if status == 1 {
                self.saveLoginResponseData(userID: resultJson["UserID"].stringValue, userName: userName, password: password, authId: resultJson["AuthenticationID"].stringValue, handheldID: handheldID, sessionID: encompassSessionID, permissions: permissions, sessionExpireTime: sessionExpireTime, result: resultJson)
                
                if MobileFrameEngine.shared.config.enableEChat {
                    self.verifySession { VerifySuccess, SocketSessionID, SocketServerURL in
                    }
                }
                
                let timeInterval = Date().timeIntervalSince1970
                let time = llround(timeInterval*1000.0)
                let millisecond = Int(time)
                
                lastAutoLoginTime = millisecond
                
                complated(true, result1, "Success")
            }
            else {
                complated(false, [:], resultJson["Message"].stringValue)
            }
            
            if uploadDatabase == 1 {
                NetWorkManager.shared.uploadLogs(memo: "Login after UploadDatabase = true")
            }
            
        } failure: { error in
            complated(false, [:], error.localizedDescription)
        }
    }
    
    func autoLogin(complated: (@escaping (_ isSuccess: Bool)->())) {
        
        if LoginManager.shared.isLogin() == false {
            return
        }
        
        guard let userName = UserDefaults.standard.string(forKey: LoginManager.LoginUserName_Key)  else {
            complated(false)
            return
        }
        
        guard let password = UserDefaults.standard.string(forKey: LoginManager.LoginPassword_Key) else {
            complated(false)
            return
        }
        
        self.loginQueue.async {
            self.semaphore.wait()
            self.login(userName: userName, password: password) {isSuccess, result, msg in
                complated(isSuccess)
                self.semaphore.signal()
            }
        }
    }
    
    func isLogin() -> Bool {
        guard let _ = UserDefaults.standard.string(forKey: LoginManager.LoginAuthID_Key) else {
            return false
        }
        
        return true
    }
    
    func saveLoginResponseData(userID: String, userName: String, password: String, authId: String, handheldID: String, sessionID: String, permissions: String, sessionExpireTime: String, result: JSON) {
        
        UserDefaults.standard.set(userID, forKey: LoginManager.LoginUserID_Key)
        UserDefaults.standard.set(authId, forKey: LoginManager.LoginAuthID_Key)
        UserDefaults.standard.set(userName, forKey: LoginManager.LoginUserName_Key)
        UserDefaults.standard.set(password, forKey: LoginManager.LoginPassword_Key)
        UserDefaults.standard.set(handheldID, forKey: LoginManager.LoginHandleID_Key)
        UserDefaults.standard.set(sessionID, forKey: LoginManager.LoginSessionID_Key)
        UserDefaults.standard.set(permissions, forKey: LoginManager.LoginPermissions_Key)
        UserDefaults.standard.set(sessionExpireTime, forKey: LoginManager.LoginSessionExpireTime_Key)
        UserDefaults.standard.synchronize()
        
        try? SQLiteManager.default.userDB().insert(UserInfoModel(jsonData: result))
    }
    
    func updateSession(complated: (@escaping (_ isSuccess: Bool)->())) {
        NetWorkManager.shared.fetch(path: API.updateSession(), method: "GET", httpBody: nil, httpFormData: nil, header: nil) { response, data in
            complated(true);
        } failure: { error in
            SLogError("Update Session Error: " + error.localizedDescription)
            complated(false);
        }
    }
    
    func verifySession(verifyBlock: @escaping ((_ VerifySuccess: Bool, _ SocketSessionID: String, _ SocketServerURL: String) -> Void)) {
        
        if LoginManager.shared.isLogin() != true {
            verifyBlock(false, "", "")
            return
        }
        
        guard let globalStaticModel = OfflineResourcesManager.shared.localGlobalModel else {
            verifyBlock(false, "", "")
            return
        }
        
        guard let eChatServerUrl = globalStaticModel.EChatServerUrl?.sqlToN(), eChatServerUrl != "" else {
            verifyBlock(false, "", "")
            return
        }
        
        guard let sessionID = UserDefaults.standard.string(forKey:  LoginManager.LoginSessionID_Key) else {
            verifyBlock(false, "", "")
            return
        }
        
        let params = [
            "EncompassDBServer": globalStaticModel.EncompassDBServer ?? "",
            "EncompassSessionID": sessionID,
            "EncompassDistributor": MobileFrameEngine.shared.config.encompassID,
            "SessionID": self.getEchatSessionID(),
            "Platform": "3",
            "Action": "VerifySession"
        ]
        
        NetWorkManager.shared.postWithPath(path: eChatServerUrl, paras: params) { [unowned self] result in
            let data = JSON(result)
            let SocketSessionID = data["Data"]["SocketSessionID"].stringValue
            let SocketServerURL = data["Data"]["SocketServerURL"].stringValue
            let EnableEChat = data["Data"]["EnableEChat"].boolValue
            
            if EnableEChat == true && self.saveEchatSessionID(sessionID: SocketSessionID) {
                self.addDeviceToken(sessionID: SocketSessionID, serverURL: eChatServerUrl) { success in
                    if success {
                        verifyBlock(true, SocketSessionID, SocketServerURL)
                    }
                    else {
                        verifyBlock(false, "", "")
                    }
                }
                
                self.getUnreadMessageGroups { unreadCount in
                }
            }
            else {
                SLogInfo("No have permission.")

                verifyBlock(false, "", "")
            }
        } failure: { error in
            SLogError("VerifySession Fail.")
            verifyBlock(false, "", "")
        }
    }
    
    func addDeviceToken(sessionID: String, serverURL: String, block: (@escaping (_ success: Bool) -> ())) {
        guard let deviceTokenStr = UserDefaults.standard.string(forKey: "DeviceToken") else {
            return
        }
        
        let device = UIDevice.current

        var parameters = [String: Any]()
        parameters["SessionID"] = sessionID
        parameters["DeviceToken"] = deviceTokenStr
        parameters["UUID"] = device.identifierForVendor?.uuidString
        parameters["BundleID"] = Bundle.main.bundleIdentifier
        parameters["Platform"] = Env.isProduction() ? "1" : "2"
        parameters["DeviceName"] = device.name
        parameters["DeviceType"] = "\(device.model) \(device.systemName) \(device.systemVersion)"
        parameters["DeviceVersion"] = "MobileFrame \(MobileFrameEngine.mobileFrameVersion)"
        parameters["Action"] = "AddDeviceToken"
        
        NetWorkManager.init().postWithPath(path: serverURL, paras: parameters) { result in
            block(true)
        } failure: { error in
            block(false)
        }
    }
    
    func deleteDeviceToken(block: (@escaping (_ success: Bool) -> ())) {
        if LoginManager.shared.isLogin() != true {
            return
        }
        
        guard let globalStaticModel = OfflineResourcesManager.shared.localGlobalModel else {
            return
        }
        
        guard let eChatServerUrl = globalStaticModel.EChatServerUrl?.sqlToN(), eChatServerUrl != "" else {
            return
        }
        
        let device = UIDevice.current
        
        var parameters = [String: Any]()
        parameters["SessionID"] = self.getEchatSessionID()
        parameters["UUID"] = device.identifierForVendor?.uuidString
        parameters["Action"] = "DeleteDeviceToken"
        
        NetWorkManager.init().postWithPath(path: eChatServerUrl, paras: parameters) { result in
            block(true)
        } failure: { error in
            block(false)
        }
        
    }
    
    func getUnreadMessageGroups(block: @escaping ((_ unreadCount: Int) -> Void)) {
        
        if LoginManager.shared.isLogin() != true {
            block(0)
            return
        }
        
        guard let globalStaticModel = OfflineResourcesManager.shared.localGlobalModel else {
            block(0)
            return
        }
        
        guard let eChatServerUrl = globalStaticModel.EChatServerUrl?.sqlToN(), eChatServerUrl != "" else {
            block(0)
            return
        }
        
        let params = [
            "SessionID": self.getEchatSessionID(),
            "Action" : "GetUnreadMessageGroups2010"
        ]
        
        NetWorkManager.shared.postWithPath(path: eChatServerUrl, paras: params) { result in
            let data = JSON(result)
            let unreadCount = data["Data"].dictionaryValue.keys.count
            if let nav = APPDELEGATE?.window??.rootViewController as? NavigationViewController {
                if let webVc:WebViewController = nav.visibleViewController as? WebViewController {
                    webVc.jsNative.updateEchatUnReadCount(unReadCount: unreadCount)
                }
            }
            
            block(unreadCount)
        } failure: { error in
            SLogError("GetUnreadMessageGroups2010 Fail.")
            block(0)
        }
    }
    
    @discardableResult
    func checkUserPermission(permission: String) -> Bool {
        guard let userPermission = UserDefaults.standard.string(forKey: LoginManager.LoginPermissions_Key) else {
            return false
        }
        
        if userPermission.contains(permission) {
            return true
        }
        else {
            return false
        }
    }
    
    @discardableResult
    func saveEchatSessionID(sessionID: String) -> Bool {
        if sessionID.isBlank {
            return false
        }
        
        UserDefaults.standard.set(sessionID, forKey: LoginManager.EchatSessionID_Key)

        return true
    }
    
    func getEchatSessionID() -> String {
        return UserDefaults.standard.string(forKey: LoginManager.EchatSessionID_Key) ?? ""
    }
    
    @discardableResult
    func saveCookies(cookieData: String) -> Bool {
        if cookieData.isBlank {
            return false
        }
        
        UserDefaults.standard.set(cookieData, forKey: LoginManager.LoginCookie_Key)

        return true
    }
    
    func getCookieData() -> String? {
        return UserDefaults.standard.string(forKey:  LoginManager.LoginCookie_Key)
    }
    
    func clearCookie() {
        if let cookies = HTTPCookieStorage.shared.cookies {
            for cookie in cookies {
                HTTPCookieStorage.shared.deleteCookie(cookie)
            }
        }
        
        UserDefaults.standard.removeObject(forKey: LoginManager.LoginCookie_Key)
        UserDefaults.standard.synchronize()
    }
    
    func logOut() {
        deleteDeviceToken { success in
            
        }
        
        self.clearCookie()
        
        UserDefaults.standard.removeObject(forKey:  LoginManager.LoginAuthID_Key)
        UserDefaults.standard.removeObject(forKey:  LoginManager.LoginUserName_Key)
        UserDefaults.standard.removeObject(forKey:  LoginManager.LoginPassword_Key)
        UserDefaults.standard.removeObject(forKey: LoginManager.LoginCookie_Key)
        UserDefaults.standard.removeObject(forKey: LoginManager.LoginHandleID_Key)
        UserDefaults.standard.removeObject(forKey: LoginManager.LoginSessionID_Key)
        UserDefaults.standard.removeObject(forKey: LoginManager.EchatSessionID_Key)
        UserDefaults.standard.removeObject(forKey: LoginManager.LoginSessionExpireTime_Key)
        UserDefaults.standard.synchronize()
    }
}
