//
//  MobileFrameEngine.swift
//  MobileFrame
//
//  Created by ERIC on 2021/11/15.
//

import Foundation
import SwiftyJSON

public protocol MobileFrameEngineDelegate {
    func callCustomNativeFunction(functionName: String, data: [String : Any], resolve: (@escaping (_ data: String) -> ()), reject: (@escaping (_ reason: String) -> ()))
    func mobileFrameUpdateOfflineResult(complate: Bool, totalCount: Int, updateCount: Int, progress: CGFloat)
    func logOut()
}

public class MobileFrameEngine {
    
    public static var shared = MobileFrameEngine()
    
    public static var mobileFrameVersion = "22.10.000"
    
    public var config = MobileFrameConfig()
    
    public var delegate: MobileFrameEngineDelegate?
    
    public var setAppConfigComplateBlock: (() -> Void)?
        
    internal var userInfo: UserInfoModel? {
        get {
            do {
                guard let userID = UserDefaults.standard.string(forKey: LoginManager.LoginUserID_Key) else {
                    return nil
                }
                let result:[UserInfoModel] = try SQLiteManager.default.userDB().select()
                var userInfo:UserInfoModel?
                for user in result {
                    if user.UserID == userID {
                        userInfo = user
                    }
                }
                return userInfo
            }
            catch {
                return nil
            }
        }
    }
                    
    public func initWithConfig(config: MobileFrameConfig, delegate: MobileFrameEngineDelegate?) {
        
        self.config = config
        
        self.delegate = delegate
        
        OfflineResourcesManager.shared.prestrainLocalResource()
        
        WebViewReusePool.swiftyLoad()
        
        HapticFeedbackManager.excuteLightFeedback()
    }
    
    public func checkUpdateVersion(_ downloadBlock: ((_ complate: Bool, _ totalCount: Int, _ updateCount: Int, _ progress: CGFloat) -> Void)?) {
        if NetworkStatusManager.shared.getNetworkStatus() {
            OfflineResourcesManager.shared.requestDashboards { complate, totalCount, updateCount, progress in
                downloadBlock?(complate, totalCount, updateCount, progress)
            
            }
        }
    }
}

extension MobileFrameEngine {
    public func entryDashboardFilePath() -> (Int, String) {
        return OfflineResourcesManager.shared.entryDashboardFilePath()
    }
    
    public func localDashboards() -> [Int] {
        var dashboardIDs: [Int] = []
        if let localDashboards = OfflineResourcesManager.shared.localDashboardModels {
            for dashboard in localDashboards {
                if let dashboardID = dashboard.DashboardID {
                    dashboardIDs.append(dashboardID)
                }
            }
        }
        return dashboardIDs
    }
}

extension MobileFrameEngine {
    public func login(userName: String, password: String, complated: (@escaping (_ isSuccess: Bool, _ result: JSON, _ msg: String)->())) {
        LoginManager.shared.clearCookie()

        LoginManager.shared.login(userName: userName, password: password) { isSuccess, result, msg in
            complated(isSuccess, JSON(result), msg)
        }
    }
    
    public func userLoggedOn() -> Bool {
        return LoginManager.shared.isLogin()
    }
    
    public func logOut() {
        LoginManager.shared.logOut()
        self.delegate?.logOut()
    }
}

extension MobileFrameEngine {
    public func emitEvent(eventId: String, data: String) {
        if let nav = APPDELEGATE?.window??.rootViewController as? NavigationViewController {
            if let webVc:WebViewController = nav.visibleViewController as? WebViewController {
                webVc.jsNative.emitEvent(eventId: eventId, data: data)
            }
        }
    }
}
