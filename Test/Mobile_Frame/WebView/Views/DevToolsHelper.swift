//
//  DevToolsHelper.swift
//  MobileFrame
//
//  Created by Encompass on 2021/12/27.
//

import UIKit
import WebKit

internal class DevToolsHelper: NSObject, DevToolsViewDelegate {
    weak var webViewVC : WebViewController?
    
    init(webVC : WebViewController?) {
        self.webViewVC = webVC
    }
    
    func devToolsClose(_ devToolsView: DevToolsView) {
        
    }
    
    func devToolsClear(_ devToolsView: DevToolsView) {
        if let files = LocalFileManager.shallowSearchAllFiles(folderPath: MobileFrameEngine.shared.config.draftHtmlFilesPath) {
            for file in files {
                if file.contains(".html") == true {
                    LocalFileManager.removefile(filePath: (MobileFrameEngine.shared.config.draftHtmlFilesPath as NSString).appendingPathComponent(file))
                }
            }
        }
    }
    
    func devToolsReload(_ devToolsView: DevToolsView) {
        if let vc = self.webViewVC {
            if MobileFrameEngine.shared.config.isGlobalDraft {
                if let dashboardId = vc.dashboardId {
                    OfflineResourcesManager.shared.downloadDashboard(dashboardID: dashboardId) { (isSuccess, filePath) in
                        if isSuccess {
                            if !filePath.isBlank {
                                vc.startLoadWebview()
                            }
                        }
                    }
                }
            }
            else {
                vc.startLoadWebview()
            }
        }
    }
    
    func devToolsLogout(_ devToolsView: DevToolsView) {
        MobileFrameEngine.shared.logOut()
    }
    
    func devToolsDraft(_ devToolsView: DevToolsView) {
        if let vc = self.webViewVC {
            
            if devToolsView.switchView.isOn {
                if let dashboardId = vc.dashboardId {
                    OfflineResourcesManager.shared.downloadDashboard(dashboardID: dashboardId) { (isSuccess, filePath) in
                        if isSuccess {
                            if !filePath.isBlank {
                                MobileFrameEngine.shared.config.isGlobalDraft = true
                                devToolsView.switchView.setOn(true, animated: true)

                                vc.startLoadWebview()
                            }
                        }
                        else {
                            MobileFrameEngine.shared.config.isGlobalDraft = false
                            devToolsView.switchView.setOn(false, animated: true)
                        }
                    }
                }
//                MobileFrameEngine.shared.config.isGlobalDraft = true
//                vc.startLoadWebview()
            }
            else {                
                MobileFrameEngine.shared.config.isGlobalDraft = false
                vc.startLoadWebview()                
            }
            
            devToolsView.isHidden = true
        }
    }
    
    func devToolsNavToTestDashboard(_ devToolsView: DevToolsView) {
        if let vc = self.webViewVC {
            let dashboard = OfflineResourcesManager.shared.getDashboardFromDB(dashboardID: 191002)
            if dashboard != nil {
                let testVc =  WebViewController()
                testVc.dashboardId = dashboard?.DashboardID
                testVc.localFilePath = dashboard?.FilePath
                vc.navigationController?.pushViewController(testVc, animated: true)
                
                devToolsView.isHidden = true
            }
        }

    }
}
