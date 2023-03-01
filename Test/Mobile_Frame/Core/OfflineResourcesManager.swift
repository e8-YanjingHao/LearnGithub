//
//  DBResourcesManager.swift
//  MobileFrame
//
//  Created by ERIC on 2021/11/18.
//

import Foundation
import SwiftyJSON
import Alamofire

internal class OfflineResourcesManager: NSObject {
    
    static var shared = OfflineResourcesManager()
    
    lazy var localGlobalModel: GlobalStaticModel? = {
        do {
            let results = try SQLiteManager.default.resourceDB().select(GlobalStaticModel.tableName)
            let localGlobals = JSON(results).arrayValue
            return localGlobals.count >= 1 ? GlobalStaticModel(dict: localGlobals.last!) : nil
        }
        catch {
            return nil
        }
    }()
    
    lazy var localDashboardModels: [DashboardModel]? = {
        do {
            let results = try SQLiteManager.default.resourceDB().select(DashboardModel.tableName)
            let arr = JSON(results)
            return arr.arrayValue.map { DashboardModel(dict: $0) }
        }
        catch {
            return nil
        }
    }()
    
    var globalStaticModel: GlobalStaticModel?
    var dashboardModels: [DashboardModel]?
    
    var downloadBlock: ((_ complate: Bool, _ totalCount: Int, _ updateCount: Int, _ progress: CGFloat) -> Void)?
        
    override init() {
        super.init()
    }

    public func requestDashboards(_ downloadBlock: ((_ complate: Bool, _ totalCount: Int, _ updateCount: Int, _ progress: CGFloat) -> Void)?) {
        let url = API.getMeta(query: [
            "MobileFrameAppID": MobileFrameEngine.shared.config.mobileFrameAppID,
            "WebRequestID": UUID().uuidString
        ])
        
        self.downloadBlock = downloadBlock

        NetWorkManager.shared.postWithPath(path: url, paras: nil) { result in
                        
            self.globalStaticModel = GlobalStaticModel(dict: JSON(result))
            
            self.dashboardModels = JSON(result)["OfflineDashboards"].arrayValue.map { DashboardModel(dict: $0) }
                                 
            self.downloadResources()
            
//            LoginManager.shared.verifySession { VerifySuccess, SocketSessionID, SocketServerURL in
//            }
            
        } failure: { error in
            SLogError(error.localizedDescription)
            self.downloadBlock?(true, 0, 0, 0.0)
        }
    }
    
    private func downloadResources() {
        var downloadCount = 0
        var totalTasks: [[String:String]] = []
        var downloadTasks: [[String:String]] = []
        if self.checkUpdateMobileFrameZipApp() {
            if let mobileFrameZipAppUrl = self.globalStaticModel?.MobileFrameAppZipURL {
                if mobileFrameZipAppUrl.isBlank == false {
                    totalTasks.append([
                        "fileName": "MobileFrameZipApp.zip",
                        "url": mobileFrameZipAppUrl
                    ])
                }
            }
        }
        
        if self.checkUpdateEcpGlobal() {
            if let globalZipUrl = self.globalStaticModel?.GlobalZipURL {
                if globalZipUrl.isBlank == false {
                    totalTasks.append([
                        "fileName": "GlobalStaticFiles.zip",
                        "url": globalZipUrl
                    ])
                }
            }
        }
        
        let (isUpdateDashboard, urlStrings, dashboardIds) = self.checkUpdateDashboards()
        let fileNames = dashboardIds.map({ id -> String in
            return "\(id)"
        })
        if isUpdateDashboard {
            for (index, url) in urlStrings.enumerated() {
                totalTasks.append([
                    "fileName": fileNames[index],
                    "url": url
                ])
            }
        }
        
        if totalTasks.count == 0 {
            self.downloadBlock?(true, 0, 0, 0.0)
            return
        }
        
        for task in totalTasks {
            if let fileName = task["fileName"], let url = task["url"] {
                NetWorkManager.shared.download(fileName: fileName, url: url) { fileName, path in
                    downloadCount = downloadCount + 1
                    
                    self.downloadBlock?(false, totalTasks.count, downloadCount, 0.0)
                    
                    downloadTasks.append([
                        "name": fileName,
                        "path": path
                    ])
                    
                    if totalTasks.count == downloadTasks.count {
                        for task in downloadTasks {
                            let name = task["name"] ?? ""
                            let path = task["path"] ?? ""
                            if name == "MobileFrameZipApp.zip" {
                                self.unzipMobileFrameZipAppFileToPath(fileName: name, filePath: path)
                            }

                            if name == "GlobalStaticFiles.zip" {
                                self.unzipEcpGlobalFileToPath(fileName: name, filePath: path)
                            }

                            if let dashboardModels = self.dashboardModels {
                                for model in dashboardModels {
                                    if name == String(model.DashboardID ?? 0) {
                                        self.unzipDashboardFileToPath(fileName: name, filePath: path, dashboard: model)
                                        break
                                    }
                                }
                            }
                        }
                    }
                    
                } fail: { fileName in
                    AF.cancelAllRequests()
                    self.downloadBlock?(true, 0, 0, 0.0)
                }
            }
        }
    }
    
    private func checkUpdateMobileFrameZipApp() -> Bool {
        guard let localGlobalModel = getLocalGlobalModal() else {
            return true
        }

        guard let updateTime1 = localGlobalModel.MobileFrameAppZipTimeUpdated else {
            return true
        }
        
        guard let updateTime2 = globalStaticModel?.MobileFrameAppZipTimeUpdated else {
            return false
        }
        
        if updateTime1 != updateTime2 {
            return true
        }
        
        return false
    }
    
    private func checkUpdateEcpGlobal() -> Bool {
        guard let localGlobalModel = getLocalGlobalModal() else {
            return true
        }
        
        guard let version1 = localGlobalModel.MajorVersion else {
            return true
        }
        
        guard let version2 = globalStaticModel?.MajorVersion else {
            return false
        }
        
        guard let url1 = localGlobalModel.GlobalZipURL else {
            return true
        }
        
        guard let url2 = globalStaticModel?.GlobalZipURL else {
            return false
        }
        
        if version1 < version2 {
            return true
        }
        
        if url1 != url2 {
            return true
        }
        
        return false
    }
    
    private func checkUpdateDashboard(localDashboard: DashboardModel, dashboard: DashboardModel) -> Bool {
        guard let dashboardID = localDashboard.DashboardID, dashboardID != 0 else {
            return true
        }
        
        guard let version1 = localDashboard.DashboardVersionID else {
            return true
        }
        
        guard let version2 = dashboard.DashboardVersionID else {
            return false
        }
        
        guard let updateTime1 = localDashboard.TimeUpdated else {
            return true
        }
        
        guard let updateTime2 = dashboard.TimeUpdated else {
            return false
        }
        
        guard let filePath = localDashboard.FilePath else {
            return true
        }
        
        let htmlFilePath = (MobileFrameEngine.shared.config.htmlFilesPath as NSString).appendingPathComponent(filePath)
        if LocalFileManager.judgeFileOrFolderExists(filePath: htmlFilePath) == false {
            return true
        }
        
        if version1 < version2 {
            return true
        }
        
        if updateTime1 != updateTime2 {
            return true
        }
        else {
            return false
        }
    }
    
    private func checkUpdateDashboards() -> (Bool, [String], [Int]) {
        
        guard let _ = self.localDashboardModels else {
            return (true, [], [])
        }
        
        guard let dashboardModels = self.dashboardModels, dashboardModels.count != 0 else {
            return (false, [], [])
        }
        
        var urlStrings = [String]()
        var dashboardIds = [Int]()
        
        dashboardModels.forEach { model in
            
            if let dashboardID = model.DashboardID {
                if let localModel = self.getDashboardFromDB(dashboardID: dashboardID) {
                    
                    if self.checkUpdateDashboard(localDashboard: localModel, dashboard: model) {
                        urlStrings.append(model.ZipURL ?? "")
                        dashboardIds.append(model.DashboardID ?? 0)
                    }
                }
                else {
                    urlStrings.append(model.ZipURL ?? "")
                    dashboardIds.append(model.DashboardID ?? 0)
                }
            }
        }
        
        guard urlStrings.count == dashboardIds.count && (urlStrings.count > 0) else {
            return (false, [], [])
        }
        
        return (true, urlStrings, dashboardIds)
    }
    
    private func unzipMobileFrameZipAppFileToPath(fileName: String, filePath: String) {

        let unzipTmpPath = (MobileFrameEngine.shared.config.tmpFilesPath as NSString).appendingPathComponent(fileName)
        let htmlPath = MobileFrameEngine.shared.config.htmlFilesPath
        let draftHtmlPath = MobileFrameEngine.shared.config.draftHtmlFilesPath

        let unzipSuccess = ZipArchiveManager.share.unzip(filePath: filePath, unzipPath: htmlPath)
        
        let _ = ZipArchiveManager.share.unzip(filePath: filePath, unzipPath: draftHtmlPath)
             
        if unzipSuccess == false { SLog.error("\(fileName) File decompression failed"); return }

        let (issuccess, _) = LocalFileManager.createFolder(folderPath: unzipTmpPath)
        
        if issuccess == false { SLog.error("\(fileName) Temporary directory creation failed"); return }
        
        let success = ZipArchiveManager.share.unzip(filePath: filePath, unzipPath: unzipTmpPath)
        
        if success == false { SLog.error("\(fileName) File decompression failed"); return }
        
        var filesStr = ""
        if let files = LocalFileManager.deepSearchAllFiles(folderPath: unzipTmpPath) {
            for file in files {
                let f = file as! String
                filesStr += f + ","
            }
        }
        self.globalStaticModel?.Files = self.globalStaticModel?.Files ?? "" + filesStr
        
        if let ecp = self.globalStaticModel {
            SQLiteManager.default.resourceDB().update(ecp)
        }
    }
    
    private func unzipEcpGlobalFileToPath(fileName: String, filePath: String) {

        let unzipTmpPath = (MobileFrameEngine.shared.config.tmpFilesPath as NSString).appendingPathComponent(fileName)
        let htmlPath = MobileFrameEngine.shared.config.htmlFilesPath
        let draftHtmlPath = MobileFrameEngine.shared.config.draftHtmlFilesPath

        let unzipSuccess = ZipArchiveManager.share.unzip(filePath: filePath, unzipPath: htmlPath)
        
        let _ = ZipArchiveManager.share.unzip(filePath: filePath, unzipPath: draftHtmlPath)
        
        if unzipSuccess == false { SLog.error("\(fileName) File decompression failed"); return }

        let (issuccess, _) = LocalFileManager.createFolder(folderPath: unzipTmpPath)
        
        if issuccess == false { SLog.error("\(fileName) Temporary directory creation failed"); return }
        
        let success = ZipArchiveManager.share.unzip(filePath: filePath, unzipPath: unzipTmpPath)
        
        if success == false { SLog.error("\(fileName) File decompression failed"); return }
        
        var filesStr = ""
        if let files = LocalFileManager.deepSearchAllFiles(folderPath: unzipTmpPath) {
            for file in files {
                let f = file as! String
                filesStr += f + ","
            }
        }
        self.globalStaticModel?.Files = self.globalStaticModel?.Files ?? "" + filesStr
        
        if let ecp = self.globalStaticModel {
            SQLiteManager.default.resourceDB().update(ecp)
        }
    }
    
    private func unzipDashboardFileToPath(fileName: String, filePath: String, dashboard: DashboardModel) {
        
        let unzipTmpPath = (MobileFrameEngine.shared.config.tmpFilesPath as NSString).appendingPathComponent(fileName)
        let htmlPath = MobileFrameEngine.shared.config.htmlFilesPath
        
        let unzipSuccess = ZipArchiveManager.share.unzip(filePath: filePath, unzipPath: htmlPath)
        
        if unzipSuccess == false { SLog.error("\(fileName) File decompression failed"); return }

        let (issuccess, _) = LocalFileManager.createFolder(folderPath: unzipTmpPath)
        
        if issuccess == false { SLog.error("\(fileName) Temporary directory creation failed"); return }
        
        let success = ZipArchiveManager.share.unzip(filePath: filePath, unzipPath: unzipTmpPath)
        
        if success == false { SLog.error("\(fileName) File decompression failed"); return }
        
        var filesStr = ""
        var htmlStr = ""
        if let files = LocalFileManager.deepSearchAllFiles(folderPath: unzipTmpPath) {
            for file in files {
                let f = file as! String
                if f.contains(".html") == true {
                    htmlStr = f
                }
                filesStr += f + ","
            }
        }
        
        dashboard.Files = filesStr
        
        dashboard.FilePath = htmlStr

        try? SQLiteManager.default.resourceDB().insert(dashboard)
    }
}

extension OfflineResourcesManager {
    
    public func getDashboardFromDB(dashboardID: Int) -> DashboardModel? {
        do {
            let results:[DashboardModel] = try SQLiteManager.default.resourceDB().select(["DashboardID":dashboardID])
            return results.count >= 1 ? results.last : nil
        }
        catch {
            return nil
        }
    }
    
    public func getLocalGlobalModal() -> GlobalStaticModel? {
        do {
            let results = try SQLiteManager.default.resourceDB().select(GlobalStaticModel.tableName)
            let localGlobals = JSON(results).arrayValue
            return localGlobals.count >= 1 ? GlobalStaticModel(dict: localGlobals.last!) : nil
        }
        catch {
            return nil
        }
    }
    
    public func dashboardFilePathByDashboardID(dashboardID: Int) -> String {
        
        guard let dashboard = OfflineResourcesManager.shared.getDashboardFromDB(dashboardID: dashboardID) else {
            return ""
        }
        
        guard let filePath = dashboard.FilePath else {
            return ""
        }
        
        let htmlFilePath = MobileFrameEngine.shared.config.isGlobalDraft ? (MobileFrameEngine.shared.config.draftHtmlFilesPath as NSString).appendingPathComponent(filePath) : (MobileFrameEngine.shared.config.htmlFilesPath as NSString).appendingPathComponent(filePath)
        if LocalFileManager.judgeFileOrFolderExists(filePath: htmlFilePath) == false {
            return ""
        }

        return filePath
    }
    
    public func offLineByDashboardID(dashboardID: Int) -> Bool {
        guard let _ = OfflineResourcesManager.shared.getDashboardFromDB(dashboardID: dashboardID) else {
            return false
        }
        
        return true
    }
    
    public func entryDashboardFilePath() -> (Int, String) {
        guard let globalDashboard = getLocalGlobalModal() else {
            return (0, "")
        }
        
        guard let dashboardID = globalDashboard.EntryDashboardID, dashboardID != 0 else {
            return (0, "")
        }
        
        return (dashboardID, dashboardFilePathByDashboardID(dashboardID: dashboardID))
    }
    
    public func exceptionDashboardFilePath() -> (Int, String) {
        guard let globalDashboard = getLocalGlobalModal() else {
            return (0, "")
        }
        
        guard let dashboardID = globalDashboard.ExceptionDashboardID, dashboardID != 0 else {
            return (0, "")
        }
        
        return (dashboardID, dashboardFilePathByDashboardID(dashboardID: dashboardID))
    }
    
}

extension OfflineResourcesManager {
    public func prestrainLocalResource() {
        
        let (_, path) = self.entryDashboardFilePath()
        
        if path.isBlank {
                    
            guard let resourcePlist = Bundle.main.path(forResource: "resources", ofType: "plist") else {
                return
            }
            
            guard let defaultResources = NSDictionary(contentsOfFile: resourcePlist) else {
                return
            }
            
            self.globalStaticModel = GlobalStaticModel(dict: JSON(defaultResources))
            
            self.dashboardModels = JSON(defaultResources)["OfflineDashboards"].arrayValue.map { DashboardModel(dict: $0) }
            
            if let mobileFramePath = Bundle.main.path(forResource: self.globalStaticModel?.MobileFrameAppZipURL, ofType: "zip") {
                self.unzipMobileFrameZipAppFileToPath(fileName: "MobileFrameZipApp.zip", filePath: mobileFramePath)
            }
            if let globalStaticPath = Bundle.main.path(forResource: self.globalStaticModel?.GlobalZipURL, ofType: "zip") {
                self.unzipEcpGlobalFileToPath(fileName: "GlobalStaticFiles.zip", filePath: globalStaticPath)
            }
            
            if let dashboardModels = self.dashboardModels {
                for model in dashboardModels {
                    if let path = Bundle.main.path(forResource: String(model.DashboardID ?? 0), ofType: "zip") {
                        self.unzipDashboardFileToPath(fileName: String(model.DashboardID ?? 0) , filePath: path, dashboard: model)
                    }
                }
            }
        }
    }
}

extension OfflineResourcesManager {
    func downloadDashboard(dashboardID: Int, success: @escaping (_ isSuccess: Bool, _ filePath: String)->()) {
        let path = API.getDashboard(query: [
            "DashboardID": String(describing: dashboardID),
            "Release": "False",
            "WebRequestID": UUID().uuidString
        ])
        MobileFrameEngine.shared.delegate?.mobileFrameUpdateOfflineResult(complate: false, totalCount: 1, updateCount: 0, progress: 0)

        NetWorkManager.shared.download(fileName: String(describing: dashboardID), url: path) { fileName, path in
            let drafHtmlPath = MobileFrameEngine.shared.config.draftHtmlFilesPath

            let unzipSuccess = ZipArchiveManager.share.unzip(filePath: path, unzipPath: drafHtmlPath)

            var filePath = ""
            if unzipSuccess {
                filePath = "\(dashboardID).html"
            }

            success(unzipSuccess, filePath)
        } fail: { fileName in
            success(false, "")
        }
    }
}
