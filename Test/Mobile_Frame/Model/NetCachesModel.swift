//
//  NetCachesModel.swift
//  MobileFrame
//
//  Created by ERIC on 2021/12/7.
//

import Foundation
import SwiftyJSON

internal class NetCachesModel: NSObject, SQLiteProtocol {
    public static var tableName: String {
        return "NetCachesModel"
    }
    
    public var primaryKey: String {
        return "Key"
    }
    
    public var uniqueKeys: [String]? {
        return ["Key"]
    }
    
    var Key: String
    var Content: String
    
    public required init(key: String, content: String) {
        Key = key
        Content = content
    }
    
    public required init(_ dict: [String : Any]) {
        self.Key = dict["Key"] as! String
        self.Content = dict["Content"] as! String
    }
}
