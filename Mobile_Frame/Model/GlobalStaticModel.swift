//
//  ECPGlobalModel.swift
//  MobileFrame
//
//  Created by ERIC on 2021/11/17.
//

import Foundation
import SwiftyJSON

internal class GlobalStaticModel: NSObject, SQLiteProtocol {
    required public init(_ dict: [String : Any]) {
        
    }
    
    public static var tableName: String {
        return "GlobalStaticModel"
    }
    
    var primaryKey: String {
        return "EncompassID"
    }
    
    var EncompassID: String?
    var MajorVersion: String?
    var EntryDashboardID: Int?
    var ExceptionDashboardID: Int?
    var GlobalZipURL: String?
    var MobileFrameAppZipURL: String?
    var MobileFrameAppZipTimeUpdated: String?
    var Files: String?
    var IsTestDatabase: String?
    
    var EChatServerUrl: String?
    var EChatDashboardID: Int?
    var EncompassDBServer: String?

    var FilePath: String = "" {
        didSet {
            SLogDebug(FilePath)
        }
    }

    required init(dict: JSON) {
        EncompassID = dict["EncompassID"].stringValue
        MajorVersion = dict["MajorVersion"].stringValue
        EntryDashboardID = dict["EntryDashboardID"].intValue
        ExceptionDashboardID = dict["ExceptionDashboardID"].intValue
        GlobalZipURL = dict["GlobalZipURL"].stringValue
        MobileFrameAppZipURL = dict["MobileFrameAppZipURL"].stringValue
        MobileFrameAppZipTimeUpdated = dict["MobileFrameAppZipTimeUpdated"].stringValue
        FilePath = dict["FilePath"].stringValue
        Files = dict["Files"].stringValue
        IsTestDatabase = dict["IsTestDatabase"].stringValue
        EChatServerUrl = dict["EChatServerUrl"].stringValue
        EChatDashboardID = dict["EChatDashboardID"].intValue
        EncompassDBServer = dict["EncompassDBServer"].stringValue
    }
}
