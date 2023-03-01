//
//  DashboardModel.swift
//  MobileFrame
//
//  Created by ERIC on 2021/11/17.
//

import Foundation
import SwiftyJSON

internal class DashboardModel: NSObject, SQLiteProtocol {
    public static var tableName: String {
        return "DashboardModel"
    }
    
    public var primaryKey: String {
        return "DashboardID"
    }
    
//    public var uniqueKeys: [String]? {
//        return ["DashboardID"]
//    }
    
    var DashboardID: Int?
    var DashboardVersionID: Int?
    var ZipURL: String?
    var FilePath: String?
    var Files: String?
    var TimeUpdated: String?
    var DefaultBackgroundColor: String?
    
    public required init(dict: JSON) {
        DashboardID = dict["DashboardID"].intValue
        DashboardVersionID = dict["DashboardVersionID"].intValue
        ZipURL = dict["ZipURL"].stringValue
        FilePath = dict["FilePath"].stringValue
        Files = dict["Files"].stringValue
        TimeUpdated = dict["TimeUpdated"].stringValue
        DefaultBackgroundColor = dict["DefaultBackgroundColor"].stringValue
    }
    
    public required init(_ dict: [String : Any]) {
        let jsonData = JSON(dict)
        DashboardID = jsonData["DashboardID"].intValue
        DashboardVersionID = jsonData["DashboardVersionID"].intValue
        ZipURL = jsonData["ZipURL"].stringValue
        FilePath = jsonData["FilePath"].stringValue
        Files = jsonData["Files"].stringValue
        TimeUpdated = jsonData["TimeUpdated"].stringValue
        DefaultBackgroundColor = jsonData["DefaultBackgroundColor"].stringValue
    }
}

