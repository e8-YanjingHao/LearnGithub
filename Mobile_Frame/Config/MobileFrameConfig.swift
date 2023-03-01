//
//  MobileFrameConfig.swift
//  MobileFrame
//
//  Created by ERIC on 2021/11/15.
//

import Foundation
import UIKit

struct Env {
    private static let production : Bool = {
        #if DEBUG
            return false
        #elseif ADHOC
            return false
        #else
            return true
        #endif
    }()
    
    static func isProduction() -> Bool {
        return self.production
    }
}

public class MobileFrameConfig: NSObject {
        
    private(set) var customScheme = ""
    
    private(set) var baseUrl = ""
    
    private(set) var mainIndex : String?
    
    // MARK: DocumentPath directory
    public var documentPath: String {
        get {
            return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        }
    }
    
    // MARK: Caches directory
    public var cachesPath: String {
        get {
            return NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
        }
    }
    
    // MARK: Tmp directory
    public var tmpPath: String {
        get {
            return NSTemporaryDirectory() as String
        }
    }
        
    public var mobileFrameAppID = ""
        
    public var encompassID = ""
    
    public var serverHost = ""
    
    public var userAgent = ""
    
    public var clientLogType = "1"
    
    public var enableEChat = false
        
    // MARK: Log to file
    public var addLocalLog = true {
        didSet {
            SLog.addFileLog = addLocalLog
        }
    }
    
    // MARK: SQL Debug
    public var sqlLog = false {
        didSet {
            SQLiteManager.default.enableLog = sqlLog
        }
    }
    
    // MARK: devtools view
    public var devTools = false
    
    // MARK: Global Draft Env
    public var isGlobalDraft = false

    // MARK: Default storage root directory
    public var rootPath = ""

    // MARK: Compressed file storage directory
    internal var zipFilesPath = ""
    
    // MARK: Unzip file storage directory
    internal var htmlFilesPath = ""
    
    // MARK: Draft Unzip file storage directory
    internal var draftHtmlFilesPath = ""
    
    // MARK: Temporary storage directory for decompressed files
    internal var tmpFilesPath = ""
    
    // MARK: atabasesPath
    internal var globalStaticDatabasePath = ""
    
    // MARK: global base databasePath
    internal var globalStaticDatabase = ""
    
    // MARK: log path
    internal var logFilePath = ""
    
    public override init() {
        super.init()
    }
    
    public static func initConfig(mobileFrameAppID: String, encompassID: String, serverHost: String, userAgent: String, clientLogType: String, devTools: Bool, sqlLog: Bool) -> MobileFrameConfig {
        
        let config = MobileFrameConfig()
        
        config.mobileFrameAppID = mobileFrameAppID
        
        if let encompassID = UserDefaults.standard.value(forKey: "EncompassID") as? String {
            config.encompassID = encompassID
        }
        else {
            config.encompassID = encompassID
        }
        
        if let serverHost = UserDefaults.standard.value(forKey: "ServerHost") as? String {
            config.serverHost = serverHost
        }
        else {
            config.serverHost = serverHost
        }
        
        if let userAgent = UserDefaults.standard.value(forKey: "UserAgent") as? String {
            config.userAgent = userAgent
        }
        else {
            config.userAgent = userAgent
        }
        
        if let devTools = UserDefaults.standard.value(forKey: "DevTools") as? Bool {
            config.devTools = devTools
        }
        else {
            config.devTools = devTools
        }
        
        config.clientLogType = clientLogType
        config.sqlLog = sqlLog
    
        config.customScheme    = "fm"
        config.baseUrl         = "fm://"

        config.rootPath = config.cachesPath + "/Dashboards"
        config.logFilePath = config.cachesPath + "/Logs"
        config.zipFilesPath = (config.rootPath as NSString).appendingPathComponent("ZipResources")
        config.htmlFilesPath = (config.rootPath as NSString).appendingPathComponent("HtmlResources")
        config.draftHtmlFilesPath = (config.rootPath as NSString).appendingPathComponent("DraftHtmlResources")
        config.tmpFilesPath = (config.rootPath as NSString).appendingPathComponent("TmpResources")
        config.globalStaticDatabasePath = (config.rootPath as NSString).appendingPathComponent("databases")
        config.globalStaticDatabase = config.globalStaticDatabasePath + "/db.sqlite3"
        
        LocalFileManager.createFolder(folderPath: config.globalStaticDatabasePath)
        
        SLogInfo(config.rootPath)
        
        return config
    }
    
    internal func updateGlobalConfig(encompassID: String, serverHost: String, userAgent: String, devTools: Bool) {
        MobileFrameEngine.shared.config.encompassID = encompassID
        MobileFrameEngine.shared.config.serverHost = serverHost
        MobileFrameEngine.shared.config.userAgent = userAgent
        MobileFrameEngine.shared.config.devTools = devTools
        
        UserDefaults.standard.set(encompassID, forKey: "EncompassID")
        UserDefaults.standard.set(serverHost, forKey: "ServerHost")
        UserDefaults.standard.set(userAgent, forKey: "UserAgent")
        UserDefaults.standard.set(devTools, forKey: "DevTools")
    }
}
